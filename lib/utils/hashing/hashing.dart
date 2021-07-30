import 'dart:convert';
import 'package:crypto/crypto.dart';

///convert string to md5
String convertToMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}
