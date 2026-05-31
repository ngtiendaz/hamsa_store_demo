import 'package:flutter/material.dart';
import 'package:hamsa_store_demo/core/theme/app_colors.dart';
import 'package:hamsa_store_demo/core/widgets/app_network_image.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;

  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.surface,
      child: Icon(
        Icons.shopping_bag_outlined,
        size: size * 0.5,
        color: AppColors.detail,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: placeholder,
      );
    }

    return AppNetworkImage(
      imageUrl: imageUrl!,
      width: size,
      height: size,
      borderRadius: borderRadius,
      fit: BoxFit.cover,
      placeholder: placeholder,
      errorWidget: placeholder,
    );
  }
}
