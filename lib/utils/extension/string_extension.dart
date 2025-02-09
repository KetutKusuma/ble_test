extension StringExtensions on String {
  String changeEmptyString() {
    if (isEmpty) {
      return "-";
    }
    return this;
  }

  String changeZeroString() {
    if (this == "0") {
      return "-";
    }
    return this;
  }
}
