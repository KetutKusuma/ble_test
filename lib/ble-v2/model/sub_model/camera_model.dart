class CameraModel {
  int brightness;
  int contrast;
  int saturation;
  int specialEffect;
  bool hMirror;
  bool vFlip;
  int jpegQuality;

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
