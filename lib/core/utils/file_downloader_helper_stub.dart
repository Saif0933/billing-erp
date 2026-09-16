import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<void> downloadFileToDevice({
  required String content,
  required String fileName,
  String mimeType = 'text/csv;charset=utf-8',
}) async {
  final contentWithBom = content.startsWith('\uFEFF') ? content : '\uFEFF$content';
  final bytes = Uint8List.fromList(utf8.encode(contentWithBom));
  // ignore: deprecated_member_use
  await Share.shareXFiles(
    [
      XFile.fromData(
        bytes,
        name: fileName,
        mimeType: mimeType,
      ),
    ],
    subject: fileName,
    text: 'Exported file: $fileName',
  );
}

Future<void> downloadBytesToDevice({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
}) async {
  // ignore: deprecated_member_use
  await Share.shareXFiles(
    [
      XFile.fromData(
        bytes,
        name: fileName,
        mimeType: mimeType,
      ),
    ],
    subject: fileName,
    text: 'Exported file: $fileName',
  );
}
