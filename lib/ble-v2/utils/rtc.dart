class RTC {
  static int getSeconds() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 - 946659600;
  }

  static DateTime getTimeFromSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch((seconds + 946659600) * 1000);
  }
}
