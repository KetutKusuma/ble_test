class CameraModel {
  final int brightness;
  final int contrast;
  final int saturation;
  final int specialEffect;
  final bool hMirror;
  final bool vFlip;
  final int jpegQuality;

  CameraModel(
      {required this.brightness,
      required this.contrast,
      required this.saturation,
      required this.specialEffect,
      required this.hMirror,
      required this.vFlip,
      required this.jpegQuality});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
brightness : $brightness \ncontrast : $contrast \nsaturation : $saturation \nspecialEffect : $specialEffect \nhMirror : $hMirror \nvFlip : $vFlip \njpegQuality : $jpegQuality
      }
''';
  }
}
