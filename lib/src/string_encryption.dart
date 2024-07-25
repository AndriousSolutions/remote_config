// import 'package:flutter_string_encryption/flutter_string_encryption.dart'
//     show PlatformStringCryptor;

import 'package:encrypt/encrypt.dart';

///
/// Copyright (C) 2020 Andrious Solutions
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///    http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
///          Created  31 Mar 2020
///
///
class StringCrypt {
  ///
  StringCrypt({
    String? password,
    String? key,
  }) {
    //
    if (password == null || password.trim().isEmpty) {
      password = null;
    } else {
      password = password.trim().padLeft(32, '+');
    }

    if (key == null || key.trim().isEmpty) {
      key = null;
    } else {
      key = key.trim().padLeft(32, '+');
    }

    _iv = key == null ? IV.fromSecureRandom(32) : IV.fromUtf8(key);

    final _key =
        password == null ? Key.fromSecureRandom(32) : Key.fromUtf8(password);

    _encrypter = Encrypter(AES(_key));
  }
  IV? _iv;
  late Encrypter _encrypter;

  ///
  Future<String> en(String data, [String? key]) => encrypt(data, key);

  ///
  Future<String> encrypt(String data, [String? key]) async {
    //
    if (key == null || key.trim().isEmpty) {
      key = null;
    } else {
      key = key.trim().padLeft(32, '+');
    }

    final iv = key == null ? _iv : IV.fromUtf8(key);

    String encrypt;
    try {
      encrypt = _encrypter.encrypt(data, iv: iv).base64;
    } catch (ex) {
      encrypt = '';
      getError(ex);
    }
    return encrypt;
  }

  ///
  Future<String> de(String data, [String? key]) => decrypt(data, key);

  ///
  Future<String> decrypt(String data, [String? key]) async {
    //
    if (key == null || key.trim().isEmpty) {
      key = null;
    } else {
      key = key.trim().padLeft(32, '+');
    }

    final iv = key == null ? _iv : IV.fromUtf8(key);

    String decrypt;
    try {
      decrypt = _encrypter.decrypt(Encrypted.fromBase64(data), iv: iv);
    } catch (ex) {
      decrypt = '';
      getError(ex);
    }
    return decrypt;
  }

  ///
  bool get hasError => _error != null;

  ///
  bool get inError => _error != null;
  Object? _error;

  ///
  Exception? getError([Object? error]) {
    // Return the stored exception
    Exception? ex;
    if (_error != null) {
      ex = _error as Exception;
    }
    // Empty the stored exception
    if (error == null) {
      _error = null;
    } else {
      if (error is! Exception) {
        error = Exception(error.toString());
      }
      _error = error;
    }
    // Return the exception just past if any.
    return ex ??= error as Exception;
  }
}
