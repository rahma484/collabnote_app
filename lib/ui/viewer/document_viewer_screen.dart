import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/local_file_service.dart';
import '../core/app_colors.dart';
import '../core/app_widgets.dart';
import 'office_reader.dart';

/// Membuka dokumen LANGSUNG di dalam aplikasi (tanpa mengunduh):
/// docx, xlsx, pptx dibaca oleh [OfficeReader]; gambar, md, txt, csv ditampilkan langsung.
/// PDF dibuka oleh sistem (tab baru di browser / aplikasi PDF di perangkat).
Future<void> openFileInApp(
  BuildContext context, {
  required String fileName,
  required Uint8List bytes,
  String? title,
}) async {
  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  if (ext == 'pdf') {
    try {
      final ok = await context.read<LocalFileService>().openDocument(fileName, bytes);
      if (context.mounted && !ok) showSnack(context, 'PDF gagal dibuka.');
    } catch (e) {
      if (context.mounted) showSnack(context, 'PDF gagal dibuka: $e');
    }
    return;
  }
  await pushSlideUp<void>(context, DocumentViewerScreen(fileName: fileName, bytes: bytes, title: title));
}

class DocumentViewerScreen extends StatefulWidget {
  final String fileName;
  final Uint8List bytes;
  final String? title;

  const DocumentViewerScreen({super.key, required this.fileName, required this.bytes, this.title});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  OfficeContent? _office;
  String? _text;
  String? _error;
  late final String _ext = widget.fileName.contains('.') ? widget.fileName.split('.').last.toLowerCase() : '';

  bool get _isImage => ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(_ext);
  bool get _isText => ['md', 'txt', 'csv'].contains(_ext);
  bool get _isOffice => ['docx', 'xlsx', 'pptx'].contains(_ext);

  @override
  void initState() {
    super.initState();
    try {
      if (_isOffice) {
        _office = OfficeReader.read(_ext, widget.bytes);
      } else if (_isText) {
        _text = utf8.decode(widget.bytes, allowMalformed: true);
      } else if (!_isImage) {
        _error = 'Format .$_ext tidak dapat ditampilkan di dalam aplikasi. Gunakan tombol unduh untuk menyimpannya.';
      }
    } on FormatException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Dokumen gagal dibaca: $e';
    }
  }

  
Future<void> _download() async {
  final files = context.read<LocalFileService>();

  try {
    final ok = await files.exportBytes(
      widget.fileName,
      widget.bytes,
    );

    if (!mounted) return;

    showSnack(
      context,
      ok
          ? 'File berhasil diekspor: ${widget.fileName}'
          : 'Unduhan dibatalkan.',
    );
  } catch (e) {
    if (!mounted) return;

    showSnack(
      context,
      'Gagal mengunduh file: $e',
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: Text(widget.title ?? widget.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(tooltip: 'Unduh salinan', icon: const Icon(Icons.download_outlined), onPressed: _download),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return EmptyState(icon: Icons.insert_drive_file_outlined, title: widget.fileName, message: _error!);
    }
    if (_isImage) {
      return InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.memory(widget.bytes, fit: BoxFit.contain)),
      );
    }
    if (_text != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: SelectableText(_text!, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
      );
    }
    final office = _office!;
    switch (office.kind) {
      case OfficeKind.docx:
        return _DocxView(blocks: office.blocks);
      case OfficeKind.xlsx:
        return _XlsxView(sheets: office.sheets);
      case OfficeKind.pptx:
        return _PptxView(slides: office.slides);
    }
  }
}

// ---------------------------------------------------------------- DOCX

class _DocxView extends StatelessWidget {
  final List<OfficeBlock> blocks;

  const _DocxView({required this.blocks});

