
import 'dart:typed_data';

Future<bool> exportFile(String fileName, Uint8List bytes) async {
  throw UnsupportedError(
    'Fitur unduh tidak tersedia pada platform ini.',
  );
}

Future<bool> openDocument(String fileName, Uint8List bytes) async {
  return exportFile(fileName, bytes);
}
