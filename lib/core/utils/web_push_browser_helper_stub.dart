Future<String> requestBrowserNotificationPermission() async => 'unsupported';

String getBrowserNotificationPermission() => 'unsupported';

bool isServiceWorkerReady() => false;

bool showBrowserNotification({
  required String title,
  required String body,
  String? tag,
  String? url,
}) =>
    false;
