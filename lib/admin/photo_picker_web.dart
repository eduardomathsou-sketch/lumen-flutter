// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import 'photo_types.dart';

export 'photo_types.dart';

const bool photoPickerSupported = true;

/// Lado maior da foto enviada: o mesmo que a API guarda.
const _maxSide = 1600;

/// Arquivo original acima disso nem é aberto (protege a memória do navegador).
const _maxOriginalBytes = 25 * 1024 * 1024;

/// Abre o seletor de arquivos e devolve a foto já reduzida em JPEG.
/// Reduzir aqui faz fotos de celular (5 a 12 MB) caberem no limite de envio.
Future<PickedPhoto?> pickPhoto() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/png,image/webp';
  final chosen = Completer<web.File?>();
  void finish(web.File? file) {
    if (!chosen.isCompleted) chosen.complete(file);
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final files = input.files;
      finish(files != null && files.length > 0 ? files.item(0) : null);
    }).toJS,
  );
  input.addEventListener('cancel', ((web.Event _) => finish(null)).toJS);
  input.click();
  final file = await chosen.future;
  if (file == null) return null;
  if (file.size > _maxOriginalBytes) {
    throw const PhotoPickException('Foto grande demais: escolha uma de até 25 MB.');
  }
  return _shrink(file);
}

Future<PickedPhoto> _shrink(web.File file) async {
  final web.ImageBitmap bitmap;
  try {
    bitmap = await web.window.createImageBitmap(file).toDart;
  } catch (_) {
    throw const PhotoPickException(
      'Não consegui abrir essa foto. Use JPG, PNG ou WebP '
      '(foto HEIC do iPhone: exporte como JPG antes).',
    );
  }
  final scale = math.min(
    1.0,
    _maxSide / math.max(bitmap.width, bitmap.height),
  );
  final width = math.max(1, (bitmap.width * scale).round());
  final height = math.max(1, (bitmap.height * scale).round());
  final canvas = web.HTMLCanvasElement()
    ..width = width
    ..height = height;
  final context = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
  context
    ..fillStyle = '#FFFFFF'.toJS
    ..fillRect(0, 0, width, height)
    ..imageSmoothingQuality = 'high'
    ..drawImage(bitmap, 0, 0, width, height);
  bitmap.close();
  final blob = Completer<web.Blob?>();
  canvas.toBlob(
    ((web.Blob? result) => blob.complete(result)).toJS,
    'image/jpeg',
    0.88.toJS,
  );
  final jpeg = await blob.future;
  if (jpeg == null) {
    throw const PhotoPickException('Não consegui preparar a foto. Tente outra.');
  }
  final buffer = await jpeg.arrayBuffer().toDart;
  return PickedPhoto(buffer.toDart.asUint8List(), 'image/jpeg');
}
