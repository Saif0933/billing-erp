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
  return null;
}
