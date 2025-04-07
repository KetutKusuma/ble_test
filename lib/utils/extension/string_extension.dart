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

  String changeForCamera() {
    if (this == "254") {
      return "-2";
    }
    if (this == "255") {
      return "-1";
    }
    return this;
  }
}
