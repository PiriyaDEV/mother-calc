import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../utils/bill_utils.dart';

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
      avatar = CachedNetworkImage(
        imageUrl: avatarUrl!,
        imageBuilder: (ctx, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (ctx, url) => _buildInitials(fontSize),
        errorWidget: (ctx, url, err) => _buildInitials(fontSize),
      );
    } else {
      avatar = _buildInitials(fontSize);
    }

    if (showBorder) {
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: avatar,
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
            color: Colors.white,
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
      height: size,
      width: visible.length * (size * 0.7) + size * 0.3 + (extra > 0 ? size * 0.7 : 0),
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
                  color: const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B7280),
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
