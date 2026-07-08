import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class MemberAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  final String? avatarUrl;
  final bool showBorder;

  const MemberAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 40,
    this.avatarUrl,
    this.showBorder = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.38;

    Widget avatar;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:')) {
        // base64 data URI — CachedNetworkImage can't handle these
        try {
          final bytes = base64Decode(avatarUrl!.split(',').last);
          avatar = ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitials(fontSize),
            ),
          );
        } catch (_) {
          avatar = _buildInitials(fontSize);
        }
      } else {
        avatar = ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => _buildInitials(fontSize),
            errorWidget: (ctx, url, err) => _buildInitials(fontSize),
          ),
        );
      }
    } else {
      avatar = _buildInitials(fontSize);
    }

    if (showBorder) {
      // Wrap with a circle border; ClipOval ensures the image fills the full circle
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 2),
        ),
        child: ClipOval(child: avatar),
      );
    }

    return avatar;
  }

  Widget _buildInitials(double fontSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: AppColors.surface,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class MemberAvatarStack extends StatelessWidget {
  final List<({String name, Color color, String? avatarUrl})> members;
  final double size;
  final int maxVisible;

  const MemberAvatarStack({
    super.key,
    required this.members,
    this.size = 28,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    final visible = members.take(maxVisible).toList();
    final extra = members.length - maxVisible;

    return SizedBox(
      height: size + 4,
      width: visible.length * (size * 0.7) + size * 0.3 + 4.0 + (extra > 0 ? size * 0.7 : 0),
      child: Stack(
        children: [
          ...visible.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return Positioned(
              left: i * (size * 0.7),
              child: MemberAvatar(
                name: m.name,
                color: m.color,
                size: size,
                avatarUrl: m.avatarUrl,
                showBorder: true,
              ),
            );
          }),
          if (extra > 0)
            Positioned(
              left: visible.length * (size * 0.7),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
