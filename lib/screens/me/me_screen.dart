import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:kidtang_flutter/models/models.dart';
import 'package:kidtang_flutter/providers/auth_provider.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/providers/theme_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:kidtang_flutter/widgets/shared/banner_ad_widget.dart';
import 'package:kidtang_flutter/widgets/shared/confirm_dialog.dart';
import 'package:kidtang_flutter/widgets/shared/skeleton_loader.dart';
import 'package:kidtang_flutter/widgets/me/index.dart';

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
      final l = context.read<LocaleProvider>();
    final val = _nameCtrl.text.trim();
    if (val.isEmpty) return;
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await auth.updateProfile(displayName: val);
      if (!mounted) return;
      setState(() => _editingName = false);
      _showSuccess(l.t('me_save_name_success'));
    } catch (e) {
      if (!mounted) return;
      _showError(l.t('me_error_generic'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Save Username ──────────────────────────────────────────
  Future<void> _handleSaveUsername() async {
    final l = context.read<LocaleProvider>();
    final val = _usernameCtrl.text.trim().toLowerCase();
    if (!_isValidUsername(val)) {
      _showError(l.t('me_username_invalid'));
      return;
    }
    final auth = context.read<AuthProvider>();
    if (val != auth.profile?.username) {
      setState(() => _saving = true);
      final taken = await auth.isUsernameTaken(val);
      if (!mounted) return;
      if (taken) {
        setState(() => _saving = false);
        _showError(l.t('me_username_taken'));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await auth.updateProfile(username: val);
      if (!mounted) return;
      setState(() => _editingUsername = false);
      _showSuccess(l.t('me_save_username_success'));
    } catch (e) {
      if (!mounted) return;
      _showError(l.t('me_error_generic'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Save Promptpay ─────────────────────────────────────────
  Future<void> _handleSavePromptpay() async {
      final l = context.read<LocaleProvider>();
    final val = _promptpayCtrl.text.trim();
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await auth.updateProfile(promptpay: val.isEmpty ? null : val);
      if (!mounted) return;
      setState(() => _editingPromptpay = false);
      _showSuccess(l.t('me_save_promptpay_success'));
    } catch (e) {
      if (!mounted) return;
      _showError(l.t('me_error_generic'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Save Password ──────────────────────────────────────────
  Future<void> _handleSavePassword() async {
      final l = context.read<LocaleProvider>();
    final np = _newPassCtrl.text;
    final cp = _confirmPassCtrl.text;
    if (np.length < 6) {
      _showError(l.t('me_password_min_length'));
      return;
    }
    if (np != cp) {
      _showError(l.t('me_password_mismatch'));
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
      _showSuccess(l.t('me_change_password_success'));
    }
  }

  // ── Upload Avatar ──────────────────────────────────────────
  Future<void> _handlePickAvatar() async {
      final l = context.read<LocaleProvider>();
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
      _showSuccess(l.t('me_upload_avatar_success'));
    } catch (e) {
      if (!mounted) return;
      _showError(l.t('me_upload_avatar_fail'));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────
  Future<void> _handleSignOut() async {
    final l = context.read<LocaleProvider>();
    final confirmed = await showConfirmDialog(
      context,
      title: l.t('me_logout_title'),
      description: l.t('me_logout_confirm_msg'),
      confirmLabel: l.t('me_logout_confirm'),
      cancelLabel: l.t('me_logout_cancel'),
      danger: true,
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

    if (profile == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: BannerAdWidget(),
        body: SafeArea(child: MeScreenSkeleton()),
      );
    }

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
    final themeProvider = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final l = locale;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
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
          onToggleDark: () => themeProvider.toggle(),
          onLanguageTap: _showLanguagePicker,
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Sign Out ───────────────────────────────────────
        Semantics(
          label: l.t('me_logout_btn'),
          button: true,
          child: _SignOutButton(
            isDark: isDark,
            label: l.t('me_logout_btn'),
            onTap: _handleSignOut,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

// ── Animated sign-out button ───────────────────────────────────────────────────

class _SignOutButton extends StatefulWidget {
  const _SignOutButton({
    required this.isDark,
    required this.label,
    required this.onTap,
  });
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressScaleButton : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.standard,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : AppColors.redFaint,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.red.withValues(alpha: 0.3)
                  : AppColors.red.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, size: 18, color: AppColors.red),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

