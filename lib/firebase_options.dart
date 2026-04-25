import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDsWAS3upIg1P9jxA1_uHfGFKn6oWTUxU',
    appId: '1:195706072392:web:d73b9ddf0244e252ce977d',
    messagingSenderId: '195706072392',
    projectId: 'smartchain-project',
    authDomain: 'smartchain-project.firebaseapp.com',
    databaseURL: 'https://smartchain-project-default-rtdb.firebaseio.com',
    storageBucket: 'smartchain-project.firebasestorage.app',
  );
}
