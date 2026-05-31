// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
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
    final viewType = 'img-${imageUrl.hashCode}';
    
    // Register factory if not already done
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = fit == BoxFit.contain ? 'contain' : 'cover'
        ..style.borderRadius = '${borderRadius}px';
      return img;
    });

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
