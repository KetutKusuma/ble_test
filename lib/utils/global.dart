library globals;

import 'dart:async';

import 'package:ble_test/utils/enum/role.dart';

Role roleUser = Role.NONE;

StreamSubscription<List<int>>? lastValueSubscription;

List<int> lastValueG = [];
