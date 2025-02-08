class IdentityModel {
  final List<int> hardwareID;
  final List<int> toppiID;
  final bool isLicense;

  IdentityModel(
      {required this.hardwareID,
      required this.toppiID,
      required this.isLicense});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
hardwareID : $hardwareID \ntoppiID : $toppiID \nisLicense : $isLicense
      }
''';
  }
}
