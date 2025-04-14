class GatewayModel {
  // untuk handle >= 2.21

  int paramCount;
  String server;
  int port;
  int uploadUsing;
  int uploadInitialDelay;
  WifiModel wifi;
  String modemAPN;

  GatewayModel({
    required this.paramCount,
    required this.server,
    required this.port,
    required this.uploadUsing,
    required this.uploadInitialDelay,
    required this.modemAPN,
    required this.wifi,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
server : $server \nport : $port \nuploadUsing : $uploadUsing \nuploadInitialDelay : $uploadInitialDelay \nwifi : $wifi
}
''';
  }

  static String getUploadUsingString(uploadUsing) {
    if (uploadUsing == 0) {
      return "Wifi Internal";
    } else if (uploadUsing == 1) {
      return "WiFi External";
    } else if (uploadUsing == 2) {
      return "Mikrotik Hotspot";
    } else if (uploadUsing == 3) {
      return "Modem GSM UART";
    } else if (uploadUsing == 4) {
      return "Modem NB-IoT UART";
    } else {
      return "";
    }
  }

  static List<Map<String, dynamic>> listMapUploadUsing = [
    {"title": "Wifi Internal", "value": 0},
    {"title": "Wifi External", "value": 1},
    {"title": "Mikrotik Hotspot", "value": 2},
    {"title": "Modem GSM UART", "value": 3},
    {"title": "Modem NB-IoT UART", "value": 4},
  ];
}

/// String ssid;
/// String password;
/// bool secure;
/// String mikrotikIP;
/// bool mikrotikLoginSecure;
/// String mikrotikUsername;
/// String mikrotikPassword;
class WifiModel {
  String ssid;
  String password;
  bool secure;
  String mikrotikIP;
  bool mikrotikLoginSecure;
  String mikrotikUsername;
  String mikrotikPassword;

  WifiModel({
    required this.ssid,
    required this.password,
    required this.secure,
    required this.mikrotikIP,
    required this.mikrotikLoginSecure,
    required this.mikrotikUsername,
    required this.mikrotikPassword,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
ssid : $ssid \npass : $password \nsecure : $secure \nmikrotikIP : $mikrotikIP \nmikrotikLoginSecure : $mikrotikLoginSecure \nmikrotikUsername : $mikrotikUsername \nmikrotikPassword : $mikrotikPassword
}''';
  }
}
