import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtil {
  CryptoUtil._();

  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static bool verifyHash(String input, String hash) {
    return sha256Hash(input) == hash;
  }
}
