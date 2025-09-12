import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';

class CameraModel {
  int brightness;
  int contrast;
  int saturation;
  int specialEffect;
  bool hMirror;
  bool vFlip;
  int jpegQuality;
  int adjustImageRotation;

  CameraModel({
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.specialEffect,
    required this.hMirror,
    required this.vFlip,
    required this.jpegQuality,
    required this.adjustImageRotation,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
brightness : $brightness \ncontrast : $contrast \nsaturation : $saturation \nspecialEffect : $specialEffect \nhMirror : $hMirror \nvFlip : $vFlip \njpegQuality : $jpegQuality
      }
''';
  }

  String getAdjustImageRotationString() {
    num a = adjustImageRotation ~/ 100;
    num b = adjustImageRotation % 100;

    return "$a.$b";
  }

  double adjustImageRotationToDouble() {
    return double.parse(getAdjustImageRotationString());
  }

  void toDeviceConfiguration(CameraSettingModelYaml c) {
    c.brightness = brightness;
    c.contrast = contrast;
    c.saturation = saturation;
    c.setSpecialEffectFromUint8(specialEffect);
    c.hMirror = hMirror;
    c.vFlip = vFlip;
    c.jpegQuality = jpegQuality;
    c.adjustImageRotation = adjustImageRotationToDouble();
  }

  static CameraModel fromDeviceConfiguration(CameraSettingModelYaml c) {
    try {
      return CameraModel(
        brightness: c.brightness ?? 0,
        contrast: c.contrast ?? 0,
        saturation: c.saturation ?? 0,
        specialEffect: c.getSpecialEffectToUint8(),
        hMirror: c.hMirror ?? false,
        vFlip: c.vFlip ?? false,
        jpegQuality: c.jpegQuality ?? 0,
        adjustImageRotation: adjustImageRotationFromFloat(
          c.adjustImageRotation ?? 0.0,
        ),
      );
    } catch (e) {
      throw "Error in CameraModel.fromDeviceConfiguration: $e";
    }
  }

  static int adjustImageRotationFromFloat(double value) {
    if (value < 0 || value >= 360) {
      throw ArgumentError(
        "Adjust image rotation value is overflow, must be >0 and <365",
      );
    }
    return (value * 100).toInt();
  }

  /// Mengonversi nilai string ke rotation dalam rentang 0-35999
  static int adjustImageRotationFromString(String value) {
    // Pisahkan bagian kiri dan kanan dari titik desimal
    var sLeft = value;
    var sRight = "0";
    final pointIndex = value.indexOf('.');

    if (pointIndex != -1) {
      sLeft = value.substring(0, pointIndex);
      sRight = value.substring(pointIndex + 1);
    }

    if (sLeft.isEmpty) sLeft = "0";
    if (sRight.isEmpty) sRight = "0";

    // Jika lebih dari 2 digit setelah koma, kita potong
    if (sRight.length > 2) {
      sRight = sRight.substring(0, 2);
    }

    final iLeft = int.parse(sLeft);
    final iRight = int.parse(sRight);

    return (iLeft * 100) + iRight;
  }
}
