import 'package:flutter/material.dart';

class WebImagePlatformHelper {
  static Widget build({
    required String imageUrl,
    required double? width,
    required double? height,
    required double borderRadius,
    required BoxFit fit,
    required Widget placeholder,
  }) {
    throw UnsupportedError('Cannot create web image on this platform');
  }
}
