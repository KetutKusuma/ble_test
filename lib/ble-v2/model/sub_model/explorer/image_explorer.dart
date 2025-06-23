import 'package:intl/intl.dart';

class ImageExplorerModel {
  DateTime dateTime;
  List<int> filename;
  int dirIndex;
  int fileSize;

  ImageExplorerModel({
    required this.dateTime,
    required this.filename,
    required this.dirIndex,
    required this.fileSize,
  });

  String getDateTimeString() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  String getDateTimeStringToUTC() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toUtc());
  }

  String getDirIndexString() {
    return dirIndex == 1 ? 'Gambar Toppi lain' : 'Gambar Toppi ini';
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

  static void sort(List<ImageExplorerModel> models, bool ascending) {
    models.sort((a, b) => ascending
        ? a.dateTime.compareTo(b.dateTime)
        : b.dateTime.compareTo(a.dateTime));
  }
}
