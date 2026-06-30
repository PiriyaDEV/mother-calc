import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _displayNameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _promptpayCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _displayNameCtrl = TextEditingController(text: profile?.displayName ?? '');
    _usernameCtrl = TextEditingController(text: profile?.username ?? '');
    _promptpayCtrl = TextEditingController(text: profile?.promptpay ?? '');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _promptpayCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        displayName: _displayNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        promptpay: _promptpayCtrl.text.trim().isEmpty ? null : _promptpayCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกสำเร็จ', style: GoogleFonts.notoSansThai()),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด', style: GoogleFonts.notoSansThai()),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('แก้ไขโปรไฟล์', style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(
              'บันทึก',
              style: GoogleFonts.notoSansThai(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                MemberAvatar(
                  name: profile?.displayName ?? profile?.username ?? '?',
                  color: AppColors.primary,
                  size: 80,
                  avatarUrl: profile?.avatarUrl,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.bgDark : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Form fields
          _FormLabel(label: 'ชื่อที่แสดง'),
          const SizedBox(height: 6),
          TextField(
            controller: _displayNameCtrl,
            decoration: const InputDecoration(hintText: 'ชื่อที่แสดงในแอป'),
          ),
          const SizedBox(height: AppSpacing.lg),

          _FormLabel(label: 'ชื่อผู้ใช้'),
          const SizedBox(height: 6),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(hintText: 'username'),
          ),
          const SizedBox(height: AppSpacing.lg),

          _FormLabel(label: 'เบอร์ PromptPay'),
          const SizedBox(height: 6),
          TextField(
            controller: _promptpayCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'เบอร์โทรหรือเลขบัตรประชาชน'),
          ),
          const SizedBox(height: AppSpacing.lg),

          _FormLabel(label: 'อีเมล'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Text(
              auth.user?.email ?? '',
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'บันทึกการเปลี่ยนแปลง',
                    style: GoogleFonts.notoSansThai(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.notoSansThai(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }
}
