import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final Profile? profile;
  final double size;
  final bool uploading;
  final VoidCallback? onPickAvatar;

  const ProfileAvatar({
    super.key,
    required this.profile,
    required this.size,
    this.uploading = false,
    this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 3),
            boxShadow: AppColors.shadowFloat,
          ),
          child: _avatar(),
        ),
        if (onPickAvatar != null)
          Positioned(
            bottom: -2,
            right: -2,
            child: GestureDetector(
              onTap: uploading ? null : onPickAvatar,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.shadowSubtle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 13,
                  color: uploading ? AppColors.neutral400 : AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatar() {
    final avatarUrl = profile?.avatarUrl;
    final name = profile?.displayName ?? profile?.username ?? '?';
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    Widget inner;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:')) {
        try {
          final bytes = base64Decode(avatarUrl.split(',').last);
          inner = ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initial(initial),
            ),
          );
        } catch (_) {
          inner = _initial(initial);
        }
      } else {
        inner = ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => _initial(initial),
            errorWidget: (ctx, url, err) => _initial(initial),
          ),
        );
      }
    } else {
      inner = _initial(initial);
    }

    if (uploading) {
      return Stack(
        children: [
          inner,
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return inner;
  }

  Widget _initial(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.person_outline_rounded,
            size: size * 0.4, color: Colors.white),
      ),
    );
  }
}
