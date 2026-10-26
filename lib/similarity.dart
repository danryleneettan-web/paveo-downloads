import 'dart:typed_data';
import 'dart:ui' as ui;

Future<double> comparePhotos(Uint8List a, Uint8List b) async {
  try {
    final c1 = await ui.instantiateImageCodec(a, targetWidth: 16, targetHeight: 16);
    final f1 = await c1.getNextFrame();
    final d1 = (await f1.image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();

    final c2 = await ui.instantiateImageCodec(b, targetWidth: 16, targetHeight: 16);
    final f2 = await c2.getNextFrame();
    final d2 = (await f2.image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();

    var diff = 0;
    for (var i = 0; i < d1.length; i += 4) {
      diff += (d1[i] - d2[i]).abs() + (d1[i + 1] - d2[i + 1]).abs() + (d1[i + 2] - d2[i + 2]).abs();
    }
    return (1.0 - (diff / (16 * 16 * 3 * 255))).clamp(0.0, 1.0);
  } catch (_) {
    return 0.0;
  }
}
