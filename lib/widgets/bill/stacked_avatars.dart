import 'package:flutter/material.dart';
import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/utils/bill_utils.dart';
import 'package:kidtang_flutter/widgets/shared/member_avatar.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class StackedAvatars extends StatelessWidget {
  final List<BillMember> members;

  const StackedAvatars({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    const maxShow = 3;
    final shown = members.take(maxShow).toList();
    final extra = members.length - shown.length;
    final totalWidth = shown.isEmpty
        ? 0.0
        : 24.0 + (shown.length - 1) * 16.0 + (extra > 0 ? 20.0 : 0.0);

    if (shown.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: totalWidth,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...shown.asMap().entries.map((e) => Positioned(
                left: e.key * 16.0,
                child: MemberAvatar(
                  name: e.value.name,
                  color: colorFromHex(e.value.color),
                  size: 24,
                  avatarUrl: e.value.profile?.avatarUrl,
                  showBorder: true,
                ),
              )),
          if (extra > 0)
            Positioned(
              left: shown.length * 16.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.neutral400,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.surface,
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
