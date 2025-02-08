import 'package:ble_test/ble-v2/utils/convert.dart';

class FirmwareModel {
  final String name;
  final String version;

  FirmwareModel({required this.name, required this.version});

  @override
  String toString() {
    // TODO: implement toString

    return '''
{
name : $name \nversion : $version
      }
''';
  }
}

class IdentityModel {
  final List<int> hardwareID;
  final List<int> toppiID;
  final bool isLicense;

  IdentityModel(
      {required this.hardwareID,
      required this.toppiID,
      required this.isLicense});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
hardwareID : $hardwareID \ntoppiID : $toppiID \nisLicense : $isLicense
      }
''';
  }
}

class BatteryVoltageModel {
  final double batteryVoltage1;
  final double batteryVoltage2;

  BatteryVoltageModel(
      {required this.batteryVoltage1, required this.batteryVoltage2});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
batteryVoltage1 : $batteryVoltage1 \nbatteryVoltage2 : $batteryVoltage2
      }
''';
  }
}

class BatteryCoefficientModel {
  final double coefficient1;
  final double coefficient2;

  BatteryCoefficientModel(
      {required this.coefficient1, required this.coefficient2});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
coefficient1 : $coefficient1 \ncoefficient2 : $coefficient2
      }
''';
  }
}

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

class ImageModel {
  final int allImage;
  final int allUnsent;
  final int selfAll;
  final int selfUnsent;
  final int nearAll;
  final int nearUnsent;

  ImageModel({
    required this.allImage,
    required this.allUnsent,
    required this.selfAll,
    required this.selfUnsent,
    required this.nearAll,
    required this.nearUnsent,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
allImage : $allImage \nallUnsent : $allUnsent \nselfAll : $selfAll \nselfUnsent : $selfUnsent \nnearAll : $nearAll \nnearUnsent : $nearUnsent
      }
''';
  }
}

class StorageModel {
  final int total;
  final int used;

  StorageModel({required this.total, required this.used});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
total : $total \nused : $used
      }
''';
  }
}

class MetaDataModel {
  final String modelMeter;
  final String meterSN;
  final String meterSeal;
  final int timeUTC;

  MetaDataModel(
      {required this.modelMeter,
      required this.meterSN,
      required this.meterSeal,
      required this.timeUTC});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
modelMeter : $modelMeter \nmeterSN : $meterSN \nmeterSeal : $meterSeal \ntimeUTC : $timeUTC
      }
''';
  }
}

class GatewayModel {
  final String server;
  final int port;
  final int uploadUsing;
  final int uploadInitialDelay;
  final String wifiSSID;
  final String wifiPassword;
  final String modemAPN;

  GatewayModel(
      {required this.server,
      required this.port,
      required this.uploadUsing,
      required this.uploadInitialDelay,
      required this.wifiSSID,
      required this.wifiPassword,
      required this.modemAPN});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{ 
server : $server \nport : $port \nuploadUsing : $uploadUsing \nuploadInitialDelay : $uploadInitialDelay \nwifiSSID : $wifiSSID \nwifiPassword : $wifiPassword \nmodemAPN : $modemAPN
}
''';
  }

  String getUploadUsingString() {
    if (uploadUsing == 0) {
      return "Wifi";
    } else if (uploadUsing == 1) {
      return "Modul Modem";
    } else if (uploadUsing == 2) {
      return "NB-IoT";
    } else {
      return "";
    }
  }
}

class UploadModel {
  final bool enable;
  final int schedule;

  UploadModel({required this.enable, required this.schedule});

  String getScheduleString() {
    return ConvertV2().minuteToDateTimeString(schedule);
  }

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
enable : $enable \nschedule : $schedule
}
''';
  }
}
