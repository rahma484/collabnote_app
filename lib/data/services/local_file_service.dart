
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_export_stub.dart'
    if (dart.library.js_interop) 'file_export_web.dart' as platform_export;

import 'document_opener_stub.dart'
    if (dart.library.io) 'document_opener_io.dart' as document_opener;

class PickedFileData {
  final String name;
  final String extension;
  final Uint8List bytes;

  const PickedFileData({
    required this.name,
    required this.extension,
    required this.bytes,
  });
}

class LocalFileService {
  static const _prefix = 'collabnote_file_';

  Future<String> saveBytes(String fileName, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();

    final key =
        '$_prefix${DateTime.now().microsecondsSinceEpoch}_${fileName.hashCode.abs()}';

    final ok = await prefs.setString(key, base64Encode(bytes));

    if (!ok) {
      throw Exception(
        'File tidak dapat disimpan. Ukuran file mungkin melebihi kapasitas penyimpanan.',
      );
    }

    return 'collabnote://$key';
  }

  Future<Uint8List?> readBytes(String? path) async {
    if (path == null || !path.startsWith('collabnote://')) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(
      path.substring('collabnote://'.length),
    );

    if (value == null) return null;

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String? path) async {
    if (path == null || !path.startsWith('collabnote://')) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      path.substring('collabnote://'.length),
    );
  }

  Future<PickedFileData?> pickFile({
    bool imageOnly = false,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: imageOnly ? FileType.image : FileType.any,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.first;
    final bytes = picked.bytes;

    if (bytes == null) {
      throw Exception(
        'File tidak dapat dibaca. Silakan pilih ulang file tersebut.',
      );
    }

    return PickedFileData(
      name: picked.name,
      extension: (picked.extension ?? '').toLowerCase(),
      bytes: bytes,
    );
  }

  // Mengunduh atau membagikan dokumen.
  Future<bool> exportBytes(
    String fileName,
    Uint8List bytes,
  ) async {
    if (kIsWeb) {
      return platform_export.exportFile(fileName, bytes);
    }

    final mimeType = _getMimeType(fileName);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: mimeType,
          ),
        ],
        fileNameOverrides: [fileName],
        subject: fileName,
      ),
    );

    return true;
  }

  // Membuka dokumen asli.
  Future<bool> openDocument(
    String fileName,
    Uint8List bytes,
  ) async {
    if (kIsWeb) {
      return platform_export.openDocument(fileName, bytes);
    }

    final mimeType = _getMimeType(fileName);

    return document_opener.openDocument(
      fileName,
      bytes,
      mimeType,
    );
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
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
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'md':
        return 'text/markdown';
      default:
        return 'application/octet-stream';
    }
  }
}
