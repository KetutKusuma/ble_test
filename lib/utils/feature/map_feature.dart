import 'package:ble_test/utils/feature/enum_feature.dart';

List<Map> listMapFeature = [
  // ini type button tidak dgn form
  {
    "feature": "id?",
    "return_type": ReturnType.string,
    "role": [
      Role.admin,
      Role.guest,
      Role.operator,
      Role.none,
    ],
    "command": "id?",
    "is_button_form": false,
    "form": [], // list of form
  },

  // ini type button dgn form tapi bukan listselect
  {
    "feature": "id=",
    "return_type": ReturnType.bool,
    "role": [
      Role.admin,
    ],
    "command": "id=&",
    "is_button_form": true,
    // list of form
    "form": [
      {
        "title": "id",
        "type": FormType.setid,
      }
    ],
  },
  // ini form dgn 2 form tapi bukan listselect
  {
    "feature": "set_password=String;String",
    "return_type": ReturnType.bool,
    "role": [
      Role.admin,
      Role.operator,
      Role.guest,
    ],
    "command": "set_password=&;&",
    "is_button_form": true,
    // list of form
    "form": [
      {
        "title": "old password",
        "type": FormType.text,
      },
      {
        "title": "new password",
        "type": FormType.text,
      }
    ],
  },
  {
    "feature": "id?",
    "return_type": ReturnType.string,
    "role": [
      Role.admin,
      Role.guest,
      Role.operator,
      Role.none,
    ],
    "command": "id?",
    "is_button_form": false,
    "form": [], // list of form
  },
];
