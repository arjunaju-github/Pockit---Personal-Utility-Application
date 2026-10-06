import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class NoteIOService {
  Future<String> exportAsText(
    List<Map<String, dynamic>> notes,
    String fileName,
  ) async {
    Directory dir;

    if (Platform.isAndroid) {
      dir = Directory("/storage/emulated/0/Download");
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final safeFileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File("${dir.path}/$safeFileName.txt");

    final content = const JsonEncoder.withIndent("  ").convert({
      "format": "pockit-notes-rich-text",
      "version": 1,
      "notes": notes
          .map(
            (note) => {
              "title": note["title"] ?? "",
              "content": note["content"] ?? "",
              "createdAt": note["createdAt"] ?? "",
            },
          )
          .toList(),
    });

    await file.writeAsString(content);
    return file.path;
  }

  Future<List<Map<String, String>>> importFromText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result == null) return [];

    final file = File(result.files.single.path!);
    final content = await file.readAsString();

    final richNotes = _parseRichTextExport(content);
    if (richNotes != null) {
      return richNotes;
    }

    return _parseLegacyTextExport(content);
  }

  List<Map<String, String>>? _parseRichTextExport(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded["format"] != "pockit-notes-rich-text") return null;

      final exportedNotes = decoded["notes"];
      if (exportedNotes is! List) return [];

      return exportedNotes
          .whereType<Map<String, dynamic>>()
          .map(
            (note) => {
              "title": (note["title"] ?? "").toString(),
              "content": (note["content"] ?? "").toString(),
              "createdAt": (note["createdAt"] ?? "").toString(),
            },
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  List<Map<String, String>> _parseLegacyTextExport(String content) {
    List<Map<String, String>> notes = [];

    final parts = content.split("----END----");

    for (var part in parts) {
      if (part.trim().isEmpty) continue;

      String title = "";
      String body = "";

      final lines = part.split("\n");
      final bodyStart = part.indexOf("CONTENT:");

      for (var line in lines) {
        if (line.startsWith("TITLE:")) {
          title = line.replaceFirst("TITLE:", "").trim();
        }
      }

      if (bodyStart != -1) {
        body = part.substring(bodyStart + "CONTENT:".length).trim();
      }

      notes.add({"title": title, "content": body});
    }

    return notes;
  }
}
