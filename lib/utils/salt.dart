import 'dart:typed_data';

const int SALT_LEN = 32;
// ignore: constant_identifier_names
// const List<int> SALT1 = [
//   144,
//   230,
//   10,
//   194,
//   181,
//   153,
//   60,
//   11,
//   251,
//   154,
//   130,
//   21,
//   173,
//   185,
//   211,
//   247,
//   192,
//   23,
//   99,
//   69,
//   15,
//   86,
//   235,
//   51,
//   13,
//   223,
//   56,
//   65,
//   207,
//   190,
//   97,
//   104
// ];
// // ignore: constant_identifier_names
// const List<int> SALT2 = [
//   97,
//   148,
//   21,
//   36,
//   150,
//   98,
//   82,
//   238,
//   26,
//   150,
//   66,
//   198,
//   13,
//   208,
//   6,
//   143,
//   178,
//   172,
//   190,
//   4,
//   23,
//   162,
//   51,
//   214,
//   139,
//   235,
//   230,
//   15,
//   59,
//   7,
//   38,
//   24
// ];
// // ignore: constant_identifier_names
// const List<int> SALT3 = [
//   58,
//   18,
//   26,
//   33,
//   84,
//   195,
//   121,
//   159,
//   124,
//   109,
//   77,
//   235,
//   92,
//   180,
//   18,
//   236,
//   202,
//   153,
//   215,
//   244,
//   249,
//   151,
//   2,
//   241,
//   143,
//   139,
//   178,
//   10,
//   59,
//   60,
//   203,
//   162,
// ];

const List<int> SALT1 = [
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
];
const List<int> SALT2 = [
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
  24
];
const List<int> SALT3 = [
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
];

Uint8List Salt1Uint8List = Uint8List.fromList(SALT1);
Uint8List Salt2Uint8List = Uint8List.fromList(SALT2);
Uint8List Salt3Uint8List = Uint8List.fromList(SALT3);
