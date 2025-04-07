library globals;

import 'dart:async';

import 'package:ble_test/utils/enum/role.dart';

Role roleUser = Role.NONE;
int sessionID = 0;

StreamSubscription<List<int>>? lastValueSubscription;

List<int> lastValueG = [];
