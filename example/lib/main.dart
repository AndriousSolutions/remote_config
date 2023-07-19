// ignore_for_file: require_trailing_commas
// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:remote_config/remote_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// High-level variable
late RemoteConfig hRemoteConfig;

///
class MyApp extends StatelessWidget {
  ///
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Remote Config Example',
        home: FutureBuilder<RemoteConfig>(
          future: _setupRemoteConfig(),
          builder: (_, AsyncSnapshot<RemoteConfig> snapshot) {
            Widget widget;
            if (snapshot.hasData) {
              widget = WelcomeWidget();
            } else {
              widget = const SizedBox();
            }
            return widget;
          },
        ),
      );
}

///
Future<RemoteConfig> _setupRemoteConfig() async {
  //
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
        authDomain: 'react-native-firebase-testing.firebaseapp.com',
        databaseURL: 'https://react-native-firebase-testing.firebaseio.com',
        projectId: 'react-native-firebase-testing',
        storageBucket: 'react-native-firebase-testing.appspot.com',
        messagingSenderId: '448618578101',
        appId: '1:448618578101:web:772d484dc9eb15e9ac3efc',
        measurementId: 'G-0N1G9FLDZE'),
  );

  hRemoteConfig = RemoteConfig(fetchTimeout: 10, minimumFetchInterval: 1);
  // FirebasehRemoteConfig.instance;

  // Essential to call initAsync()
  await hRemoteConfig.initAsync();

  // This does the same thing as above in the constructor.
  await hRemoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));

  await hRemoteConfig.setDefaults(<String, dynamic>{
    'welcome': 'default welcome',
    'hello': 'default hello',
  });
  return hRemoteConfig;
}

///
class WelcomeWidget extends AnimatedWidget {
  ///
  WelcomeWidget({
    super.key,
  }) : super(listenable: hRemoteConfig);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Remote Config Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(hRemoteConfig.getString('welcome')),
              const SizedBox(
                height: 20,
              ),
              const Text('Same value from the RemoteConfigValue:'),
              Text(hRemoteConfig.getValue('welcome').asString()),
              const Text('Indicates at which source this value came from:'),
              Text('${hRemoteConfig.getValue('welcome').source}'),
              const SizedBox(
                height: 20,
              ),
              const Text('Time of last successful fetch:'),
              Text('${hRemoteConfig.lastFetchTime}'),
              const Text('Status of the last fetch attempt:'),
              Text('${hRemoteConfig.lastFetchStatus}'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Using zero duration to force fetching from remote server.
            await hRemoteConfig.setConfigSettings(RemoteConfigSettings(
              fetchTimeout: const Duration(seconds: 10),
              minimumFetchInterval: Duration.zero,
            ));

            try {
              await hRemoteConfig.fetchAndActivate(throwError: true);
            } on PlatformException catch (exception) {
              // Fetch exception.
              if (kDebugMode) {
                print(exception);
              }
            } catch (exception) {
              if (kDebugMode) {
                print(
                    'Unable to fetch remote config. Cached or default values will be '
                    'used');
                print(exception);
              }
            }
          },
          child: const Icon(Icons.refresh),
        ),
      );
}
