import 'dart:js_interop';

@JS('window.edusyncWebPush.getPermission')
external JSString _getPermission();

@JS('window.edusyncWebPush.isSwReady')
external JSBoolean _isSwReady();

@JS('window.edusyncWebPush.requestPermission')
external JSPromise<JSString> _requestPermission();

@JS('window.edusyncWebPush.showNotification')
external JSBoolean _showNotification(
  JSString title,
  JSString body,
  JSString tag,
  JSString url,
);

String getBrowserNotificationPermission() {
  try {
    return _getPermission().toDart;
  } catch (_) {
    return 'default';
  }
}

bool isServiceWorkerReady() {
  try {
    return _isSwReady().toDart;
  } catch (_) {
    return false;
  }
}

Future<String> requestBrowserNotificationPermission() async {
  try {
    final result = await _requestPermission().toDart;
    return result.toDart;
  } catch (_) {
    return getBrowserNotificationPermission();
  }
}

bool showBrowserNotification({
  required String title,
  required String body,
  String? tag,
  String? url,
}) {
  try {
    return _showNotification(
      title.toJS,
      body.toJS,
      (tag ?? 'edusync-${DateTime.now().millisecondsSinceEpoch}').toJS,
      (url ?? '/pulpit').toJS,
    ).toDart;
  } catch (_) {
    return false;
  }
}
