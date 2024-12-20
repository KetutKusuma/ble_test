import 'package:ble_test/utils/feature/model_feature.dart';

import 'enum_feature.dart';

List<FormSelectList> selectSpecialEffect = [
  FormSelectList(title: "No Effect", value: "0"),
  FormSelectList(title: "Negative", value: "1"),
  FormSelectList(title: "Grayscale", value: "2"),
  FormSelectList(title: "Red Tint", value: "3"),
  FormSelectList(title: "Green Tint", value: "4"),
  FormSelectList(title: "Blue Tint", value: "5"),
  FormSelectList(title: "Sepia", value: "6"),
];

List<FormSelectList> selectRole = [
  FormSelectList(title: "Undefined", value: "0"),
  FormSelectList(title: "Regular", value: "1"),
  FormSelectList(title: "Gateway", value: "2"),
];

List<FormSelectList> selectMin2to2 = [
  FormSelectList(title: "-2", value: "-2"),
  FormSelectList(title: "-1", value: "-1"),
  FormSelectList(title: "0", value: "0"),
  FormSelectList(title: "1", value: "1"),
  FormSelectList(title: "2", value: "2"),
];

List<FormSelectList> selectUploadUsing = [
  FormSelectList(title: "Wifi", value: "0"),
  FormSelectList(title: "Gsm Module/sim800l", value: "1"),
  FormSelectList(title: "NB-IoT", value: "2"),
];

List<FormSelectList> selectTimeUTC = [
  FormSelectList(title: "-12", value: "-12"),
  FormSelectList(title: "-11", value: "-11"),
  FormSelectList(title: "-10", value: "-10"),
  FormSelectList(title: "-9", value: "-9"),
  FormSelectList(title: "-8", value: "-8"),
  FormSelectList(title: "-7", value: "-7"),
  FormSelectList(title: "-6", value: "-6"),
  FormSelectList(title: "-5", value: "-5"),
  FormSelectList(title: "-4", value: "-4"),
  FormSelectList(title: "-3", value: "-3"),
  FormSelectList(title: "-2", value: "-2"),
  FormSelectList(title: "-1", value: "-1"),
  FormSelectList(title: "0", value: "0"),
  FormSelectList(title: "1", value: "1"),
  FormSelectList(title: "2", value: "2"),
  FormSelectList(title: "3", value: "3"),
  FormSelectList(title: "4", value: "4"),
  FormSelectList(title: "5", value: "5"),
  FormSelectList(title: "6", value: "6"),
  FormSelectList(title: "7", value: "7"),
  FormSelectList(title: "8", value: "8"),
  FormSelectList(title: "9", value: "9"),
  FormSelectList(title: "10", value: "10"),
  FormSelectList(title: "11", value: "11"),
  FormSelectList(title: "12", value: "12"),
];

