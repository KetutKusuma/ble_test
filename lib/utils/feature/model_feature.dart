import 'package:ble_test/utils/feature/enum_feature.dart';

class FeatureModel {
  String feature;
  ReturnType returnType;
  List<Role> role;
  String command;
  bool isButtonForm;
  List<FormModel>? listForm;

  FeatureModel({
    required this.feature,
    required this.returnType,
    required this.role,
    required this.command,
    required this.isButtonForm,
    this.listForm,
  });
}

class FormModel {
  String title;
  FormType type;
  List<FormSelectList>? listSelect;

  FormModel({required this.title, required this.type, this.listSelect});
}

class FormSelectList {
  String title;
  String value;

  FormSelectList({required this.title, required this.value});
}
