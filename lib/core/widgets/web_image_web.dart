// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;

class WebImagePlatformHelper {
  static final Set<String> _registeredViewTypes = {};

  static Widget build({
    required String imageUrl,
    required double? width,
    required double? height,
    required double borderRadius,
    required BoxFit fit,
    required Widget placeholder,
  }) {
    final viewType = 'img-${Object.hash(imageUrl, fit, borderRadius)}';

    if (_registeredViewTypes.add(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final container = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'none';
        final img = html.ImageElement()
          ..src = imageUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'none'
          ..style.objectFit = fit == BoxFit.contain ? 'contain' : 'cover'
          ..style.borderRadius = '${borderRadius}px';
        container.append(img);
        return container;
      });
    }

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(
        viewType: viewType,
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      ),
    );
  }
}
