import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:flutter/services.dart';

class GatewayModelYaml {
  String? server;
  int? port;
  String? uploadUsing;
  int? uploadInitialDelay;
  String? wifiSSID;
  String? wifiPassword;
  bool? wifiSecure;
  String? mikrotikIP;
  bool? mikrotikLoginSecure;
  String? mikrotikUsername;
  String? mikrotikPassword;
  String? modemAPN;

  GatewayModelYaml({
    this.server,
    this.port,
    this.uploadUsing,
    this.uploadInitialDelay,
    this.wifiSSID,
    this.wifiPassword,
    this.wifiSecure,
    this.mikrotikIP,
    this.mikrotikLoginSecure,
    this.mikrotikUsername,
    this.mikrotikPassword,
    this.modemAPN,
  });

  /// Convert from JSON (e.g. from local config or API)
  factory GatewayModelYaml.fromJson(Map<String, dynamic> json) {
    return GatewayModelYaml(
      server: json['Server'],
      port: json['Port'],
      uploadUsing: json['UploadUsing'],
      uploadInitialDelay: json['UploadInitialDelay'],
      wifiSSID: json['WifiSSID'],
      wifiPassword: json['WifiPassword'],
      wifiSecure: json['WifiSecure'],
      mikrotikIP: json['MikrotikIP'],
      mikrotikLoginSecure: json['MikrotikLoginSecure'],
      mikrotikUsername: json['MikrotikUsername'],
      mikrotikPassword: json['MikrotikPassword'],
      modemAPN: json['ModemAPN'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "Gateway": {
        'Server': server,
        'Port': port,
        'UploadUsing': uploadUsing,
        'UploadInitialDelay': uploadInitialDelay,
        'WifiSSID': wifiSSID,
        'WifiPassword': wifiPassword,
        'WifiSecure': wifiSecure,
        'MikrotikIP': mikrotikIP,
        'MikrotikLoginSecure': mikrotikLoginSecure,
        'MikrotikUsername': mikrotikUsername,
        'MikrotikPassword': mikrotikPassword,
        'ModemAPN': modemAPN,
      }
    };
  }

  /// Convert `UploadUsing` to uint8
  int getUploadUsingToUint8() {
    switch (uploadUsing) {
      case 'Wifi Internal':
        return 0;
      case 'Wifi External':
        return 1;
      case 'Mikrotik Hotspot':
        return 2;
      case 'Modem GSM UART':
        return 3;
      case 'Modem NB-IoT UART':
        return 4;
      default:
        return 0; // default to wifi-internal
    }
  }

  /// Set `UploadUsing` from uint8
  String setUploadUsingFromUint8(int value) {
    switch (value) {
      case 0:
        return 'Wifi Internal';
      case 1:
        return 'Wifi External';
      case 2:
        return 'Mikrotik Hotspot';
      case 3:
        return 'Modem GSM UART';
      case 4:
        return 'Modem NB-IoT UART';
      default:
        return 'Wifi Internal';
    }
  }
}

class MetaDataModelYaml {
  String? meterModel;
  String? meterSN;
  String? meterSeal;
  String? customerId;
  int? numberDigit;
  int? numberDecimal;
  String? custom;
  String? timeUTC;

  MetaDataModelYaml({
    this.meterModel,
    this.meterSN,
    this.meterSeal,
    this.customerId,
    this.numberDigit,
    this.numberDecimal,
    this.custom,
    this.timeUTC,
  });

