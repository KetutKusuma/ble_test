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

  static DateTime getTimeFromSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch((seconds + 946684800) * 1000);
  }
}
