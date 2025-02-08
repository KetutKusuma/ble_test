class ImageModel {
  final int allImage;
  final int allUnsent;
  final int selfAll;
  final int selfUnsent;
  final int nearAll;
  final int nearUnsent;

  ImageModel({
    required this.allImage,
    required this.allUnsent,
    required this.selfAll,
    required this.selfUnsent,
    required this.nearAll,
    required this.nearUnsent,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
allImage : $allImage \nallUnsent : $allUnsent \nselfAll : $selfAll \nselfUnsent : $selfUnsent \nnearAll : $nearAll \nnearUnsent : $nearUnsent
      }
''';
  }
}
