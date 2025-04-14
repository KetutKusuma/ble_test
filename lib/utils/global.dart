library globals;

import 'dart:async';

import 'package:ble_test/utils/enum/role.dart';
import 'package:package_info_plus/package_info_plus.dart';

Role roleUser = Role.NONE;
int sessionID = 0;

StreamSubscription<List<int>>? lastValueSubscription;

List<int> lastValueG = [];
String appName = "BLE-TOPPI-MOBILE";
