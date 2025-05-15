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

  BatteryVoltageCoefficientModelYaml.fromJson(Map<String, dynamic> json) {
    voltageCoefficient1 = json['VoltageCoefficient1'];
    voltageCoefficient2 = json['VoltageCoefficient2'];
  }

  Map<String, dynamic> toMap() {
    return {
      'BatteryVoltageCoefficient': {
        'VoltageCoefficient1': voltageCoefficient1,
        'VoltageCoefficient2': voltageCoefficient2
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

  CameraSettingModelYaml.fromJson(Map<String, dynamic> json) {
    brightness = json['Brigtness'];
    contrast = json['Contrast'];
    saturation = json['Saturation'];
    specialEffect = json['SpecialEffect'];
    hMirror = json['HMirror'];
    vFlip = json['VFlip'];
    jpegQuality = json['JpegQuality'];
    adjustImageRotation = json['AdjustImageRotation'];
  }

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
  bool setDateTime = true;
  GatewayModelYaml? gateway;
  MetaDataModelYaml? metaData;
  BatteryVoltageCoefficientModelYaml? batteryVoltageCoefficient;
  CameraSettingModelYaml? cameraSetting;
  bool printToSerialMonitor = false;

  AdministratorModelYaml({
    this.setRole = "regular",
    this.setEnable = false,
    this.setDateTime = true,
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

  static AdministratorModelYaml fromJson(Map<String, dynamic> json) {
    return AdministratorModelYaml(
      setRole: json['SetRole'],
      setEnable: json['SetEnable'],
      setDateTime: json['SetDateTime'],
      gateway: json['Gateway'] != null
          ? GatewayModelYaml.fromJson(json['Gateway'])
          : null,
      metaData: json['MetaData'] != null
          ? MetaDataModelYaml.fromJson(json['MetaData'])
          : null,
      batteryVoltageCoefficient: json['BatteryVoltageCoefficient'] != null
          ? BatteryVoltageCoefficientModelYaml.fromJson(
              json['BatteryVoltageCoefficient'])
          : null,
      cameraSetting: json['CameraSetting'] != null
          ? CameraSettingModelYaml.fromJson(json['CameraSetting'])
          : null,
      printToSerialMonitor: json['PrintToSerialMonitor'],
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> m = {
      "SetRole": setRoleFromUint8(getRoleToUint8()),
      "SetEnable": setEnable,
      "SetDateTime": true,
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

class DateTimeWithUTCModelModelYaml {
  DateTime dateTime;
  int utc;

  DateTimeWithUTCModelModelYaml({
    required this.dateTime,
    required this.utc,
  });
}

class CaptureScheduleModelYaml {
  String? schedule = "";
  int? count = 0;
  int? interval = 0;
  List<int>? specialDate = [];
  String? specialSchedule = "";
  int? specialCount = 0;
  int? specialInterval = 0;
  int? recentCaptureLimit = 0;

  CaptureScheduleModelYaml({
    this.schedule = "",
    this.count = 0,
    this.interval = 0,
    this.specialDate,
    this.specialSchedule = "",
    this.specialCount = 0,
    this.specialInterval = 0,
    this.recentCaptureLimit = 0,
  });

  CaptureScheduleModelYaml.fromJson(Map<String, dynamic> json) {
    List<int>? spDatehelp = json['SpecialDate'] != null
        ? List<int>.from(json['SpecialDate'])
        : null;
    schedule = json['Schedule'];
    count = json['Count'];
    interval = json['Interval'];
    specialDate = spDatehelp;
    specialSchedule = json['SpecialSchedule'];
    specialCount = json['SpecialCount'];
    specialInterval = json['SpecialInterval'];
    recentCaptureLimit = json['RecentCaptureLimit'];
  }
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
    final scheduleInMinutes =
        ConvertV2().dateTimeStringToMinute(schedule ?? "");
    return scheduleInMinutes;
  }

  // Fungsi untuk mengubah schedule dari uint16
  void setScheduleFromUint16(int schedule) {
    this.schedule = ConvertV2().minuteToDateTimeString(schedule);
  }

  // Fungsi untuk mendapatkan SpecialDate sebagai uint32
  int getSpecialDateToUint32() {
    int value = 0;
    for (final date in specialDate ?? []) {
      if (date >= 1 && date <= 31) {
        value = ConvertV2().setBit(value, date - 1, true) ? 1 : 0;
      }
    }
    return value;
  }

  // Fungsi untuk mengubah SpecialDate dari uint32
  void setSpecialDateFromUint32(int value) {
    specialDate ??= [];
    specialDate!.clear();
    for (int i = 0; i < 31; i++) {
      if (ConvertV2().getBit(value, i)) {
        specialDate!.add(i + 1);
      }
    }
  }

  // Fungsi untuk mendapatkan specialSchedule sebagai uint16
  int getSpecialScheduleToUint16() {
    final specialScheduleInMinutes =
        ConvertV2().dateTimeStringToMinute(specialSchedule ?? "");
    return specialScheduleInMinutes;
  }

  // Fungsi untuk mengubah specialSchedule dari uint16
  void setSpecialScheduleFromUint16(int specialSchedule) {
    this.specialSchedule = ConvertV2().minuteToDateTimeString(specialSchedule);
  }
}

class TransmitScheduleScheduleModelYaml {
  bool? enabled = false;
  String? schedule = "";
  String? destinationID = "";

  TransmitScheduleScheduleModelYaml({
    this.enabled,
    this.schedule,
    this.destinationID,
  });

  static TransmitScheduleScheduleModelYaml fromJson(Map<String, dynamic> json) {
    return TransmitScheduleScheduleModelYaml(
      enabled: json['Enabled'],
      schedule: json['Schedule'],
      destinationID: json['DestinationID'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "Enabled": enabled,
      "Schedule": schedule,
      "DestinationID": destinationID,
    };
  }

  // Fungsi untuk mendapatkan Schedule sebagai uint16
  int getScheduleToUint16() {
    final scheduleInMinutes =
        ConvertV2().dateTimeStringToMinute(schedule ?? "");
    return scheduleInMinutes;
  }

  // Fungsi untuk mengubah Schedule dari uint16
  void setScheduleFromUint16(int schedule) {
    this.schedule = ConvertV2().minuteToDateTimeString(schedule);
  }

  // Fungsi untuk mendapatkan DestinationID sebagai List<uint8>
  List<int> getDestinationIDToArrayUint8() {
    return ConvertV2().stringHexAddressToArrayUint8(destinationID ?? "", 5);
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

  TransmitScheduleModelYaml();

  TransmitScheduleModelYaml.fromJson(Map<String, dynamic> json) {
    schedules[0] =
        TransmitScheduleScheduleModelYaml.fromJson(json['Schedule1']);
    schedules[1] =
        TransmitScheduleScheduleModelYaml.fromJson(json['Schedule2']);
    schedules[2] =
        TransmitScheduleScheduleModelYaml.fromJson(json['Schedule3']);
    schedules[3] =
        TransmitScheduleScheduleModelYaml.fromJson(json['Schedule4']);
    schedules[4] =
        TransmitScheduleScheduleModelYaml.fromJson(json['Schedule5']);
    schedules[5] =
        TransmitScheduleScheduleModelYaml.fromJson(json['Schedule6']);
    schedules[6] =
        TransmitScheduleScheduleModelYaml.fromJson(json['Schedule7']);
    schedules[7] =
        TransmitScheduleScheduleModelYaml.fromJson(json['Schedule8']);
  }

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
  bool? enabled = false;
  String? schedule = "";
  int? timeAdjust = 0;

  ReceiveScheduleScheduleModelYaml({
    this.enabled = false,
    this.schedule = "",
    this.timeAdjust = 0,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
Enabled : $enabled \n
Schedule : $schedule \n
TimeAdjust : $timeAdjust \n
}''';
  }

  static ReceiveScheduleScheduleModelYaml fromJson(Map<String, dynamic> json) {
    return ReceiveScheduleScheduleModelYaml(
      enabled: json['Enabled'],
      schedule: json['Schedule'],
      timeAdjust: json['TimeAdjust'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "Enabled": enabled,
      "Schedule": schedule,
      "TimeAdjust": timeAdjust,
    };
  }

  // Fungsi untuk mendapatkan Schedule sebagai uint16
  int getScheduleToUint16() {
    final scheduleInMinutes =
        ConvertV2().dateTimeStringToMinute(schedule ?? "");
    return scheduleInMinutes;
  }

  // Fungsi untuk mengubah Schedule dari uint16
  void setScheduleFromUint16(int schedule) {
    this.schedule = ConvertV2().minuteToDateTimeString(schedule);
  }
}

class ReceiveScheduleModelYaml {
  @override
  String toString() {
    // TODO: implement toString
    return '''
{
Schedule1 : ${schedules[0]} \n
Schedule2 : ${schedules[1]} \n
Schedule3 : ${schedules[2]} \n
Schedule4 : ${schedules[3]} \n
Schedule5 : ${schedules[4]} \n
Schedule6 : ${schedules[5]} \n
Schedule7 : ${schedules[6]} \n
Schedule8 : ${schedules[7]} \n
Schedule9 : ${schedules[8]} \n
Schedule10 : ${schedules[9]} \n
Schedule11 : ${schedules[10]} \n
Schedule12 : ${schedules[11]} \n
Schedule13 : ${schedules[12]} \n
Schedule14 : ${schedules[13]} \n
Schedule15 : ${schedules[14]} \n
Schedule16 : ${schedules[15]} \n
}''';
  }

  // Menggunakan List agar lebih clean
  final List<ReceiveScheduleScheduleModelYaml> schedules = List.generate(
    16,
    (_) => ReceiveScheduleScheduleModelYaml(),
  );

  ReceiveScheduleModelYaml();

  ReceiveScheduleModelYaml.fromJson(Map<String, dynamic> json) {
    schedules[0] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule1']);
    schedules[1] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule2']);
    schedules[2] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule3']);
    schedules[3] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule4']);
    schedules[4] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule5']);
    schedules[5] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule6']);
    schedules[6] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule7']);
    schedules[7] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule8']);
    schedules[8] = ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule9']);
    schedules[9] =
        ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule10']);
    schedules[10] =
        ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule11']);
    schedules[11] =
        ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule12']);
    schedules[12] =
        ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule13']);
    schedules[13] =
        ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule14']);
    schedules[14] =
        ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule15']);
    schedules[15] =
        ReceiveScheduleScheduleModelYaml.fromJson(json['Schedule16']);
  }

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

  UploadScheduleScheduleModelYaml({
    this.enabled = false,
    this.schedule = "",
  });

  static UploadScheduleScheduleModelYaml fromJson(Map<String, dynamic> json) {
    return UploadScheduleScheduleModelYaml(
      enabled: json['Enabled'],
      schedule: json['Schedule'],
    );
  }

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

  UploadScheduleModelYaml();

  UploadScheduleModelYaml.fromJson(Map<String, dynamic> json) {
    schedules[0] = UploadScheduleScheduleModelYaml.fromJson(json['Schedule1']);
    schedules[1] = UploadScheduleScheduleModelYaml.fromJson(json['Schedule2']);
    schedules[2] = UploadScheduleScheduleModelYaml.fromJson(json['Schedule3']);
    schedules[3] = UploadScheduleScheduleModelYaml.fromJson(json['Schedule4']);
    schedules[4] = UploadScheduleScheduleModelYaml.fromJson(json['Schedule5']);
    schedules[5] = UploadScheduleScheduleModelYaml.fromJson(json['Schedule6']);
    schedules[6] = UploadScheduleScheduleModelYaml.fromJson(json['Schedule7']);
    schedules[7] = UploadScheduleScheduleModelYaml.fromJson(json['Schedule8']);
  }

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

  ChangePasswordModelYaml({
    this.oldPassword = "",
    this.newPassword = "",
  });

  static ChangePasswordModelYaml fromJson(Map<String, dynamic> json) {
    return ChangePasswordModelYaml(
      oldPassword: json['OldPassword'],
      newPassword: json['NewPassword'],
    );
  }
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

  DeviceConfiguration.fromJson(Map<String, dynamic> json) {
    administrator = json['Administrator'] != null
        ? AdministratorModelYaml.fromJson(json['Administrator'])
        : null;
    captureSchedule = json['CaptureSchedule'] != null
        ? CaptureScheduleModelYaml.fromJson(json['CaptureSchedule'])
        : null;
    transmitSchedule = json['TransmitSchedule'] != null
        ? TransmitScheduleModelYaml.fromJson(json['TransmitSchedule'])
        : null;
    receiveSchedule = json['ReceiveSchedule'] != null
        ? ReceiveScheduleModelYaml.fromJson(json['ReceiveSchedule'])
        : null;
    uploadSchedule = json['UploadSchedule'] != null
        ? UploadScheduleModelYaml.fromJson(json['UploadSchedule'])
        : null;
    changePassword = json['ChangePassword'] != null
        ? ChangePasswordModelYaml.fromJson(json['ChangePassword'])
        : null;
  }

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
    m.addAll(receiveSchedule!.toMap());
    m.addAll(uploadSchedule!.toMap());

    return m;
  }

  void validate() {
    try {
      if (administrator == null) {
        throw "Administrator is null";
      }

      administrator!.setRole = administrator!.setRole.toLowerCase();
      String role = administrator!.setRole;
      if (role != "regular" || role != "gateway") {
        throw "Role must be regular or gateway";
      }

      GatewayModelYaml? gateway = administrator!.gateway;

      if (gateway == null) {
        throw "Value Administrator > Gateway is null";
      }

      if (gateway.uploadUsing == null) {
        throw "Value Administrator > Gateway > UploadUsing is null";
      }

      String uploadUsing = gateway.uploadUsing!;
      if (!(uploadUsing == "Wifi Internal" ||
          uploadUsing == "Wifi External" ||
          uploadUsing == "Mikrotik Hotspot" ||
          uploadUsing == "Modem GSM UART" ||
          uploadUsing == "Modem NB-IoT UART")) {
        throw "Value Administrator > Gateway > UploadUsing must be Wifi Internal, Wifi External, Mikrotik Hotspot, Modem GSM UART, Modem NB-IoT UART";
      }

      if (gateway.server == null) {
        throw "Value Administrator > Gateway > Server is null";
      }

      if (gateway.server!.length > 48) {
        throw "Value Administrator Gateway > Server must be less than 48 characters";
      }

      if (gateway.wifiSSID == null) {
        throw "Value Administrator > Gateway > WifiSSID is null";
      }

      if (gateway.wifiSSID!.length > 16) {
        throw "Value Administrator > Gateway > WifiSSID must be less than 16 characters";
      }

      if (gateway.wifiPassword == null) {
        throw "Value Administrator > Gateway > WifiPassword is null";
      }

      if (gateway.modemAPN == null) {
        throw "Value Administrator > Gateway > ModemAPN is null";
      }

      if (gateway.modemAPN!.length > 16) {
        throw "Value Administrator > Gateway > ModemAPN must be less than 16 characters";
      }

      MetaDataModelYaml? metaData = administrator!.metaData;
      if (metaData == null) {
        throw "Value Administrator > MetaData is null";
      }

      if (metaData.meterModel == null) {
        throw "Value Administrator > MetaData > MeterModel is null";
      }

      if (metaData.meterModel!.length > 16) {
        throw "Value Administrator > MetaData > MeterModel must be less than 16 characters";
      }

      if (metaData.meterSN == null) {
        throw "Value Administrator > MetaData > MeterSerialNumber is null";
      }

      if (metaData.meterSN!.length > 16) {
        throw "Value Administrator > MetaData > MeterSerialNumber must be less than 16 characters";
      }

      if (metaData.meterSeal == null) {
        throw "Value Administrator > MetaData > MeterSeal is null";
      }

      if (metaData.meterSeal!.length > 16) {
        throw "Value Administrator > MetaData > MeterSeal must be less than 16 characters";
      }

      if (metaData.custom == null) {
        throw "Value Administrator > MetaData > Custom is null";
      }

      if (metaData.custom!.length > 32) {
        throw "Value Administrator > MetaData > Custom must be less than 16 characters";
      }

      if (metaData.timeUTC == null) {
        throw "Value Administrator > MetaData > TimeUTC is null";
      }
      ConvertV2().utcStringToUint8(metaData.timeUTC!);

      // ===  batteryVoltageCoefficient ===

      if (administrator!.batteryVoltageCoefficient == null) {
        throw "Value Administrator > BatteryVoltageCoefficient is null";
      }

      if (administrator!.batteryVoltageCoefficient!.voltageCoefficient1 ==
          null) {
        throw "Value Administrator > BatteryVoltageCoefficient > VoltageCoefficient1 is null";
      }

      String? bat1 = checkBattery(
          administrator!.batteryVoltageCoefficient!.voltageCoefficient1!);
      if (bat1 != null) {
        throw "Value Administrator > BatteryVoltageCoefficient > VoltageCoefficient1 $bat1";
      }

      if (administrator!.batteryVoltageCoefficient!.voltageCoefficient2 ==
          null) {
        throw "Value Administrator > BatteryVoltageCoefficient > VoltageCoefficient2 is null";
      }

      String? bat2 = checkBattery(
          administrator!.batteryVoltageCoefficient!.voltageCoefficient2!);
      if (bat2 != null) {
        throw "Value Administrator > BatteryVoltageCoefficient > VoltageCoefficient2 $bat2";
      }

      // ===  cameraSetting ===

      CameraSettingModelYaml? camera = administrator!.cameraSetting;

      if (camera == null) {
        throw "Value Administrator > CameraSetting is null";
      }

      String? checkBrightness = checkCamera(camera.brightness, "Brigtness");
      if (checkBrightness != null) {
        throw checkBrightness;
      }

      String? checkContrast = checkCamera(camera.contrast, "Contrast");
      if (checkContrast != null) {
        throw checkContrast;
      }

      String? checkSaturation = checkCamera(camera.saturation, "Saturation");
      if (checkSaturation != null) {
        throw checkSaturation;
      }

      String? specialEffect = camera.specialEffect;
      if (specialEffect != null) {
        throw "Value Administrator > CameraSetting > SpecialEffect is null";
      }

      if (!(specialEffect == "no_effect" ||
          specialEffect == "negative" ||
          specialEffect == "grayscale" ||
          specialEffect == "red_tint" ||
          specialEffect == "green_tint" ||
          specialEffect == "blue_tint" ||
          specialEffect == "sephia")) {
        throw "Value Administrator > CameraSetting > SpecialEffect must between 0 and 6";
      }
      if (camera.jpegQuality == null) {
        throw "Value Administrator > CameraSetting > JpegQuality is null";
      }

      if (camera.jpegQuality! < 5 || camera.jpegQuality! > 63) {
        throw "Value Administrator > CameraSetting > JpegQuality must between 5 and 63";
      }
    } catch (e) {
      throw "Error validate catch : $e";
    }
  }

  String? checkBattery(double bat) {
    if (bat < 0.5 || bat > 1.5) {
      return "must between 0.5 and 1.5";
    }
    return null;
  }

  String? checkCamera(int? value, String name) {
    if (value == null) {
      return "Value Administrator > CameraSetting > $name is null";
    }
    if (value < -2 || value > 2) {
      return "Value Administrator > CameraSetting > $name must between -2 and 2";
    }
    return null;
  }
}
