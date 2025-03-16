import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class ConfigModel {
  final String config;
  final String urlUpload;
  final String portUpload;
  final String protocolUpload;
  final String urlHelpUpload;
  final String urlTestOCR;

  ConfigModel(
    this.config,
    this.urlUpload,
    this.portUpload,
    this.protocolUpload,
    this.urlHelpUpload,
    this.urlTestOCR,
  );

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      json['config'],
      json['upload']['url'],
      json['upload']['port'],
      json['upload']['protocol'],
      json['help_upload']['url'],
      json['test_ocr']['url'],
    );
  }

  @override
  String toString() {
    return '''
    {
    config : $config \nurlUpload : $urlUpload \nportUpload : $portUpload \nprotocolUpload : $protocolUpload \nurlForceUpload : $urlHelpUpload \nurlTestOCR : $urlTestOCR
    }''';
  }
}

class ConfigProvider with ChangeNotifier {
  late ConfigModel _config;

  ConfigModel get config => _config;

  loadConfig() async {
    String configFile = 'config.yaml';

    if (config.config == 'production') {
      configFile = 'config-staging.yaml';
    }

    final yamlString = await rootBundle.loadString("assets/config/$configFile");
    final yaml = loadYaml(yamlString);

    _config = ConfigModel.fromJson(yaml);

    notifyListeners();
  }
}
