import 'dart:developer';

class RTC {
  static int getSeconds() {
    int seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (seconds > 946684800) {
      seconds -= 946684800;
    } else {
      seconds = 0;
    }

    return seconds;
  }

  static int getTimeUTC() {
    DateTime local = DateTime.now();
    DateTime utc = DateTime.now().toUtc();

    Duration offset = local.difference(utc); // offset dari UTC
    int offsetInSeconds = offset.inSeconds;

    // Bagi offset dalam 30 menit (1800 detik) lalu tambah 24
    int value = 24 + (offsetInSeconds ~/ (30 * 60));

    log("get time utcnya : $offset/$value");

    return value; // tipe int, setara dengan uint8 di Go
  }

  static DateTime getTimeFromSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch((seconds + 946684800) * 1000,
        isUtc: true);
  }
}