List<FeatureModel> listFeature = [
  FeatureModel(
    feature: "id?",
    returnType: ReturnType.string,
    role: [Role.admin, Role.guest, Role.operator, Role.none],
    command: "id?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "id=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "id=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Id",
        type: FormType.setid,
      ),
    ],
  ),
  FeatureModel(
    feature: "set_password=String;String",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.guest, Role.operator, Role.none],
    command: "set_password=String;String",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Id",
        type: FormType.setid,
      ),
    ],
  ),

  // voltage coef 1
  FeatureModel(
      feature: "voltage1_coef?",
      returnType: ReturnType.float,
      role: [Role.admin],
      command: "voltage1_coef?",
      isButtonForm: false),
  FeatureModel(
    feature: "voltage1_coef=float",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "voltage1_coef=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Voltage Coef",
        type: FormType.float,
      ),
    ],
  ),
  // voltage coef 2
  FeatureModel(
      feature: "voltage2_coef?",
      returnType: ReturnType.float,
      role: [Role.admin],
      command: "voltage2_coef?",
      isButtonForm: false),
  FeatureModel(
    feature: "voltage2_coef=float",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "voltage2_coef=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Voltage Coef",
        type: FormType.float,
      ),
    ],
  ),

  // brightness
  FeatureModel(
      feature: "brightness?",
      returnType: ReturnType.int8,
      role: [Role.admin],
      command: "brightness?",
      isButtonForm: false),
  FeatureModel(
    feature: "brightness=int8_t",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "brightness=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Brightness",
        type: FormType.listselect,
        listSelect: selectMin2to2,
      ),
    ],
  ),

  // contrast
  FeatureModel(
    feature: "contrast?",
    returnType: ReturnType.int8,
    role: [Role.admin],
    command: "contrast?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "contrast=int8_t",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "contrast=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Contrast",
        type: FormType.listselect,
        listSelect: selectMin2to2,
      ),
    ],
  ),

  // saturation
  FeatureModel(
    feature: "saturation?",
    returnType: ReturnType.int8,
    role: [Role.admin],
    command: "saturation?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "saturation=int8_t",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "saturation=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Saturation",
        type: FormType.listselect,
        listSelect: selectMin2to2,
      ),
    ],
  ),

  // special effect
  FeatureModel(
    feature: "special_effect?",
    returnType: ReturnType.int8,
    role: [Role.admin],
    command: "special_effect?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "special_effect=uint8_t",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "special_effect=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Special Effect",
        type: FormType.listselect,
        listSelect: selectSpecialEffect,
      ),
    ],
  ),

  // hmirror
  FeatureModel(
    feature: "hmirror?",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "hmirror?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "hmirror=bool",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "hmirror=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Hmirror",
        type: FormType.bool,
      ),
    ],
  ),

  // vflip
  FeatureModel(
    feature: "vflip?",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "vflip?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "vflip=bool",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "vflip=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Vflip",
        type: FormType.bool,
      ),
    ],
  ),

  // role
  FeatureModel(
    feature: "role?",
    returnType: ReturnType.int8,
    role: [Role.admin],
    command: "role?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "role=uint8_t",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "role=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Role",
        type: FormType.listselect,
        listSelect: selectRole,
      ),
    ],
  ),

  // capture schedule
  FeatureModel(
    feature: "capture_schedule?",
    returnType: ReturnType.int8,
    role: [Role.admin, Role.operator],
    command: "capture_schedule?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "capture_schedule=uint8_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "capture_schedule=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Capture Schedule",
        type: FormType.int,
      ),
    ],
  ),

  // capture interval
  FeatureModel(
    feature: "capture_interval?",
    returnType: ReturnType.int8,
    role: [Role.admin, Role.operator],
    command: "capture_interval?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "capture_interval=uint8_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "capture_interval=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Capture Interval",
        type: FormType.int,
      ),
    ],
  ),

  // capture count
  FeatureModel(
    feature: "capture_count?",
    returnType: ReturnType.int8,
    role: [Role.admin, Role.operator],
    command: "capture_count?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "capture_count=uint8_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "capture_count=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Capture Count",
        type: FormType.int,
      ),
    ],
  ),

  // capture recent limit
  FeatureModel(
    feature: "capture_recent_limit?",
    returnType: ReturnType.int8,
    role: [Role.admin, Role.operator],
    command: "capture_recent_limit?",
    isButtonForm: false,
  ),
  FeatureModel(
      feature: "capture_recent_limit=uint8_t",
      returnType: ReturnType.bool,
      role: [Role.admin, Role.operator],
      command: "capture_recent_limit=&",
      isButtonForm: true,
      listForm: [
        FormModel(
          title: "Capture Recent Limit",
          type: FormType.int,
        ),
      ]),

  // special capture date
  FeatureModel(
    feature: "special_capture_date?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "special_capture_date?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "special_capture_date=uint8_t;bool",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "special_capture_date=&;&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Special Capture Date Day",
        type: FormType.int,
      ),
      FormModel(
        title: "Special Capture Enable",
        type: FormType.bool,
      )
    ],
  ),

  // special capture schedule
  FeatureModel(
    feature: "special_capture_schedule?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "special_capture_schedule?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "special_capture_schedule=uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "special_capture_schedule=&;&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Special Capture Schedule",
        type: FormType.int,
      ),
    ],
  ),

  // special capture interval
  FeatureModel(
    feature: "special_capture_interval?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "special_capture_interval?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "special_capture_interval=uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "special_capture_interval=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Special Capture Interval",
        type: FormType.int,
      ),
    ],
  ),

  // special capture count
  FeatureModel(
    feature: "special_capture_count?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "special_capture_count?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "special_capture_count=uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "special_capture_count=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Special Capture Count",
        type: FormType.int,
      ),
    ],
  ),

  // receive enable
  FeatureModel(
    feature: "receive_enable?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_enable?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "receive_enable=bool",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_enable=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Receive Enable",
        type: FormType.bool,
      ),
    ],
  ),

  // receive schedule
  FeatureModel(
    feature: "receive_schedule?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_schedule?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "receive_schedule=uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_schedule=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Receive Schedule",
        type: FormType.int,
      ),
    ],
  ),

  // receive interval
  FeatureModel(
    feature: "receive_interval?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_interval?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "receive_interval=uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_interval=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Receive Interval",
        type: FormType.int,
      ),
    ],
  ),

  // receive count
  FeatureModel(
    feature: "receive_count?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_count?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "receive_count=uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_count=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Receive Count",
        type: FormType.int,
      ),
    ],
  ),

  // receive time adjust
  FeatureModel(
    feature: "receive_time_adjust?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_time_adjust?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "receive_time_adjust=uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "receive_time_adjust=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Receive Time Adjust",
        type: FormType.int,
      ),
    ],
  ),

  // destination enable
  FeatureModel(
    feature: "destination_enable?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "destination_enable?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "destination_enable=bool",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "destination_enable=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Destination Enable",
        type: FormType.bool,
      ),
    ],
  ),

  // destination id string
  FeatureModel(
    feature: "destination_id_string?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "destination_id_string?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "destination_id_string=string",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "destination_id_string=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Destination ID String",
        type: FormType.setid,
      ),
    ],
  ),

  // transmit schedule
  FeatureModel(
    feature: "transmit_schedule?uint8_t;uint16_t",
    returnType: ReturnType.int16,
    role: [Role.admin, Role.operator],
    command: "transmit_schedule?&;&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Transmit Schedule Index",
        type: FormType.int,
      ),
      FormModel(
        title: "Transmit Schedule Minutes",
        type: FormType.int,
      ),
    ],
  ),
  FeatureModel(
    feature: "transmit_schedule=uint8_t;uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "transmit_schedule=&;&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Transmit Schedule Index",
        type: FormType.int,
      ),
      FormModel(
        title: "Transmit Schedule Minutes",
        type: FormType.int,
      ),
    ],
  ),

  // server
  FeatureModel(
    feature: "server?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "server?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "server=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "server=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Server",
        type: FormType.text,
      ),
    ],
  ),

  // port
  FeatureModel(
    feature: "port?",
    returnType: ReturnType.int16,
    role: [Role.admin],
    command: "port?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "port=int16_t",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "port=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Port",
        type: FormType.int,
      ),
    ],
  ),

  // upload enable
  FeatureModel(
    feature: "upload_enable?",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "upload_enable?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "upload_enable=bool",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "upload_enable=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Upload Enable",
        type: FormType.bool,
      ),
    ],
  ),

  // upload schedule
  FeatureModel(
    feature: "upload_schedule?uint8_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "upload_schedule?",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Upload Schedule Index",
        type: FormType.int,
      ),
    ],
  ),
  FeatureModel(
    feature: "upload_schedule=uint8_t;uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "upload_schedule=&;&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Upload Schedule Index",
        type: FormType.int,
      ),
      FormModel(
        title: "Upload Schedule Minutes",
        type: FormType.int,
      ),
    ],
  ),

  // upload using
  FeatureModel(
    feature: "upload_using?",
    returnType: ReturnType.int8,
    role: [Role.admin, Role.operator],
    command: "upload_using?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "upload_using=bool",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "upload_using=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Upload Using",
        type: FormType.int,
      ),
    ],
  ),

  // upload initial delay
  FeatureModel(
    feature: "upload_initial_delay?",
    returnType: ReturnType.int16,
    role: [Role.admin, Role.operator],
    command: "upload_initial_delay?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "upload_initial_delay=uint16_t",
    returnType: ReturnType.bool,
    role: [Role.admin, Role.operator],
    command: "upload_initial_delay=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Upload Initial Delay",
        type: FormType.int,
      ),
    ],
  ),

  // wifi ssid
  FeatureModel(
    feature: "wifi_ssid?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "wifi_ssid?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "wifi_ssid=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "wifi_ssid=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Wifi SSID",
        type: FormType.text,
      ),
    ],
  ),

  // wifi password
  FeatureModel(
    feature: "wifi_password?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "wifi_password?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "wifi_password=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "wifi_password=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Wifi Password",
        type: FormType.text,
      ),
    ],
  ),

  // modem apn
  FeatureModel(
    feature: "modem_apn?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "modem_apn?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "modem_apn=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "modem_apn=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Modem APN",
        type: FormType.text,
      ),
    ],
  ),

  // meter model
  FeatureModel(
    feature: "meter_model?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "meter_model?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "meter_model=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "meter_model=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Meter Model",
        type: FormType.text,
      ),
    ],
  ),

  // meter sn
  FeatureModel(
    feature: "meter_sn?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "meter_sn?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "meter_sn=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "meter_sn=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Meter SN",
        type: FormType.text,
      ),
    ],
  ),

  // meter seal
  FeatureModel(
    feature: "meter_seal?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "meter_seal?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "meter_seal=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "meter_seal=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Meter Seal",
        type: FormType.text,
      ),
    ],
  ),

  // time utc
  FeatureModel(
    feature: "time_utc?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "time_utc?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "time_utc=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "time_utc=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Time UTC",
        type: FormType.listselect,
        listSelect: selectTimeUTC,
      ),
    ],
  ),

  // time
  FeatureModel(
    feature: "time?",
    returnType: ReturnType.string,
    role: [Role.admin],
    command: "time?",
    isButtonForm: false,
  ),
  FeatureModel(
    feature: "time=string",
    returnType: ReturnType.bool,
    role: [Role.admin],
    command: "time=&",
    isButtonForm: true,
    listForm: [
      FormModel(
        title: "Time",
        type: FormType.date,
      ),
    ],
  ),

  // temperature
  FeatureModel(
    feature: "temperature?",
    returnType: ReturnType.float,
    role: [Role.admin, Role.operator, Role.guest, Role.none],
    command: "temperature?",
    isButtonForm: false,
  ),

  // battery ??
  // responnya kyknya susah nih
  // buat respon battery, storage, files, raw_admin, raw_capture, raw_receive, raw_transmit, raw_upload, raw_meta_data
  FeatureModel(
    feature: "battery?",
    returnType: ReturnType.float,
    role: [Role.admin, Role.operator, Role.guest, Role.none],
    command: "battery?",
    isButtonForm: false,
  ),
];
