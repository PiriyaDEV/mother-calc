import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/stores/friends_store.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// Self-contained add-friend panel.
/// Owns its own text-field state so keystrokes only rebuild this widget,
/// not the entire FriendsScreen.
class AddFriendPanel extends StatefulWidget {
  final bool isDark;
  final FriendsStore store;
  final VoidCallback onClose;

  const AddFriendPanel({
    super.key,
    required this.isDark,
    required this.store,
    required this.onClose,
  });

  @override
  State<AddFriendPanel> createState() => _AddFriendPanelState();
}

class _AddFriendPanelState extends State<AddFriendPanel> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String _error = '';
  String _success = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final username = _ctrl.text.trim().replaceAll('@', '');
    if (username.isEmpty) return;
    setState(() {
      _loading = true;
      _error = '';
      _success = '';
    });
    final profile = await widget.store.searchByUsername(username);
    if (!mounted) return;
    if (profile == null) {
      setState(() {
        _loading = false;
        _error = 'ไม่พบผู้ใช้ @$username';
      });
      return;
    }
    final err = await widget.store.sendFriendRequest(profile.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (err != null) {
        _error = err;
      } else {
        _success = 'ส่งคำขอเป็นเพื่อนไปยัง @$username แล้ว!';
        _ctrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final isDark = widget.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.neutral100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.t('friends_add_new'),
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.neutral400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: GoogleFonts.notoSansThai(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '@username',
                          hintStyle: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            color: AppColors.neutral400,
                          ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(36, 10, 12, 10),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceDark
                              : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                            borderSide: const BorderSide(
                                color: Color(0xFF286BFE)),
                          ),
                        ),
                        onChanged: (v) {
                          // strip @ prefix automatically
                          if (v.startsWith('@')) {
                            _ctrl.value = TextEditingValue(
                              text: v.substring(1),
                              selection: TextSelection.collapsed(
                                  offset: v.length - 1),
                            );
                          }
                          setState(() {});
                        },
                        onSubmitted: (_) => _handleSend(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(Icons.search_rounded,
                            size: 16, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: _loading || _ctrl.text.trim().isEmpty
                      ? null
                      : _handleSend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: 10),
                    decoration: BoxDecoration(
                      color: _ctrl.text.trim().isEmpty
                          ? AppColors.neutral400
                          : AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            l.t('friends_send'),
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(
                  _error,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
            if (_success.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _success,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
