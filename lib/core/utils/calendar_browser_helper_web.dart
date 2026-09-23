import 'dart:convert';
import 'dart:js_interop';

@JS('window.open')
external JSObject? _windowOpen(JSString url, JSString target);

@JS('document.createElement')
external _JSAnchorElement _createElement(JSString tagName);

@JS('document.body.appendChild')
external void _appendChild(_JSAnchorElement element);

@JS('document.body.removeChild')
external void _removeChild(_JSAnchorElement element);

extension type _JSAnchorElement._(JSObject _) implements JSObject {
  external set href(JSString value);
  external set download(JSString value);
  external set target(JSString value);
  external void click();
}

/// Opens [url] in a new browser tab (`_blank`).
bool openUrlInBrowser(String url) {
  try {
    _windowOpen(url.toJS, '_blank'.toJS);
    return true;
  } catch (_) {
    return false;
  }
}

/// Triggers an immediate browser download of [content] as [filename] (`.ics`).
bool downloadTextFileInBrowser({
  required String filename,
  required String content,
  String mimeType = 'text/calendar;charset=utf-8',
}) {
  try {
    final base64Content = base64Encode(utf8.encode(content));
    final dataUri = 'data:$mimeType;base64,$base64Content';
    final anchor = _createElement('a'.toJS);
    anchor.href = dataUri.toJS;
    anchor.download = filename.toJS;
    anchor.target = '_blank'.toJS;
    _appendChild(anchor);
    anchor.click();
    _removeChild(anchor);
    return true;
  } catch (_) {
    return false;
  }
}
