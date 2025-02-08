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
