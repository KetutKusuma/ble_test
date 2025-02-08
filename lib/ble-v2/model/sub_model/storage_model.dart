class StorageModel {
  final int total;
  final int used;

  StorageModel({required this.total, required this.used});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
total : $total \nused : $used
      }
''';
  }
}
