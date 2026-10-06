import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

const _encryptionKey = String.fromEnvironment('POCKIT_ENCRYPTION_KEY');

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

Encrypter _passwordEncrypter() {
  if (_encryptionKey.length != 32) {
    throw StateError('POCKIT_ENCRYPTION_KEY must be exactly 32 characters');
  }

  return Encrypter(AES(Key.fromUtf8(_encryptionKey)));
}

IV _generateIV() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  return IV(Uint8List.fromList(bytes));
}

String encryptPassword(String text) {
  final iv = _generateIV();
  final encrypted = _passwordEncrypter().encrypt(text, iv: iv);

  return '${iv.base64}:${encrypted.base64}';
}

String decryptPassword(String text) {
  final encrypter = _passwordEncrypter();
  final parts = text.split(':');

  if (parts.length != 2) {
    return encrypter.decrypt64(text, iv: IV.fromLength(16));
  }

  final iv = IV.fromBase64(parts[0]);
  return encrypter.decrypt64(parts[1], iv: iv);
}
