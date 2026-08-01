import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:js_util' as js_util;

Future<Map<String, dynamic>?> triggerGoogleSignInWeb() async {
  if (!kIsWeb) return null;
  final completer = Completer<Map<String, dynamic>?>();

  try {
    js_util.callMethod(js_util.globalThis, 'triggerGoogleSignInWeb', [
      js_util.allowInterop((String resultJson) {
        try {
          final data = jsonDecode(resultJson) as Map<String, dynamic>;
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      })
    ]);
  } catch (e) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }

  return completer.future;
}
