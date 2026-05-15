import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SetupGuideOpener {
  static const _channel = MethodChannel('sleewave/link_opener');

  Future<void> open(String url) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final opened = await _channel.invokeMethod<bool>('openUrl', url);
        if (opened == true) {
          return;
        }
      } catch (_) {}
    }
    await Clipboard.setData(ClipboardData(text: url));
  }
}
