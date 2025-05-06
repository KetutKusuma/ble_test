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

extension DoubleExtensions on double {
  formatDouble() {
    // Buat string dengan 3 angka di belakang koma
    String fixed = toStringAsFixed(3);

    // Ubah ke double lalu kembali ke string agar trailing zero hilang
    return double.parse(fixed).toString();
  }
}
