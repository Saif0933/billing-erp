import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class PickedFileData {
  final Uint8List bytes;
  final String name;

  const PickedFileData({
    required this.bytes,
    required this.name,
  });
}

Future<PickedFileData?> pickImageFile() async {
  try {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      return PickedFileData(bytes: bytes, name: file.name);
    }
  } catch (_) {}
  return null;
}
