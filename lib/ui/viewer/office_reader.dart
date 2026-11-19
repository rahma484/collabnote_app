import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Pembaca dokumen Office (docx, xlsx, pptx) tanpa aplikasi luar.
///
/// File Office sebenarnya adalah ZIP berisi XML. Kelas ini membuka ZIP (paket `archive`),
/// membaca XML (paket `xml`), lalu mengubahnya menjadi model sederhana yang digambar
/// oleh DocumentViewerScreen. Jadi dokumen dapat dibuka langsung di dalam aplikasi,
/// termasuk di browser, tanpa harus diunduh.

// ------------------------------------------------------------------- Model

class OfficeRun {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;

  const OfficeRun(this.text, {this.bold = false, this.italic = false, this.underline = false});
}

abstract class OfficeBlock {
  const OfficeBlock();
}

/// Paragraf. [heading]: 0 = judul dokumen, 1..6 = Heading 1..6, null = paragraf biasa.
class OfficeParagraph extends OfficeBlock {
  final List<OfficeRun> runs;
  final int? heading;
  final bool bullet;

  const OfficeParagraph(this.runs, {this.heading, this.bullet = false});

  String get plainText => runs.map((r) => r.text).join();
}

class OfficeTable extends OfficeBlock {
  final List<List<String>> rows;

  const OfficeTable(this.rows);
}

class OfficeSheet {
  final String name;
  final List<List<String>> rows;
  final int columnCount;
  final bool truncated;

  const OfficeSheet({required this.name, required this.rows, required this.columnCount, this.truncated = false});
}

class OfficeSlide {
  final String title;
  final List<String> lines;

  const OfficeSlide({required this.title, required this.lines});
}

enum OfficeKind { docx, xlsx, pptx }

class OfficeContent {
  final OfficeKind kind;
  final List<OfficeBlock> blocks;
  final List<OfficeSheet> sheets;
  final List<OfficeSlide> slides;

  const OfficeContent.docx(this.blocks)
      : kind = OfficeKind.docx,
        sheets = const [],
        slides = const [];

  const OfficeContent.xlsx(this.sheets)
      : kind = OfficeKind.xlsx,
        blocks = const [],
        slides = const [];

  const OfficeContent.pptx(this.slides)
      : kind = OfficeKind.pptx,
        blocks = const [],
        sheets = const [];
}

// ------------------------------------------------------------------ Pembaca

class OfficeReader {
  OfficeReader._();

  static const int maxRows = 300;
  static const int maxColumns = 26;

  /// Membaca [bytes] sesuai [extension]. Melempar [FormatException] bila file tidak valid.
  static OfficeContent read(String extension, Uint8List bytes) {
    final Archive zip;
    try {
      zip = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('File bukan dokumen Office yang valid (atau rusak).');
    }
    switch (extension.toLowerCase()) {
      case 'docx':
        return _readDocx(zip);
      case 'xlsx':
        return _readXlsx(zip);
      case 'pptx':
        return _readPptx(zip);
    }
    throw FormatException('Format .$extension belum didukung untuk dibuka di aplikasi.');
  }

  // ------------------------------------------------------------ Util XML

  static XmlDocument _xml(Archive zip, String path) {
    final file = zip.findFile(path);
    if (file == null) throw FormatException('Bagian $path tidak ditemukan di dalam file.');
    return XmlDocument.parse(utf8.decode(file.content as List<int>, allowMalformed: true));
  }

  static XmlDocument? _xmlOrNull(Archive zip, String path) {
    final file = zip.findFile(path);
    if (file == null) return null;
    return XmlDocument.parse(utf8.decode(file.content as List<int>, allowMalformed: true));
  }

  static Iterable<XmlElement> _kids(XmlNode node, String local) =>
      node.children.whereType<XmlElement>().where((e) => e.name.local == local);

  static Iterable<XmlElement> _all(XmlNode node, String local) =>
      node.descendants.whereType<XmlElement>().where((e) => e.name.local == local);

  static XmlElement? _first(XmlNode node, String local) {
    for (final e in _all(node, local)) {
      return e;
    }
    return null;
  }

  static String? _attr(XmlElement e, String local) {
    for (final a in e.attributes) {
      if (a.name.local == local) return a.value;
    }
    return null;
  }

