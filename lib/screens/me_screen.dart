import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/me/index.dart';

// ── Helpers ────────────────────────────────────────────────────
bool _isValidUsername(String u) =>
    RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(u);

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  bool _editingName = false;
  bool _editingUsername = false;
  bool _editingPassword = false;
  bool _editingPromptpay = false;

  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _promptpayCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;
  String? _success;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<AuthProvider>().profile;
      if (profile != null) _syncFromProfile(profile);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _promptpayCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  void _syncFromProfile(Profile profile) {
    _nameCtrl.text = profile.displayName ?? '';
    _usernameCtrl.text = profile.username ?? '';
    _promptpayCtrl.text = profile.promptpay ?? '';
  }

  void _showSuccess(String msg) {
    _successTimer?.cancel();
    setState(() {
      _success = msg;
      _error = null;
    });
    _successTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _success = null);
    });
  }

  void _showError(String msg) {
    setState(() {
      _error = msg;
      _success = null;
    });
  }

  // ── Save Name ──────────────────────────────────────────────
  Future<void> _handleSaveName() async {
    final val = _nameCtrl.text.trim();
    if (val.isEmpty) return;
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await auth.updateProfile(displayName: val);
      if (!mounted) return;
      setState(() => _editingName = false);
      _showSuccess('บันทึกชื่อเรียบร้อย');
    } catch (e) {
      if (!mounted) return;
      _showError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Save Username ──────────────────────────────────────────
  Future<void> _handleSaveUsername() async {
    final val = _usernameCtrl.text.trim().toLowerCase();
    if (!_isValidUsername(val)) {
      _showError(
          'username ต้องเป็นตัวอักษรภาษาอังกฤษ ตัวเลข หรือ _ (3-30 ตัว)');
      return;
    }
    final auth = context.read<AuthProvider>();
    if (val != auth.profile?.username) {
      setState(() => _saving = true);
      final taken = await auth.isUsernameTaken(val);
      if (!mounted) return;
      if (taken) {
        setState(() => _saving = false);
        _showError('username นี้ถูกใช้งานแล้ว');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await auth.updateProfile(username: val);
      if (!mounted) return;
      setState(() => _editingUsername = false);
      _showSuccess('บันทึก username เรียบร้อย');
    } catch (e) {
      if (!mounted) return;
      _showError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Save Promptpay ─────────────────────────────────────────
  Future<void> _handleSavePromptpay() async {
    final val = _promptpayCtrl.text.trim();
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await auth.updateProfile(promptpay: val.isEmpty ? null : val);
      if (!mounted) return;
      setState(() => _editingPromptpay = false);
      _showSuccess('บันทึกพร้อมเพย์เรียบร้อย');
    } catch (e) {
      if (!mounted) return;
      _showError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Save Password ──────────────────────────────────────────
  Future<void> _handleSavePassword() async {
    final np = _newPassCtrl.text;
    final cp = _confirmPassCtrl.text;
    if (np.length < 6) {
      _showError('รหัสผ่านต้องมีอย่างน้อย 6 ตัว');
      return;
    }
    if (np != cp) {
      _showError('รหัสผ่านไม่ตรงกัน');
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    final err = await auth.updatePassword(np);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      _showError(err);
    } else {
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      setState(() => _editingPassword = false);
      _showSuccess('เปลี่ยนรหัสผ่านเรียบร้อย');
    }
  }

  // ── Upload Avatar ──────────────────────────────────────────
  Future<void> _handlePickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 80);
    if (picked == null || !mounted) return;
    final auth = context.read<AuthProvider>();
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await auth.updateProfile(avatarUrl: base64Str);
      if (!mounted) return;
      _showSuccess('อัปโหลดรูปโปรไฟล์เรียบร้อย');
    } catch (e) {
      if (!mounted) return;
      _showError('อัปโหลดรูปไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────
  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ออกจากระบบ',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w600)),
        content: Text('ต้องการออกจากระบบหรือไม่?',
            style: GoogleFonts.notoSansThai()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('ยกเลิก',
                style: GoogleFonts.notoSansThai(
                    color: AppColors.textSecondaryLight)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('ออกจากระบบ',
                style: GoogleFonts.notoSansThai(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    if (mounted) context.go('/login');
  }

  // ── Language Picker ────────────────────────────────────────
  void _showLanguagePicker() {
    final locale = context.read<LocaleProvider>();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => LanguageDialog(
        currentLocale: locale.locale,
        onSelect: (lang) {
          locale.setLocale(lang);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // context.select — each selector only triggers a rebuild when its specific
    // slice of state changes, not on every notifyListeners() from any provider.
    final profile = context.select<AuthProvider, Profile?>((a) => a.profile);
    final auth = context.read<AuthProvider>();

    // Detect Google user
    final providers = auth.user?.appMetadata['providers'] as List?;
    final isGoogleUser =
        providers != null && providers.contains('google');

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: ProfileHeader(
                isDark: isDark,
                profile: profile,
                uploading: _uploadingAvatar,
                onPickAvatar: _handlePickAvatar,
                onDismissError: () => setState(() => _error = null),
                successMessage: _success,
                errorMessage: _error,
              ),
            ),
          ],
          body: _buildBody(context, isDark, profile, auth, isGoogleUser),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Profile? profile,
    AuthProvider auth,
    bool isGoogleUser,
  ) {
    final themeProvider = context.read<ThemeProvider>();
    final locale = context.read<LocaleProvider>();
    final notifUnread =
        context.select<NotificationsProvider, int>((p) => p.unreadCount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        AccountSection(
          isDark: isDark,
          profile: profile,
          editingName: _editingName,
          nameCtrl: _nameCtrl,
          saving: _saving,
          onEditName: () => setState(() {
            _editingName = true;
            _editingUsername = false;
            _editingPromptpay = false;
          }),
          onSaveName: _handleSaveName,
          onCancelName: () => setState(() {
            _editingName = false;
            _nameCtrl.text = profile?.displayName ?? '';
          }),
          editingUsername: _editingUsername,
          usernameCtrl: _usernameCtrl,
          onEditUsername: () => setState(() {
            _editingUsername = true;
            _editingName = false;
            _editingPromptpay = false;
          }),
          onSaveUsername: _handleSaveUsername,
          onCancelUsername: () => setState(() {
            _editingUsername = false;
            _usernameCtrl.text = profile?.username ?? '';
          }),
          editingPromptpay: _editingPromptpay,
          promptpayCtrl: _promptpayCtrl,
          onEditPromptpay: () => setState(() {
            _editingPromptpay = true;
            _editingName = false;
            _editingUsername = false;
          }),
          onSavePromptpay: _handleSavePromptpay,
          onCancelPromptpay: () => setState(() {
            _editingPromptpay = false;
            _promptpayCtrl.text = profile?.promptpay ?? '';
          }),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (!isGoogleUser) ...[
          SecuritySection(
            isDark: isDark,
            editingPassword: _editingPassword,
            saving: _saving,
            newPassCtrl: _newPassCtrl,
            confirmPassCtrl: _confirmPassCtrl,
            onToggleEdit: () =>
                setState(() => _editingPassword = !_editingPassword),
            onSave: _handleSavePassword,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        SettingsSection(
          isDark: isDark,
          isThai: locale.isThai,
          notifUnread: notifUnread,
          onToggleDark: () => themeProvider.toggle(),
          onLanguageTap: _showLanguagePicker,
          onNotificationsTap: () => context.push('/notifications'),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Sign Out ───────────────────────────────────────
        GestureDetector(
          onTap: _handleSignOut,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.redFaint,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: isDark
                    ? AppColors.red.withValues(alpha: 0.3)
                    : AppColors.red.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded,
                    size: 18, color: AppColors.red),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'ออกจากระบบ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

