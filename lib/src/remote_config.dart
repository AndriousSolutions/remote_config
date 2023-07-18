import 'package:firebase_core/firebase_core.dart' show FirebaseApp;
import 'package:firebase_remote_config/firebase_remote_config.dart' as r;
import 'package:flutter/foundation.dart'
    show ChangeNotifier, VoidCallback, mustCallSuper;

import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;
import 'package:remote_config/src/string_encryption.dart' show StringCrypt;

export 'package:firebase_remote_config/firebase_remote_config.dart'
    show RemoteConfigSettings, RemoteConfigValue;

///
class RemoteConfig with ChangeNotifier {
  /// Constructor takes in default values
  RemoteConfig({
    String? key,
    Map<String, dynamic>? defaults,
    int? fetchTimeout,
    int? minimumFetchInterval,
    FirebaseApp? app,
  }) {
    //
    if (key != null && key.trim().isNotEmpty) {
      _key = key;
    }
    //
    if (defaults != null && defaults.isNotEmpty) {
      _defaults = defaults;
    }
    //
    if (fetchTimeout != null && fetchTimeout > 0) {
      _fetchTimeout = fetchTimeout;
    } else {
      // Defaults to one minute.
      _fetchTimeout = 60;
    }
    //
    if (minimumFetchInterval != null && minimumFetchInterval > 0) {
      _minimumFetchInterval = minimumFetchInterval;
    } else {
      // Considered stale after 12 hours.
      _minimumFetchInterval = 12;
    }

    // If explicitly supplied a FirebaseApp
    if (app != null) {
      _app = app;
    }
  }
  String? _key;
  Map<String, dynamic>? _defaults;
  late int _fetchTimeout;
  late int _minimumFetchInterval;
  FirebaseApp? _app;

  StringCrypt? _crypto;

  /// Indicates if initialized correctly.
  bool get isInit => _init;
  bool _init = false;

  /// Indicates if activated.
  bool get activated => _activated;
  bool _activated = false;

  /// References an instance of the underlying Firebase Remote Config plugin.
  r.FirebaseRemoteConfig? get instance => _remoteConfig;
  r.FirebaseRemoteConfig? _remoteConfig;

  /// Initializes the Firebase Remote Config plugin.
  Future<bool> initAsync() async {
    // Already called.
    if (_init) {
      return _init;
    }

    try {
      // If explicitly supplied a FirebaseApp
      if (_app != null) {
        _remoteConfig ??= r.FirebaseRemoteConfig.instanceFor(app: _app!);
        _app = null;
      } else {
        // Gets the instance of RemoteConfig for the default Firebase app.
        _remoteConfig ??= r.FirebaseRemoteConfig.instance;
      }

      await _remoteConfig?.setConfigSettings(r.RemoteConfigSettings(
        fetchTimeout: Duration(seconds: _fetchTimeout),
        minimumFetchInterval: Duration(hours: _minimumFetchInterval),
      ));

      if (_defaults != null) {
        await _remoteConfig?.setDefaults(_defaults!);
      }

      _activated = await fetchAndActivate(throwError: true);

      if (_key == null) {
        final info = await PackageInfo.fromPlatform();
        final key = info.packageName.replaceAll('.', '');
        _key = _remoteConfig?.getString(key);
        // Supply the package name as the key
        if (_key == null || _key!.trim().isEmpty) {
          _key = key;
        }
      }

      if (_key == null || _key!.trim().isEmpty) {
        throw ArgumentError('An invalid key provided to RemoteConfig()');
      }

      _crypto = StringCrypt(password: _key);

      _init = true;
      // Fetch throttled.
      // } on r.FetchThrottledException catch (ex) {
      //   _init = false;
      //   getError(ex);
    } catch (ex) {
      _init = false;
      getError(ex);
    }
    return _init;
  }

  /// Cleans up the Firebase Remote Config plugin.
  @override
  @mustCallSuper
  void dispose() {
    _app = null;
    super.dispose();
  }

  /// Returns the last time a Remote Config value was retrieved.
  /// If no successful the epoch (1970-01-01 UTC) is returned.
  DateTime get lastFetchTime =>
      _remoteConfig?.lastFetchTime ?? DateTime.utc(1970);

  /// Returns the status of the last attempt to fetch Remote Config value.
  r.RemoteConfigFetchStatus get lastFetchStatus =>
      _remoteConfig?.lastFetchStatus ?? r.RemoteConfigFetchStatus.noFetchYet;

