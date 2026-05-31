import 'package:flutter/material.dart';
import 'web_image_stub.dart' if (dart.library.html) 'web_image_web.dart';

Widget buildWebImage({
  required String imageUrl,
  required double? width,
  required double? height,
  required double borderRadius,
  required BoxFit fit,
  required Widget placeholder,
}) {
  return WebImagePlatformHelper.build(
    imageUrl: imageUrl,
    width: width,
    height: height,
    borderRadius: borderRadius,
    fit: fit,
    placeholder: placeholder,
  );
}
