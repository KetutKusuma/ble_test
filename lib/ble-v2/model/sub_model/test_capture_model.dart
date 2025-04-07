class ToppiFileModel {
  int fileSize;
  int totalChunck;
  int crc32;

  ToppiFileModel({
    required this.fileSize,
    required this.totalChunck,
    required this.crc32,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
fileSize : $fileSize \ntotalChunck : $totalChunck \ncrc32 : $crc32
    }''';
  }
}

class ToppiExplorerModel {
  int fileSize;
  int totalChunck;
  int crc32;
  int totalFile;

  ToppiExplorerModel({
    required this.fileSize,
    required this.totalChunck,
    required this.crc32,
    required this.totalFile,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
fileSize : $fileSize \ntotalChunck : $totalChunck \ncrc32 : $crc32 \ntotalFile : $totalFile
    }''';
  }
}
