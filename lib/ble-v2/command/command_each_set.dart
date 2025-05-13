import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';
import 'package:ble_test/ble-v2/model/sub_model/battery_voltage_model.dart';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/message.dart';

import '../../utils/global.dart';

class CommandSetEach {}

class DateTimeWithUTCModelModelYaml {
  DateTime dateTime;
  int utc;

  DateTimeWithUTCModelModelYaml({
    required this.dateTime,
    required this.utc,
  });
}
