class FirmwareModel {
  final String name;
  final String version;

  FirmwareModel({required this.name, required this.version});

  @override
  String toString() {
    // TODO: implement toString

    return '''
{
name : $name \nversion : $version
      }
''';
  }
}
