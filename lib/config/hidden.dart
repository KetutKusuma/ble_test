import 'dart:convert';
import 'dart:developer';

import 'package:ble_test/config/config.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

class Hidden {
  Future<http.Response> sendRequest(
      String hardwareID, String toppiID, ConfigModel config) async {
    final yamlString = await rootBundle.loadString("assets/config/hidden.yaml");
    final yaml = loadYaml(yamlString);

    List<int> licenseList = base64.decode(yaml["license"]);
    String license = utf8.decode(licenseList);
    final url = Uri.parse(license);
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "HardwareID": hardwareID,
      "ToppiID": toppiID,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      return response;
    } catch (e) {
      log('Error dapat send request: $e');
      return http.Response("Error dapat send request", 500);
    }
  }
}
