
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

// Mengunduh dokumen.
Future<bool> exportFile(String fileName, Uint8List bytes) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: _getMimeType(fileName)),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;

  anchor.click();

  Timer(
    const Duration(seconds: 2),
    () => web.URL.revokeObjectURL(url),
  );

  return true;
}

// Membuka dokumen di tab baru jika format didukung browser.
Future<bool> openDocument(String fileName, Uint8List bytes) async {
  final extension = fileName.split('.').last.toLowerCase();

  const supportedFormats = [
    'pdf',
    'png',
    'jpg',
    'jpeg',
  ];

  // Format Office diarahkan ke unduhan karena browser
  // tidak dapat menampilkan dokumen Office secara langsung.
  if (!supportedFormats.contains(extension)) {
    return exportFile(fileName, bytes);
  }

  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: _getMimeType(fileName)),
  );

  final url = web.URL.createObjectURL(blob);

  final openedWindow = web.window.open(url, '_blank');

  if (openedWindow == null) {
    web.URL.revokeObjectURL(url);
    throw Exception(
      'Browser memblokir tab baru. Izinkan pop-up untuk membuka dokumen.',
    );
  }

  // Berikan waktu agar browser selesai membaca dokumen.
  Timer(
    const Duration(minutes: 2),
    () => web.URL.revokeObjectURL(url),
  );

  return true;
}

String _getMimeType(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();

  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'ppt':
      return 'application/vnd.ms-powerpoint';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    default:
      return 'application/octet-stream';
  }
}
