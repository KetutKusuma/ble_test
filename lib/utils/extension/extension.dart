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

extension IntExtensions on int {
  String changeZeroString() {
    if (this == 0) {
      return "-";
    }
    return toString();
  }

  bool changeZeroBool() {
    if (this == 0) {
      return false;
    }
    return true;
  }
}

extension BoolExtensions on bool {
  int changeBoolToInt() {
    if (this) {
      return 1;
    }
    return 0;
  }

  String changeBoolToStringIndo() {
    if (this) {
      return "Ya";
    }
    return "Tidak";
  }
}
