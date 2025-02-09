class ImageModel {
  int allImage;
  int allUnsent;
  int selfAll;
  int selfUnsent;
  int nearAll;
  int nearUnsent;

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
