// ignore_for_file: non_constant_identifier_names

class InitConfig {
  final List<int> KEY;
  final List<int> IV;
  final List<int> SALT1;
  final List<int> SALT2;
  final List<int> SALT3;

  InitConfig({
    required this.KEY,
    required this.IV,
    required this.SALT1,
    required this.SALT2,
    required this.SALT3,
  });

  factory InitConfig.data() {
    return InitConfig(KEY: [
      90,
      224,
      183,
      188,
      169,
      160,
      49,
      9,
      193,
      172,
      179,
      165,
      40,
      227,
      77,
      215,
      229,
      14,
      58,
      218,
      149,
      23,
      79,
      226,
      112,
      87,
      157,
      169,
      252,
      97,
      155,
      238
    ], IV: [
      205,
      86,
      116,
      60,
      10,
      109,
      141,
      165,
      169,
      197,
      47,
      157,
      232,
      175,
      155,
      43
    ], SALT1: [
      144,
      230,
      10,
      194,
      181,
      153,
      60,
      11,
      251,
      154,
      130,
      21,
      173,
      185,
      211,
      247,
      192,
      23,
      99,
      69,
      15,
      86,
      235,
      51,
      13,
      223,
      56,
      65,
      207,
      190,
      97,
      104
    ], SALT2: [
      97,
      148,
      21,
      36,
      150,
      98,
      82,
      238,
      26,
      150,
      66,
      198,
      13,
      208,
      6,
      143,
      178,
      172,
      190,
      4,
      23,
      162,
      51,
      214,
      139,
      235,
      230,
      15,
      59,
      7,
      38,
      24,
    ], SALT3: [
      58,
      18,
      26,
      33,
      84,
      195,
      121,
      159,
      124,
      109,
      77,
      235,
      92,
      180,
      18,
      236,
      202,
      153,
      215,
      244,
      249,
      151,
      2,
      241,
      143,
      139,
      178,
      10,
      59,
      60,
      203,
      162
    ]);
  }
}
