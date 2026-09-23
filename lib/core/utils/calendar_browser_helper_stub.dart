/// Stub implementation for non-web platforms and widget tests.
bool openUrlInBrowser(String url) {
  return false;
}

bool downloadTextFileInBrowser({
  required String filename,
  required String content,
  String mimeType = 'text/calendar;charset=utf-8',
}) {
  return false;
}
