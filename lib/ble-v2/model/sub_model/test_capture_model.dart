class TestCaptureModel {
  int fileSize;
  int totalChunck;
  int crc32;

  TestCaptureModel({
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
