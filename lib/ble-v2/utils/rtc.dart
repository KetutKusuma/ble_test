class RTC {
  static int getSeconds() {
    int seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (seconds > 946659600) {
      seconds -= 946659600;
    } else {
      seconds = 0;
    }

    return seconds;
  }

  static DateTime getTimeFromSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch((seconds + 946659600) * 1000);
  }
}
