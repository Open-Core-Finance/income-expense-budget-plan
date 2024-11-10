// // File generated by FlutterFire CLI.
// // ignore_for_file: type=lint
// import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
// import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
//
// /// Default [FirebaseOptions] for use with your Firebase apps.
// ///
// /// Example:
// /// ```dart
// /// import 'firebase_options.dart';
// /// // ...
// /// await Firebase.initializeApp(
// ///   options: DefaultFirebaseOptions.currentPlatform,
// /// );
// /// ```
// class DefaultFirebaseOptions {
//   static FirebaseOptions get currentPlatform {
//     if (kIsWeb) {
//       return web;
//     }
//     switch (defaultTargetPlatform) {
//       case TargetPlatform.android:
//         return android;
//       case TargetPlatform.iOS:
//         return ios;
//       case TargetPlatform.macOS:
//         return macos;
//       case TargetPlatform.windows:
//         return windows;
//       case TargetPlatform.linux:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions have not been configured for linux - '
//           'you can reconfigure this by running the FlutterFire CLI again.',
//         );
//       default:
//         throw UnsupportedError(
//           'DefaultFirebaseOptions are not supported for this platform.',
//         );
//     }
//   }
//
//   static const FirebaseOptions web = FirebaseOptions(
//     apiKey: 'AIzaSyDF58ZFJOzMjV1fwO85g_hA7CAvHAzsHnA',
//     appId: '1:696243667812:web:f97cb8618f18821629b071',
//     messagingSenderId: '696243667812',
//     projectId: 'income-expense-budget-plan',
//     authDomain: 'income-expense-budget-plan.firebaseapp.com',
//     storageBucket: 'income-expense-budget-plan.firebasestorage.app',
//     measurementId: 'G-HTS2JW6XBK',
//   );
//
//   static const FirebaseOptions android = FirebaseOptions(
//     apiKey: 'AIzaSyAA3L6u0muFAvvn1GLQEjQzxyGeWc0O2q4',
//     appId: '1:696243667812:android:68ded307f734127f29b071',
//     messagingSenderId: '696243667812',
//     projectId: 'income-expense-budget-plan',
//     storageBucket: 'income-expense-budget-plan.firebasestorage.app',
//   );
//
//   static const FirebaseOptions ios = FirebaseOptions(
//     apiKey: 'AIzaSyAh40_xUHp05u4VpLBaCsEZ_ksTB2hJNv8',
//     appId: '1:696243667812:ios:b5b43df708ccb60729b071',
//     messagingSenderId: '696243667812',
//     projectId: 'income-expense-budget-plan',
//     storageBucket: 'income-expense-budget-plan.firebasestorage.app',
//     iosBundleId: 'com.dbaotrung.incomeExpenseBudgetPlan',
//   );
//
//   static const FirebaseOptions macos = FirebaseOptions(
//     apiKey: 'AIzaSyAh40_xUHp05u4VpLBaCsEZ_ksTB2hJNv8',
//     appId: '1:696243667812:ios:b5b43df708ccb60729b071',
//     messagingSenderId: '696243667812',
//     projectId: 'income-expense-budget-plan',
//     storageBucket: 'income-expense-budget-plan.firebasestorage.app',
//     iosBundleId: 'com.dbaotrung.incomeExpenseBudgetPlan',
//   );
//
//   static const FirebaseOptions windows = FirebaseOptions(
//     apiKey: 'AIzaSyDF58ZFJOzMjV1fwO85g_hA7CAvHAzsHnA',
//     appId: '1:696243667812:web:ae36f190afa6556929b071',
//     messagingSenderId: '696243667812',
//     projectId: 'income-expense-budget-plan',
//     authDomain: 'income-expense-budget-plan.firebaseapp.com',
//     storageBucket: 'income-expense-budget-plan.firebasestorage.app',
//     measurementId: 'G-K8VEMCY19V',
//   );
// }
