import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/section_header.dart';

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
      builder: (ctx) => _LanguageDialog(
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
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final profile = auth.profile;

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
              child: _buildHeader(
                  context, isDark, profile, locale, themeProvider),
            ),
          ],
          body: _buildProfileTab(context, isDark, profile, auth, isGoogleUser),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Profile? profile,
    LocaleProvider locale,
    ThemeProvider themeProvider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // Toast messages
          if (_success != null) ...[
            _ToastBanner(
                message: _success!, isError: false, isDark: isDark),
            const SizedBox(height: 8),
          ],
          if (_error != null) ...[
            _ToastBanner(
              message: _error!,
              isError: true,
              isDark: isDark,
              onDismiss: () => setState(() => _error = null),
            ),
            const SizedBox(height: 8),
          ],

          // ── Hero Card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppGradients.primaryButtonDark
                  : AppGradients.primaryButtonLight,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppColors.shadowFloat,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: AppColors.shadowFloat,
                          ),
                          child: _buildAvatar(profile, 72),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: GestureDetector(
                            onTap: _uploadingAvatar
                                ? null
                                : _handlePickAvatar,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppColors.shadowSubtle,
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 13,
                                color: _uploadingAvatar
                                    ? AppColors.neutral400
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Name & username
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.displayName ??
                                profile?.username ??
                                'ผู้ใช้',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (profile?.username != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '@${profile!.username}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                color: Colors.white
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Profile Tab ────────────────────────────────────────────
  Widget _buildProfileTab(
    BuildContext context,
    bool isDark,
    Profile? profile,
    AuthProvider auth,
    bool isGoogleUser,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final notifUnread = context.watch<NotificationsProvider>().unreadCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Section: บัญชี ─────────────────────────────────
        const SectionHeaderWidget(label: 'บัญชี'),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              _ProfileFieldRow(
                isDark: isDark,
                label: 'ชื่อที่แสดง',
                value: profile?.displayName ?? '',
                isEditing: _editingName,
                controller: _nameCtrl,
                saving: _saving,
                onEdit: () => setState(() {
                  _editingName = true;
                  _editingUsername = false;
                  _editingPromptpay = false;
                }),
                onSave: _handleSaveName,
                onCancel: () => setState(() {
                  _editingName = false;
                  _nameCtrl.text = profile?.displayName ?? '';
                }),
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              _ProfileFieldRow(
                isDark: isDark,
                label: 'Username',
                value: '@${profile?.username ?? ''}',
                isEditing: _editingUsername,
                controller: _usernameCtrl,
                saving: _saving,
                prefix: '@',
                inputFormatters: [_LowercaseFormatter()],
                onEdit: () => setState(() {
                  _editingUsername = true;
                  _editingName = false;
                  _editingPromptpay = false;
                }),
                onSave: _handleSaveUsername,
                onCancel: () => setState(() {
                  _editingUsername = false;
                  _usernameCtrl.text = profile?.username ?? '';
                }),
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              _ProfileFieldRow(
                isDark: isDark,
                label: 'พร้อมเพย์ (ใช้เป็น default ในบิล)',
                value: profile?.promptpay != null &&
                        profile!.promptpay!.isNotEmpty
                    ? '📱 ${profile.promptpay}'
                    : 'ยังไม่ได้ตั้งค่า',
                valueColor: profile?.promptpay == null ||
                        profile!.promptpay!.isEmpty
                    ? AppColors.textTertiaryLight
                    : null,
                isEditing: _editingPromptpay,
                controller: _promptpayCtrl,
                saving: _saving,
                hintText: 'เบอร์โทร หรือ เลขบัตรประชาชน',
                onEdit: () => setState(() {
                  _editingPromptpay = true;
                  _editingName = false;
                  _editingUsername = false;
                }),
                onSave: _handleSavePromptpay,
                onCancel: () => setState(() {
                  _editingPromptpay = false;
                  _promptpayCtrl.text = profile?.promptpay ?? '';
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Section: ความปลอดภัย ──────────────────────────
        if (!isGoogleUser) ...[
          const SectionHeaderWidget(label: 'ความปลอดภัย'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'เปลี่ยนรหัสผ่าน',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                            () => _editingPassword = !_editingPassword),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            borderRadius:
                                BorderRadius.circular(AppRadii.md),
                          ),
                          child: Icon(
                            _editingPassword
                                ? Icons.close_rounded
                                : Icons.edit_outlined,
                            size: 15,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_editingPassword) ...[
                  Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _PasswordField(
                          controller: _newPassCtrl,
                          hint: 'รหัสผ่านใหม่',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _PasswordField(
                          controller: _confirmPassCtrl,
                          hint: 'ยืนยันรหัสผ่านใหม่',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _saving ? null : _handleSavePassword,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: _saving
                                  ? AppColors.textTertiaryLight
                                  : AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.md),
                            ),
                            child: Center(
                              child: Text(
                                _saving ? 'กำลังบันทึก...' : 'บันทึก',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
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
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Section: การตั้งค่า ────────────────────────────
        const SectionHeaderWidget(label: 'การตั้งค่า'),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              // Dark mode toggle
              _SettingsTile(
                isDark: isDark,
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                iconColor: isDark
                    ? const Color(0xFF7C83FD)
                    : const Color(0xFFFFB23E),
                label: 'โหมดสีเข้ม',
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => themeProvider.toggle(),
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primaryFaint,
                  inactiveThumbColor: AppColors.neutral400,
                  inactiveTrackColor: AppColors.neutral100,
                ),
                onTap: () => themeProvider.toggle(),
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              // Language
              _SettingsTile(
                isDark: isDark,
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF34C77B),
                label: 'ภาษา',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    locale.isThai ? '🇹🇭 ไทย' : '🇬🇧 EN',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                onTap: _showLanguagePicker,
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
              // Notifications
              _SettingsTile(
                isDark: isDark,
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFFF5C5C),
                label: 'การแจ้งเตือน',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (notifUnread > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          notifUnread > 99 ? '99+' : '$notifUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ],
                ),
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
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

  // ── Avatar Builder ─────────────────────────────────────────
  Widget _buildAvatar(Profile? profile, double size) {
    final avatarUrl = profile?.avatarUrl;
    final name = profile?.displayName ?? profile?.username ?? '?';
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    Widget inner;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('data:')) {
        // base64 data URI (freshly picked photo, not yet a real URL) —
        // CachedNetworkImage can't handle these.
        try {
          final bytes = base64Decode(avatarUrl.split(',').last);
          inner = ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _buildInitialAvatar(initial, size),
            ),
          );
        } catch (_) {
          inner = _buildInitialAvatar(initial, size);
        }
      } else {
        inner = ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => _buildInitialAvatar(initial, size),
            errorWidget: (ctx, url, err) =>
                _buildInitialAvatar(initial, size),
          ),
        );
      }
    } else {
      inner = _buildInitialAvatar(initial, size);
    }

    if (_uploadingAvatar) {
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

  Widget _buildInitialAvatar(String initial, double size) {
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

// ── Toast Banner ───────────────────────────────────────────────
class _ToastBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final bool isDark;
  final VoidCallback? onDismiss;

  const _ToastBanner({
    required this.message,
    required this.isError,
    required this.isDark,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isError
        ? (isDark
            ? AppColors.red.withValues(alpha: 0.15)
            : AppColors.redFaint)
        : (isDark
            ? AppColors.emeraldDark.withValues(alpha: 0.15)
            : AppColors.greenFaint);
    final border = isError
        ? AppColors.red.withValues(alpha: 0.3)
        : AppColors.emerald.withValues(alpha: 0.3);
    final textColor = isError
        ? AppColors.red
        : (isDark ? AppColors.emerald : AppColors.emeraldText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: GoogleFonts.notoSansThai(
                    fontSize: 13, color: textColor)),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 14, color: textColor),
            ),
        ],
      ),
    );
  }
}

// ── Settings Tile ──────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ── Language Dialog ────────────────────────────────────────────
class _LanguageDialog extends StatelessWidget {
  final String currentLocale;
  final ValueChanged<String> onSelect;

  const _LanguageDialog(
      {required this.currentLocale, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'เลือกภาษา / Select Language',
              style: GoogleFonts.notoSansThai(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            _LangOption(
              flag: '🇹🇭',
              name: 'ภาษาไทย',
              subtitle: 'Thai',
              selected: currentLocale == 'th',
              isDark: isDark,
              onTap: () => onSelect('th'),
            ),
            const SizedBox(height: 8),
            _LangOption(
              flag: '🇬🇧',
              name: 'English',
              subtitle: 'อังกฤษ',
              selected: currentLocale == 'en',
              isDark: isDark,
              onTap: () => onSelect('en'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String name;
  final String subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.bgDark : AppColors.bgLight),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Profile Field Row ──────────────────────────────────────────
class _ProfileFieldRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isEditing;
  final TextEditingController controller;
  final bool saving;
  final String? prefix;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ProfileFieldRow({
    required this.isDark,
    required this.label,
    required this.value,
    required this.isEditing,
    required this.controller,
    required this.saving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    this.valueColor,
    this.prefix,
    this.hintText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: ThemeColors.textTertiary(isDark),
                  ),
                ),
              ),
              if (!isEditing)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: ThemeColors.textTertiary(isDark),
                    ),
                  ),
                )
              else ...[
                GestureDetector(
                  onTap: saving ? null : onSave,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: saving
                          ? AppColors.textTertiaryLight
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: saving
                        ? const Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: ThemeColors.textTertiary(isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (!isEditing)
            Text(
              value,
              style: GoogleFonts.notoSansThai(
                fontSize: 14,
                color: valueColor ?? ThemeColors.textPrimary(isDark),
              ),
            )
          else
            Row(
              children: [
                if (prefix != null)
                  Text(
                    prefix!,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      color: ThemeColors.textTertiary(isDark),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    inputFormatters: inputFormatters,
                    style: GoogleFonts.notoSansThai(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: GoogleFonts.notoSansThai(
                        fontSize: 14,
                        color: AppColors.textTertiaryLight,
                      ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 6),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: ThemeColors.border(isDark),
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => onSave(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Password Field ─────────────────────────────────────────────
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.isDark,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: GoogleFonts.notoSansThai(fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.notoSansThai(
          fontSize: 14,
          color: AppColors.textTertiaryLight,
        ),
        filled: true,
        fillColor:
            widget.isDark ? AppColors.borderDark : AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: widget.isDark
                ? AppColors.borderDark
                : AppColors.neutral100,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: widget.isDark
                ? AppColors.borderDark
                : AppColors.neutral100,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: AppColors.textTertiaryLight,
          ),
        ),
      ),
    );
  }
}

// ── Lowercase Formatter ────────────────────────────────────────
class _LowercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
