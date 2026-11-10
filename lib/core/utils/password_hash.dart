import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String pinOrPassword) {
  final bytes = utf8.encode(pinOrPassword.trim());
  final digest = sha256.convert(bytes);
  return digest.toString();
}

bool verifyPassword(String pinOrPassword, String hash) {
  return hashPassword(pinOrPassword) == hash;
}
