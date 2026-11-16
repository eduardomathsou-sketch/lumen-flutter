import 'dart:typed_data';

/// Foto escolhida pela administração, já reduzida no aparelho (cabe no limite da API).
class PickedPhoto {
  const PickedPhoto(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;
}

class PhotoPickException implements Exception {
  const PhotoPickException(this.message);
  final String message;
}

typedef PhotoPicker = Future<PickedPhoto?> Function();