  TextStyle _styleFor(OfficeParagraph p, OfficeRun r) {
    double size = 15;
    var weight = r.bold ? FontWeight.w700 : FontWeight.w400;
    Color color = Colors.black87;
    switch (p.heading) {
      case 0:
        size = 26;
        weight = FontWeight.w800;
        color = AppColors.brown;
        break;
      case 1:
        size = 20;
        weight = FontWeight.w800;
        color = AppColors.moccaDark;
        break;
      case 2:
        size = 17.5;
        weight = FontWeight.w700;
        color = AppColors.moccaDark;
        break;
      case null:
        break;
      default:
        size = 16;
        weight = FontWeight.w700;
    }
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      fontStyle: r.italic ? FontStyle.italic : FontStyle.normal,
      decoration: r.underline ? TextDecoration.underline : TextDecoration.none,
      color: color,
      height: 1.45,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const EmptyState(icon: Icons.description_outlined, message: 'Dokumen ini tidak memiliki teks.');
    }
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 3,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: AppColors.brown.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < blocks.length; i++) _block(blocks[i], i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(OfficeBlock block, int index) {
    if (block is OfficeParagraph) {
      final text = Text.rich(
        TextSpan(children: [for (final r in block.runs) TextSpan(text: r.text, style: _styleFor(block, r))]),
      );
      final top = block.heading == null ? 2.0 : (block.heading == 0 ? 2.0 : 14.0);
      return Padding(
        padding: EdgeInsets.only(top: top, bottom: block.heading == null ? 4 : 6),
        child: block.bullet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(left: 6, right: 10, top: 1), child: Text('•', style: TextStyle(fontSize: 16))),
                  Expanded(child: text),
                ],
              )
            : text,
      );
    }
    final table = block as OfficeTable;
    final columns = table.rows.map((r) => r.length).fold<int>(0, (a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(130),
          border: TableBorder.all(color: AppColors.beige),
          children: [
            for (var r = 0; r < table.rows.length; r++)
              TableRow(
                decoration: BoxDecoration(color: r == 0 ? AppColors.card : null),
                children: [
                  for (var c = 0; c < columns; c++)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        c < table.rows[r].length ? table.rows[r][c] : '',
                        style: TextStyle(fontSize: 13, fontWeight: r == 0 ? FontWeight.w700 : FontWeight.w400, color: Colors.black87),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- XLSX

class _XlsxView extends StatefulWidget {
  final List<OfficeSheet> sheets;

  const _XlsxView({required this.sheets});

  @override
  State<_XlsxView> createState() => _XlsxViewState();
}

class _XlsxViewState extends State<_XlsxView> {
  int _index = 0;

  String _letter(int i) {
    var n = i;
    var s = '';
    do {
      s = String.fromCharCode(65 + n % 26) + s;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sheets.isEmpty) {
      return const EmptyState(icon: Icons.table_chart_outlined, message: 'Spreadsheet ini kosong.');
    }
    final sheet = widget.sheets[_index];
    final cols = sheet.columnCount == 0 ? 1 : sheet.columnCount;
    return Column(
      children: [
        if (widget.sheets.length > 1)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              children: [
                for (var i = 0; i < widget.sheets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(widget.sheets[i].name),
                      selected: i == _index,
                      selectedColor: AppColors.mocca,
                      labelStyle: TextStyle(color: i == _index ? Colors.white : AppColors.brown),
                      onSelected: (_) => setState(() => _index = i),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(128),
                columnWidths: const {0: FixedColumnWidth(40)},
                border: TableBorder.all(color: AppColors.beige),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.chip),
                    children: [
                      const SizedBox(height: 30),
                      for (var c = 0; c < cols; c++)
                        Center(child: Text(_letter(c), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    ],
                  ),
                  for (var r = 0; r < sheet.rows.length; r++)
                    TableRow(
                      decoration: BoxDecoration(color: r == 0 ? AppColors.card : Colors.white),
                      children: [
                        Container(
                          color: AppColors.chip,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: Text('${r + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ),
                        for (var c = 0; c < cols; c++)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              c < sheet.rows[r].length ? sheet.rows[r][c] : '',
                              style: TextStyle(fontSize: 12.5, fontWeight: r == 0 ? FontWeight.w700 : FontWeight.w400, color: Colors.black87),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (sheet.truncated)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Menampilkan ${OfficeReader.maxRows} baris pertama.', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- PPTX

class _PptxView extends StatefulWidget {
  final List<OfficeSlide> slides;

  const _PptxView({required this.slides});

  @override
  State<_PptxView> createState() => _PptxViewState();
}

class _PptxViewState extends State<_PptxView> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) {
      return const EmptyState(icon: Icons.slideshow_outlined, message: 'Presentasi ini tidak memiliki slide.');
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                child: AspectRatio(aspectRatio: 16 / 9, child: _SlideCard(slide: widget.slides[i], number: i + 1)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _page > 0 ? () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Slide ${_page + 1} dari ${widget.slides.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: _page < widget.slides.length - 1
                    ? () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  final OfficeSlide slide;
  final int number;

  const _SlideCard({required this.slide, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.brown.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.mocca,
            child: Text(
              slide.title.isEmpty ? 'Slide $number' : slide.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in slide.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(padding: EdgeInsets.only(right: 8), child: Text('•', style: TextStyle(color: Colors.black87))),
                            Expanded(child: Text(line, style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.35))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
