// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedFileData {
  final Uint8List bytes;
  final String name;

  const PickedFileData({
    required this.bytes,
    required this.name,
  });
}

Future<PickedFileData?> pickImageFile() async {
  final completer = Completer<PickedFileData?>();

  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/jpg,image/webp,image/svg+xml';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(PickedFileData(bytes: result, name: file.name));
        } else if (result is ByteBuffer) {
          completer.complete(
            PickedFileData(bytes: result.asUint8List(), name: file.name),
          );
        } else if (result is List<int>) {
          completer.complete(
            PickedFileData(bytes: Uint8List.fromList(result), name: file.name),
          );
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
    } else {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
  });

  return completer.future;
}
