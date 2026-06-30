import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';

// ── Helpers ────────────────────────────────────────────────────
bool _isValidUsername(String u) =>
    RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(u);

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
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
    final picked =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 256, maxHeight: 256, imageQuality: 80);
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
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final profile = auth.profile;

    // Detect Google user
    final providers = auth.user?.appMetadata['providers'] as List?;
    final isGoogleUser = providers != null && providers.contains('google');

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF4F6FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'สวัสดี!, คุณ ${profile?.displayName ?? profile?.username ?? ''}',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                // Theme toggle
                GestureDetector(
                  onTap: () => themeProvider.toggle(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_round_outlined,
                      size: 18,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Toast ────────────────────────────────────────
            if (_success != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.emeraldDark.withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
                  border: Border.all(color: isDark ? AppColors.emeraldDark : const Color(0xFFBBF7D0)),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: isDark ? AppColors.emerald : const Color(0xFF15803D)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _success!,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: isDark ? AppColors.emerald : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.red.withValues(alpha: 0.15) : AppColors.redFaint,
                  border: Border.all(color: isDark ? AppColors.red.withValues(alpha: 0.4) : const Color(0xFFFECACA)),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 16, color: isDark ? AppColors.red : const Color(0xFFDC2626)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: isDark ? AppColors.red : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: isDark ? AppColors.red : const Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Profile Hero Card ────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4366F4), Color(0xFF6B8AF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.shadowFloat,
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: AppColors.shadowFloat,
                        ),
                        child: _buildAvatar(profile, 80),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: _uploadingAvatar ? null : _handlePickAvatar,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: _uploadingAvatar
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: AppColors.shadowSubtle,
                            ),
                            child: Icon(Icons.camera_alt_outlined,
                                size: 13,
                                color: _uploadingAvatar
                                    ? const Color(0xFF9CA3AF)
                                    : AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile?.displayName ?? profile?.username ?? 'ผู้ใช้',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  if (profile?.username != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '@${profile!.username}',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Section: บัญชี ───────────────────────────────
            SectionHeaderWidget(label: 'บัญชี'),
            const SizedBox(height: 10),

            // ── Profile Fields Card ──────────────────────────
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
              ),
              child: Column(
                children: [
                  // ── ชื่อที่แสดง ──
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
                        : AppColors.borderLight,
                  ),
                  // ── Username ──
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
                        : AppColors.borderLight,
                  ),
                  // ── พร้อมเพย์ ──
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

            // ── Section: ความปลอดภัย ─────────────────────────
            if (!isGoogleUser) ...[
              SectionHeaderWidget(label: 'ความปลอดภัย'),
              const SizedBox(height: 10),
            ],

            // ── Change Password Card (non-Google only) ───────
            if (!isGoogleUser)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
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
                                borderRadius: BorderRadius.circular(AppRadii.md),
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
                            : AppColors.borderLight,
                      ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: _saving
                                      ? AppColors.textTertiaryLight
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(AppRadii.md),
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

            // ── Section: การตั้งค่า ──────────────────────────
            SectionHeaderWidget(label: 'การตั้งค่า'),
            const SizedBox(height: 10),

            // Theme toggle card
            GestureDetector(
              onTap: () => themeProvider.toggle(),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: isDark ? null : AppColors.shadowSubtle,
                ),
                child: Row(
                  children: [
                    Text(isDark ? '🌙' : '☀️', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'โหมดสีเข้ม',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    Switch(
                      value: isDark,
                      onChanged: (_) => themeProvider.toggle(),
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primaryFaint,
                      inactiveThumbColor: const Color(0xFF9CA3AF),
                      inactiveTrackColor: const Color(0xFFE5E7EB),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Sign Out ─────────────────────────────────────
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
                        : const Color(0xFFFEE2E2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 18, color: AppColors.red),
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
        ),
      ),
    );
  }

  Widget _buildAvatar(Profile? profile, double size) {
    final avatarUrl = profile?.avatarUrl;
    final name = profile?.displayName ?? profile?.username ?? '?';
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    Widget inner;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(initial, size),
        ),
      );
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
              borderRadius: BorderRadius.circular(16),
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
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Center(
        child: Icon(Icons.person_outline_rounded,
            size: size * 0.4, color: Colors.white),
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
                // ✓ Save
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
                // ✗ Cancel
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
        fillColor: widget.isDark
            ? AppColors.borderDark
            : const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: widget.isDark
                ? AppColors.borderDark
                : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: widget.isDark
                ? AppColors.borderDark
                : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: AppColors.textTertiaryLight,
          ),
        ),
      ),
    );
  }
}

// ── Lowercase TextInputFormatter ───────────────────────────────
class _LowercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
