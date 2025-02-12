class StorageModel {
  final int total;
  final int used;
  final int sizeFlashMemory;

  StorageModel({
    required this.total,
    required this.used,
    required this.sizeFlashMemory,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
total : $total \nused : $used
      }
''';
  }

  int get getFree {
    return total - used;
  }
}
