
import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> openDocument(
  String fileName,
  Uint8List bytes,
  String mimeType,
) async {
  final directory = await getTemporaryDirectory();

  final collabDirectory = Directory(
    '${directory.path}/collabnote_documents',
  );

  if (!await collabDirectory.exists()) {
    await collabDirectory.create(recursive: true);
  }

  final safeFileName = fileName
      .split(RegExp(r'[/\\]'))
      .last
      .replaceAll(RegExp(r'[<>:"|?*]'), '_');

  if (safeFileName.isEmpty) {
    throw Exception('Nama file tidak valid.');
  }

  final file = File(
    '${collabDirectory.path}/$safeFileName',
  );

  await file.writeAsBytes(bytes, flush: true);

  final result = await OpenFilex.open(
    file.path,
    type: mimeType,
  );

  if (result.type != ResultType.done) {
    throw Exception(
      'Dokumen tidak dapat dibuka. '
      'Pastikan aplikasi pendukung sudah terpasang. '
      'Detail: ${result.message}',
    );
  }

  return true;
}
