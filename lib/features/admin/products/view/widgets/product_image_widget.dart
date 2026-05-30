import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hamsa_store_demo/core/theme/app_colors.dart';

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: AppColors.surface,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}