  /// Returns the current Remote Config settings.
  r.RemoteConfigSettings get remoteConfigSettings =>
      _remoteConfig?.settings ??
      r.RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 60),
          minimumFetchInterval: const Duration(hours: 12));

  /// Sets the Remote Config settings.
  Future<bool> setConfigSettings(
      r.RemoteConfigSettings? remoteConfigSettings) async {
    var set = _remoteConfig != null;
    if (set) {
      set = remoteConfigSettings != null;
    }
    if (set) {
      await _remoteConfig?.setConfigSettings(remoteConfigSettings!);
    }
    return set;
  }

  /// Set the default Firebase Remote Config values
  Future<bool> setDefaults(Map<String, dynamic>? defaults) async {
    var set = _remoteConfig != null;
    if (set) {
      set = defaults != null;
    }
    if (set) {
      await _remoteConfig?.setDefaults(defaults!);
    }
    return set;
  }

  /// Return encrypted String
  Future<String> en(String data, [String? key]) =>
      _crypto?.en(data, key) ?? Future.value('');

  /// Returns a decrypted String value from Firebase Remote Config.
  Future<String> getStringed(String param, [String? key]) async {
    param = getString(param) ?? '';
    final string = await _crypto?.de(param, key) ?? '';
    if (_crypto?.hasError ?? false) {
      getError(_crypto?.getError());
    }
    return string;
  }

  /// Returns a String value from Firebase Remote Config.
  String getString(String key) => _remoteConfig?.getString(key) ?? '';

  /// Returns an integer value from Firebase Remote Config.
  int getInt(String key) => _remoteConfig?.getInt(key) ?? 0;

  /// Returns an double value from Firebase Remote Config.
  double getDouble(String key) => _remoteConfig?.getDouble(key) ?? 0.0;

  /// Returns an boolean value from Firebase Remote Config.
  bool getBool(String key) => _remoteConfig?.getBool(key) ?? false;

  /// Returns an 'Remote Config' value from Firebase Remote Config.
  r.RemoteConfigValue getValue(String key) =>
      _remoteConfig?.getValue(key) ??
      r.RemoteConfigValue(null, r.ValueSource.valueStatic);

  /// Returns all the 'Remote Config' values from Firebase Remote Config.
  Map<String, r.RemoteConfigValue> getAll() => _remoteConfig?.getAll() ?? {};

  /// Makes the last fetched config available to getters.
  ///
  /// Returns a [bool] that is true if the config parameters
  /// were activated. Returns a [bool] that is false if the
  /// config parameters were already activated.
  Future<bool> activate() async {
    final bool configChanged = await _remoteConfig?.activate() ?? false;
    if (configChanged) {
      // Only if not activated yet.
      notifyListeners();
    }
    return configChanged;
  }

  /// Ensures the last activated config are available to getters.
  Future<bool> ensureInitialized() async {
    final ensure = _remoteConfig != null;
    if (ensure) {
      await _remoteConfig?.ensureInitialized();
    }
    return ensure;
  }

  /// Fetches and caches configuration from the Remote Config service.
  Future<bool> fetch() async {
    final fetch = _remoteConfig != null;
    if (fetch) {
      // Only if it's instantiated.
      await _remoteConfig?.fetch();
      // Always notify listeners after an explicit fetch
      notifyListeners();
    }
    return fetch;
  }

  /// Performs a fetch and activate operation, as a convenience.
  ///
  /// Returns [bool] in the same way that is done for [activate].
  /// A FirebaseException maybe thrown with the following error code:
  /// - **forbidden**:
  ///  - Thrown if the Google Cloud Platform Firebase Remote Config API is disabled
  Future<bool> fetchAndActivate({bool? throwError}) async {
    // Rethrow and errors
    final throwIt = throwError ?? false;
    bool configChanged;
    try {
      configChanged = _remoteConfig != null;
      if (configChanged) {
        configChanged = await _remoteConfig!.fetchAndActivate();
        // Notify listeners of a fetch.
        notifyListeners();
      }
    } catch (e) {
      if (throwIt) {
        rethrow;
      } else {
        configChanged = false;
        getError(e);
      }
    }
    // Either an error or _remoteConfig == null
    return configChanged;
  }

  /// Add a listener to trigger when a Firebase Remote Config value is changed.
  @override
  void addListener(VoidCallback listener) => super.addListener(listener);

  /// Remove a specified listener
  @override
  void removeListener(VoidCallback listener) => super.removeListener(listener);

  /// Indicates if an error has occurred or not.
  @Deprecated("Use 'hadError' property instead.")
  bool get hasError => _error != null;

  /// Indicates if an error has occurred or not.
  @Deprecated("Use 'hadError' property instead.")
  bool get inError => _error != null;

  /// Indicates if an error has occurred or not.
  bool get hadError => _error != null;
  Object? _error;

  /// Returns the last error that may occurred. Records an error as well.
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
    if (ex == null && error != null) {
      ex = error as Exception;
    }
    return ex;
  }
}
