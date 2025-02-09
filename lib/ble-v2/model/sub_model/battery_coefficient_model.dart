class BatteryCoefficientModel {
  double coefficient1;
  double coefficient2;

  BatteryCoefficientModel(
      {required this.coefficient1, required this.coefficient2});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
coefficient1 : $coefficient1 \ncoefficient2 : $coefficient2
      }
''';
  }
}
