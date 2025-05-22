import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaml/yaml.dart';

class ConfigModel {
  final String config;
  final String urlUpload;
  final int portUpload;
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
  ConfigModel? _config;

  ConfigModel get config => _config ?? ConfigModel('', '', 0, '', '', '');

  loadConfig() async {
    String configFile = 'config.yaml';

    final packageInfo = await PackageInfo.fromPlatform();
    String versionApp = packageInfo.version;
    if (versionApp.contains("staging")) {
      configFile = 'config.yaml';
    }

    if (config.config == 'production') {
      configFile = 'config-staging.yaml';
    }

    final yamlString = await rootBundle.loadString("assets/config/$configFile");
    final yaml = loadYaml(yamlString);

    Map<String, dynamic> yamlMap = Map<String, dynamic>.from(yaml);
    _config = ConfigModel.fromJson(yamlMap);

    notifyListeners();
  }
}
