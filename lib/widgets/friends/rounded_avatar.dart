import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class RoundedAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final double radius;

  const RoundedAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.radius,
    this.avatarUrl,
  });

  String get _initial {
    final t = name.trim();
    return t.isNotEmpty ? t[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:')) {
        try {
          final bytes = base64Decode(avatarUrl!.split(',').last);
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitials(),
            ),
          );
        } catch (_) {
          return _buildInitials();
        }
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => _buildInitials(),
          errorWidget: (ctx, url, err) => _buildInitials(),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
