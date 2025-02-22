class ImageModel {
  int? allImage;
  int? allSent;
  int? allUnsent;
  int? selfAll;
  int? selfSent;
  int? selfUnsent;
  int? nearAll;
  int? nearSent;
  int? nearUnsent;

  ImageModel({
    this.allImage,
    this.allSent,
    this.allUnsent,
    this.selfAll,
    this.selfSent,
    this.selfUnsent,
    this.nearAll,
    this.nearSent,
    this.nearUnsent,
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
