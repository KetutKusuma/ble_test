class LogExplorerModel {
  final List<int> filename;
  final int fileSize;

  LogExplorerModel({required this.filename, required this.fileSize});

  String getDateString() {
    if (filename.length < 14) return "Invalid Filename";

    String yyyy = String.fromCharCodes(filename.sublist(6, 10));
    String mm = String.fromCharCodes(filename.sublist(10, 12));
    String dd = String.fromCharCodes(filename.sublist(12, 14));

    return "$yyyy-$mm-$dd";
  }

  String getFilenameString() {
    return String.fromCharCodes(filename);
  }

  String getFileSizeString() {
    return _humanizeFileSize(fileSize);
  }

  String _humanizeFileSize(int size) {
    if (size < 1024) return "$size B";
    final suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = 0;
    double fileSize = size.toDouble();

    while (fileSize >= 1024 && i < suffixes.length - 1) {
      fileSize /= 1024;
      i++;
    }

    return "${fileSize.toStringAsFixed(2)} ${suffixes[i]}";
  }
}
