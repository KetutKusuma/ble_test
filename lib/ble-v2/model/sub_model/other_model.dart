class OtherModel {
  MustToDoModel? mustToDo;
  int? neodymiumNotRemoveCounter;
  int? criticalBattery1Counter;
  int? criticalBattery2Counter;

  OtherModel({
    this.mustToDo,
    this.neodymiumNotRemoveCounter,
    this.criticalBattery1Counter,
    this.criticalBattery2Counter,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''  {
      mustToDo : $mustToDo \nneodymiumNotRemoveCounter : $neodymiumNotRemoveCounter \ncriticalBattery1Counter : $criticalBattery1Counter \ncriticalBattery2Counter : $criticalBattery2Counter
      }''';
  }
}

class MustToDoModel {
  bool? format;
  bool? capture;
  bool? upload;

  MustToDoModel({this.format, this.capture, this.upload});

  @override
  String toString() {
    // TODO: implement toString
    return '''  {
      format : $format \ncapture : $capture \nupload : $upload
      }''';
  }
}