  /// Teks gabungan semua elemen <t> di bawah [node].
  static String _text(XmlNode node, String tagLocal) => _all(node, tagLocal).map((e) => e.innerText).join();

  // ---------------------------------------------------------------- DOCX

  static OfficeContent _readDocx(Archive zip) {
    final doc = _xml(zip, 'word/document.xml');
    final body = _first(doc, 'body');
    if (body == null) return const OfficeContent.docx([]);
    final blocks = <OfficeBlock>[];
    for (final child in body.children.whereType<XmlElement>()) {
      if (child.name.local == 'p') {
        final p = _docxParagraph(child);
        if (p != null) blocks.add(p);
      } else if (child.name.local == 'tbl') {
        final rows = <List<String>>[];
        for (final tr in _kids(child, 'tr')) {
          final cells = <String>[];
          for (final tc in _kids(tr, 'tc')) {
            cells.add(_kids(tc, 'p').map((p) => _text(p, 't')).join('\n'));
          }
          if (cells.isNotEmpty) rows.add(cells);
        }
        if (rows.isNotEmpty) blocks.add(OfficeTable(rows));
      }
    }
    return OfficeContent.docx(blocks);
  }

  static bool _flag(XmlElement? rPr, String local) {
    if (rPr == null) return false;
    final e = _first(rPr, local);
    if (e == null) return false;
    final v = _attr(e, 'val');
    return v == null || (v != '0' && v != 'false' && v != 'none');
  }