  /// Parse from JSON
  factory MetaDataModelYaml.fromJson(Map<String, dynamic> json) {
    return MetaDataModelYaml(
      meterModel: json['MeterModel'],
      meterSN: json['MeterSN'],
      meterSeal: json['MeterSeal'],
      customerId: json['CustomerId'],
      numberDigit: json['NumberDigit'],
      numberDecimal: json['NumberDecimal'],
      custom: json['Custom'],
      timeUTC: json['TimeUTC'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toMap() {
    return {
      "MetaData": {
        'MeterModel': meterModel,
        'MeterSN': meterSN,
        'MeterSeal': meterSeal,
        'CustomerId': customerId,
        'NumberDigit': numberDigit,
        'NumberDecimal': numberDecimal,
        'Custom': custom,
        'TimeUTC': timeUTC,
      }
    };
  }

  /// Convert `TimeUTC` (e.g. "07:00") to uint8
  int getTimeUTCToUint8() {
    if (timeUTC == null) {
      return 0;
    }
    final parts = timeUTC!.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    return hour;
  }

  /// Set `TimeUTC` from uint8 (e.g. 7 → "07:00")
  String setTimeUTCFromUint8(int timeUTC) {
    final padded = timeUTC.toString().padLeft(2, '0');
    this.timeUTC = '$padded:00';
    return this.timeUTC!;
  }
}

class BatteryVoltageCoefficientModelYaml {
  double? voltageCoefficient1;
  double? voltageCoefficient2;

  BatteryVoltageCoefficientModelYaml({
    this.voltageCoefficient1,
    this.voltageCoefficient2,
  });

  Map<String, dynamic> toMap() {
    return {
      'BatteryVoltageCoefficient': {
        'voltageCoefficient1': voltageCoefficient1,
        'voltageCoefficient2': voltageCoefficient2
      }
    };
  }

  List<int> toBytes() {
    if (voltageCoefficient1 == null || voltageCoefficient2 == null) {
      throw Exception("voltageCoefficient1 or voltageCoefficient2 is null");
    }
    final buffer = ByteData(8);
    buffer.setFloat32(0, voltageCoefficient1!);
    buffer.setFloat32(4, voltageCoefficient2!);
    return buffer.buffer.asUint8List();
  }

  static BatteryVoltageCoefficientModelYaml fromBytes(List<int> bytes) {
    final buffer = ByteData.sublistView(Uint8List.fromList(bytes));
    return BatteryVoltageCoefficientModelYaml(
      voltageCoefficient1: buffer.getFloat32(0),
      voltageCoefficient2: buffer.getFloat32(4),
    );
  }
}

class CameraSettingModelYaml {
  int? brightness;
  int? contrast;
  int? saturation;
  String? specialEffect;
  bool? hMirror;
  bool? vFlip;
  int? jpegQuality;
  double? adjustImageRotation;

  CameraSettingModelYaml({
    this.brightness,
    this.contrast,
    this.saturation,
    this.specialEffect,
    this.hMirror,
    this.vFlip,
    this.jpegQuality,
    this.adjustImageRotation,
  });

  Map<String, dynamic> toMap() {
    return {
      'CameraSetting': {
        'Brigtness': brightness,
        'Contrast': contrast,
        'Saturation': saturation,
        'SpecialEffect': specialEffect,
        'HMirror': hMirror,
        'VFlip': vFlip,
        'JpegQuality': jpegQuality,
        'AdjustImageRotation': adjustImageRotation
      }
    };
  }

  List<int> toBytes() {
    if (brightness == null ||
        contrast == null ||
        saturation == null ||
        specialEffect == null ||
        hMirror == null ||
        vFlip == null ||
        jpegQuality == null ||
        adjustImageRotation == null) {
      throw Exception(
          "brightness or contrast or saturation or specialEffect or hMirror or vFlip or jpegQuality or adjustImageRotation is null");
    }
    final buffer = ByteData(14);
    buffer.setInt8(0, brightness!);
    buffer.setInt8(1, contrast!);
    buffer.setInt8(2, saturation!);
    buffer.setInt8(3, getSpecialEffectToUint8());
    buffer.setUint8(4, (hMirror ?? false) ? 1 : 0);
    buffer.setUint8(5, (vFlip ?? false) ? 1 : 0);
    buffer.setInt8(6, jpegQuality ?? 0);
    buffer.setFloat32(7, adjustImageRotation ?? 0.0);
    return buffer.buffer.asUint8List();
  }

  static CameraSettingModelYaml fromBytes(List<int> bytes) {
    final buffer = ByteData.sublistView(Uint8List.fromList(bytes));
    return CameraSettingModelYaml(
      brightness: buffer.getInt8(0),
      contrast: buffer.getInt8(1),
      saturation: buffer.getInt8(2),
      specialEffect: '',
      hMirror: buffer.getUint8(4) == 1,
      vFlip: buffer.getUint8(5) == 1,
      jpegQuality: buffer.getInt8(6),
      adjustImageRotation: buffer.getFloat32(7),
    );
  }

  // Konversi dari String ke uint8
  int getSpecialEffectToUint8() {
    switch (specialEffect) {
      case "no_effect":
        return 0;
      case "negative":
        return 1;
      case "grayscale":
        return 2;
      case "red_tint":
        return 3;
      case "green_tint":
        return 4;
      case "blue_tint":
        return 5;
      case "sephia":
        return 6;
      default:
        return 0;
    }
  }

  // Konversi dari uint8 ke String
  String? setSpecialEffectFromUint8(int setSpecialEffect) {
    switch (setSpecialEffect) {
      case 0:
        specialEffect = "no_effect";
        return specialEffect;
      case 1:
        specialEffect = "negative";
        return specialEffect;

      case 2:
        specialEffect = "grayscale";
        return specialEffect;

      case 3:
        specialEffect = "red_tint";
        return specialEffect;

      case 4:
        specialEffect = "green_tint";
        return specialEffect;

      case 5:
        specialEffect = "blue_tint";
        return specialEffect;

      case 6:
        specialEffect = "sephia";
        return specialEffect;

      default:
        specialEffect = "no_effect";
        return specialEffect;
    }
  }
}

class AdministratorModelYaml {
  String setRole = "regular";
  bool setEnable = false;
  bool setDateTime = false;
  GatewayModelYaml? gateway;
  MetaDataModelYaml? metaData;
  BatteryVoltageCoefficientModelYaml? batteryVoltageCoefficient;
  CameraSettingModelYaml? cameraSetting;
  bool printToSerialMonitor = false;

  AdministratorModelYaml({
    this.setRole = "regular",
    this.setEnable = false,
    this.setDateTime = false,
    this.gateway,
    this.metaData,
    this.batteryVoltageCoefficient,
    this.cameraSetting,
    this.printToSerialMonitor = false,
  });

  // Fungsi untuk mendapatkan role sebagai uint8
  int getRoleToUint8() {
    return setRole == "gateway" ? 1 : 0;
  }

  // Fungsi untuk mengubah role berdasarkan uint8
  String setRoleFromUint8(int role) {
    switch (role) {
      case 0:
        return "regular";
      case 1:
        return "gateway";
      default:
        return "regular";
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> m = {
      "SetRole": setRoleFromUint8(getRoleToUint8()),
      "SetEnable": setEnable,
      "SetDateTime": false,
      "PrintToSerialMonitor": printToSerialMonitor
    };
    m.addAll(gateway!.toMap());
    m.addAll(metaData!.toMap());
    m.addAll(batteryVoltageCoefficient!.toMap());
    m.addAll(cameraSetting!.toMap());

    Map<String, dynamic> adm = {
      "Administrator": m,
    };

    return adm;
  }
}

class CaptureScheduleModelYaml {
  String schedule = "";
  int count = 0;
  int interval = 0;
  List<int> specialDate = [];
  String specialSchedule = "";
  int specialCount = 0;
  int specialInterval = 0;
  int recentCaptureLimit = 0;

  Map<String, dynamic> toMap() {
    return {
      "CaptureSchedule": {
        "Schedule": schedule,
        "Count": count,
        "Interval": interval,
        "SpecialDate": specialDate,
        "SpecialSchedule": specialSchedule,
        "SpecialCount": specialCount,
        "SpecialInterval": specialInterval,
        "RecentCaptureLimit": recentCaptureLimit
      },
    };
  }

  // Fungsi untuk mendapatkan schedule sebagai uint16
  int getScheduleToUint16() {
    final scheduleInMinutes = ConvertV2().dateTimeStringToMinute(schedule);
    return scheduleInMinutes;
  }

  // Fungsi untuk mengubah schedule dari uint16
  void setScheduleFromUint16(int schedule) {
    this.schedule = ConvertV2().minuteToDateTimeString(schedule);
  }

  // Fungsi untuk mendapatkan SpecialDate sebagai uint32
  int getSpecialDateToUint32() {
    int value = 0;
    for (final date in specialDate) {
      if (date >= 1 && date <= 31) {
        value = ConvertV2().setBit(value, date - 1, true) ? 1 : 0;
      }
    }
    return value;
  }

  // Fungsi untuk mengubah SpecialDate dari uint32
  void setSpecialDateFromUint32(int value) {
    specialDate.clear();
    for (int i = 0; i < 31; i++) {
      if (ConvertV2().getBit(value, i)) {
        specialDate.add(i + 1);
      }
    }
  }

  // Fungsi untuk mendapatkan specialSchedule sebagai uint16
  int getSpecialScheduleToUint16() {
    final specialScheduleInMinutes =
        ConvertV2().dateTimeStringToMinute(specialSchedule);
    return specialScheduleInMinutes;
  }

  // Fungsi untuk mengubah specialSchedule dari uint16
  void setSpecialScheduleFromUint16(int specialSchedule) {
    this.specialSchedule = ConvertV2().minuteToDateTimeString(specialSchedule);
  }
}

class TransmitScheduleScheduleModelYaml {
  bool enabled = false;
  String schedule = "";
  String destinationID = "";

  Map<String, dynamic> toMap() {
    return {
      "Enabled": enabled,
      "Schedule": schedule,
      "DestinationID": destinationID,
    };
  }

  // Fungsi untuk mendapatkan Schedule sebagai uint16
  int getScheduleToUint16() {
    final scheduleInMinutes = ConvertV2().dateTimeStringToMinute(schedule);
    return scheduleInMinutes;
  }

  // Fungsi untuk mengubah Schedule dari uint16
  void setScheduleFromUint16(int schedule) {
    this.schedule = ConvertV2().minuteToDateTimeString(schedule);
  }

  // Fungsi untuk mendapatkan DestinationID sebagai List<uint8>
  List<int> getDestinationIDToArrayUint8() {
    return ConvertV2().stringHexAddressToArrayUint8(destinationID, 5);
  }

  // Fungsi untuk mengubah DestinationID dari List<uint8>
  void setDestinationIDFromArrayUint8(List<int> value) {
    destinationID = arrayUint8ToStringHexAddress(value);
  }

  // Fungsi konversi List<uint8> ke String Hex Address
  String arrayUint8ToStringHexAddress(List<int> array) {
    return array.map((e) => e.toRadixString(16).padLeft(2, '0')).join(":");
  }
}

class TransmitScheduleModelYaml {
  final List<TransmitScheduleScheduleModelYaml> schedules = List.generate(
    8,
    (_) => TransmitScheduleScheduleModelYaml(),
  );

  Map<String, dynamic> toMap() {
    return {
      "TransmitSchedule": {
        "Schedule1": schedules[0].toMap(),
        "Schedule2": schedules[1].toMap(),
        "Schedule3": schedules[2].toMap(),
        "Schedule4": schedules[3].toMap(),
        "Schedule5": schedules[4].toMap(),
        "Schedule6": schedules[5].toMap(),
        "Schedule7": schedules[6].toMap(),
        "Schedule8": schedules[7].toMap(),
      },
    };
  }
}

class ReceiveScheduleScheduleModelYaml {
  bool enabled = false;
  String schedule = "";
  int timeAdjust = 0;

  Map<String, dynamic> toMap() {
    return {
      "Enabled": enabled,
      "Schedule": schedule,
      "TimeAdjust": timeAdjust,
    };
  }

  // Fungsi untuk mendapatkan Schedule sebagai uint16
  int getScheduleToUint16() {
    final scheduleInMinutes = ConvertV2().dateTimeStringToMinute(schedule);
    return scheduleInMinutes;
  }

  // Fungsi untuk mengubah Schedule dari uint16
  void setScheduleFromUint16(int schedule) {
    this.schedule = ConvertV2().minuteToDateTimeString(schedule);
  }
}

class ReceiveScheduleModelYaml {
  // Menggunakan List agar lebih clean
  final List<ReceiveScheduleScheduleModelYaml> schedules = List.generate(
    16,
    (_) => ReceiveScheduleScheduleModelYaml(),
  );

  Map<String, dynamic> toMap() {
    return {
      "ReceiveSchedule": {
        "Schedule1": schedules[0].toMap(),
        "Schedule2": schedules[1].toMap(),
        "Schedule3": schedules[2].toMap(),
        "Schedule4": schedules[3].toMap(),
        "Schedule5": schedules[4].toMap(),
        "Schedule6": schedules[5].toMap(),
        "Schedule7": schedules[6].toMap(),
        "Schedule8": schedules[7].toMap(),
        "Schedule9": schedules[8].toMap(),
        "Schedule10": schedules[9].toMap(),
        "Schedule11": schedules[10].toMap(),
        "Schedule12": schedules[11].toMap(),
        "Schedule13": schedules[12].toMap(),
        "Schedule14": schedules[13].toMap(),
        "Schedule15": schedules[14].toMap(),
        "Schedule16": schedules[15].toMap(),
      },
    };
  }

  // Akses menggunakan index, contoh:
  // schedules[0] -> Schedule1
  // schedules[1] -> Schedule2
  // ...
  // schedules[15] -> Schedule16
}

class UploadScheduleScheduleModelYaml {
  bool enabled = false;
  String schedule = "";

  Map<String, dynamic> toMap() {
    return {
      "Enabled": enabled,
      "Schedule": schedule,
    };
  }

  // Fungsi untuk mendapatkan Schedule sebagai uint16
  int getScheduleToUint16() {
    final scheduleInMinutes = ConvertV2().dateTimeStringToMinute(schedule);
    return scheduleInMinutes;
  }

  // Fungsi untuk mengubah Schedule dari uint16
  void setScheduleFromUint16(int schedule) {
    this.schedule = ConvertV2().minuteToDateTimeString(schedule);
  }
}

class UploadScheduleModelYaml {
  // Menggunakan List agar lebih clean dan maintainable
  final List<UploadScheduleScheduleModelYaml> schedules = List.generate(
    8,
    (_) => UploadScheduleScheduleModelYaml(),
  );

  Map<String, dynamic> toMap() {
    return {
      "UploadSchedule": {
        "Schedule1": schedules[0].toMap(),
        "Schedule2": schedules[1].toMap(),
        "Schedule3": schedules[2].toMap(),
        "Schedule4": schedules[3].toMap(),
        "Schedule5": schedules[4].toMap(),
        "Schedule6": schedules[5].toMap(),
        "Schedule7": schedules[6].toMap(),
        "Schedule8": schedules[7].toMap(),
      },
    };
  }

  // Akses menggunakan index:
  // schedules[0] -> Schedule1
  // schedules[1] -> Schedule2
  // ...
  // schedules[7] -> Schedule8
}

class ChangePasswordModelYaml {
  String oldPassword = "";
  String newPassword = "";
}

class DeviceConfiguration {
  AdministratorModelYaml? administrator = AdministratorModelYaml();
  CaptureScheduleModelYaml? captureSchedule = CaptureScheduleModelYaml();
  TransmitScheduleModelYaml? transmitSchedule = TransmitScheduleModelYaml();
  ReceiveScheduleModelYaml? receiveSchedule = ReceiveScheduleModelYaml();
  UploadScheduleModelYaml? uploadSchedule = UploadScheduleModelYaml();
  ChangePasswordModelYaml? changePassword; // `null` jika tidak ada (optional)

  DeviceConfiguration({
    this.administrator,
    this.captureSchedule,
    this.transmitSchedule,
    this.receiveSchedule,
    this.uploadSchedule,
    this.changePassword,
  });

  Map<String, dynamic> toMap() {
    return {
      "Administrator": administrator?.toMap(),
      "CaptureSchedule": captureSchedule?.toMap(),
      "TransmitSchedule": transmitSchedule?.toMap(),
      "ReceiveSchedule": receiveSchedule?.toMap(),
      "UploadSchedule": uploadSchedule?.toMap(),
      "ChangePassword": changePassword,
    };
  }

  String mapJoinString() {
    return (administrator!.toMap().toString() +
        captureSchedule!.toMap().toString() +
        transmitSchedule!.toMap().toString() +
        receiveSchedule!.toMap().toString() +
        uploadSchedule!.toMap().toString());
  }

  Map<String, dynamic> mapJoin() {
    Map<String, dynamic> m = administrator!.toMap();
    m.addAll(captureSchedule!.toMap());
    m.addAll(transmitSchedule!.toMap());
    m.addAll(uploadSchedule!.toMap());

    return m;
  }
}