  static OfficeParagraph? _docxParagraph(XmlElement p) {
    final pPr = _kids(p, 'pPr').isEmpty ? null : _kids(p, 'pPr').first;
    int? heading;
    var bullet = false;
    if (pPr != null) {
      final style = _first(pPr, 'pStyle');
      final styleName = (style == null ? '' : (_attr(style, 'val') ?? '')).toLowerCase();
      if (styleName == 'title') {
        heading = 0;
      } else if (styleName.startsWith('heading')) {
        heading = int.tryParse(styleName.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      } else if (styleName.contains('list')) {
        bullet = true;
      }
      if (_first(pPr, 'numPr') != null) bullet = true;
    }
    final runs = <OfficeRun>[];
    for (final r in _all(p, 'r')) {
      final rPr = _kids(r, 'rPr').isEmpty ? null : _kids(r, 'rPr').first;
      final buffer = StringBuffer();
      for (final part in r.children.whereType<XmlElement>()) {
        switch (part.name.local) {
          case 't':
            buffer.write(part.innerText);
            break;
          case 'tab':
            buffer.write('    ');
            break;
          case 'br':
            buffer.write('\n');
            break;
        }
      }
      if (buffer.isEmpty) continue;
      runs.add(OfficeRun(
        buffer.toString(),
        bold: _flag(rPr, 'b'),
        italic: _flag(rPr, 'i'),
        underline: _flag(rPr, 'u'),
      ));
    }
    if (runs.isEmpty) return const OfficeParagraph([OfficeRun('')]);
    return OfficeParagraph(runs, heading: heading, bullet: bullet);
  }

  // ---------------------------------------------------------------- XLSX

  static int _columnIndex(String ref) {
    var index = 0;
    for (final unit in ref.toUpperCase().codeUnits) {
      if (unit < 65 || unit > 90) break;
      index = index * 26 + (unit - 64);
    }
    return index - 1;
  }

  static String _number(String raw) {
    final d = double.tryParse(raw);
    if (d == null) return raw;
    if (d == d.roundToDouble() && d.abs() < 1e15) return d.toInt().toString();
    return double.parse(d.toStringAsFixed(6)).toString();
  }

  static OfficeContent _readXlsx(Archive zip) {
    final shared = <String>[];
    final sst = _xmlOrNull(zip, 'xl/sharedStrings.xml');
    if (sst != null) {
      for (final si in _all(sst, 'si')) {
        shared.add(_text(si, 't'));
      }
    }
    final workbook = _xml(zip, 'xl/workbook.xml');
    final rels = _xmlOrNull(zip, 'xl/_rels/workbook.xml.rels');
    final targets = <String, String>{};
    if (rels != null) {
      for (final r in _all(rels, 'Relationship')) {
        final id = _attr(r, 'Id');
        final target = _attr(r, 'Target');
        if (id != null && target != null) targets[id] = target;
      }
    }
    final sheets = <OfficeSheet>[];
    var counter = 0;
    for (final s in _all(workbook, 'sheet')) {
      counter++;
      final name = _attr(s, 'name') ?? 'Sheet$counter';
      final rid = _attr(s, 'id');
      var target = rid == null ? null : targets[rid];
      target ??= 'worksheets/sheet$counter.xml';
      final path = target.startsWith('/') ? target.substring(1) : 'xl/$target';
      final sheetXml = _xmlOrNull(zip, path);
      if (sheetXml == null) continue;
      final rows = <List<String>>[];
      var columns = 0;
      var truncated = false;
      for (final row in _all(sheetXml, 'row')) {
        if (rows.length >= maxRows) {
          truncated = true;
          break;
        }
        final rowNumber = int.tryParse(_attr(row, 'r') ?? '') ?? (rows.length + 1);
        while (rows.length < rowNumber - 1 && rows.length < maxRows) {
          rows.add(const []);
        }
        final cells = <String>[];
        for (final c in _kids(row, 'c')) {
          final ref = _attr(c, 'r') ?? '';
          final col = ref.isEmpty ? cells.length : _columnIndex(ref);
          if (col >= maxColumns) continue;
          while (cells.length < col) {
            cells.add('');
          }
          final type = _attr(c, 't');
          final v = _first(c, 'v')?.innerText ?? '';
          String value;
          if (type == 's') {
            final i = int.tryParse(v) ?? -1;
            value = (i >= 0 && i < shared.length) ? shared[i] : '';
          } else if (type == 'inlineStr') {
            value = _text(c, 't');
          } else if (type == 'b') {
            value = v == '1' ? 'TRUE' : 'FALSE';
          } else if (type == 'str') {
            value = v;
          } else {
            value = _number(v);
          }
          if (col < cells.length) {
            cells[col] = value;
          } else {
            cells.add(value);
          }
        }
        if (cells.length > columns) columns = cells.length;
        rows.add(cells);
      }
      sheets.add(OfficeSheet(name: name, rows: rows, columnCount: columns, truncated: truncated));
    }
    return OfficeContent.xlsx(sheets);
  }

  // ---------------------------------------------------------------- PPTX

  static OfficeContent _readPptx(Archive zip) {
    final slideFiles = zip.files
        .where((f) => f.isFile && RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(f.name))
        .toList()
      ..sort((a, b) {
        int n(String s) => int.parse(RegExp(r'(\d+)\.xml$').firstMatch(s)!.group(1)!);
        return n(a.name).compareTo(n(b.name));
      });
    final slides = <OfficeSlide>[];
    for (final file in slideFiles) {
      final xml = XmlDocument.parse(utf8.decode(file.content as List<int>, allowMalformed: true));
      var title = '';
      final lines = <String>[];
      for (final sp in _all(xml, 'sp')) {
        final ph = _first(sp, 'ph');
        final phType = ph == null ? null : _attr(ph, 'type');
        final paragraphs = <String>[];
        final txBody = _first(sp, 'txBody');
        if (txBody == null) continue;
        for (final p in _kids(txBody, 'p')) {
          final t = _text(p, 't').trim();
          if (t.isNotEmpty) paragraphs.add(t);
        }
        if (paragraphs.isEmpty) continue;
        if (phType == 'title' || phType == 'ctrTitle') {
          title = paragraphs.join(' ');
        } else if (phType == 'subTitle') {
          lines.addAll(paragraphs);
        } else {
          lines.addAll(paragraphs);
        }
      }
      for (final tbl in _all(xml, 'tbl')) {
        for (final tr in _kids(tbl, 'tr')) {
          final cells = _kids(tr, 'tc').map((tc) => _text(tc, 't').trim()).toList();
          if (cells.any((c) => c.isNotEmpty)) lines.add(cells.join('  |  '));
        }
      }
      slides.add(OfficeSlide(title: title, lines: lines));
    }
    return OfficeContent.pptx(slides);
  }
}
