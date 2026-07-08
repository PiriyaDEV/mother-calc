import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidtang_flutter/providers/locale_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';

class HomeEmptyState extends StatelessWidget {
  final bool isDark;
  const HomeEmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: isDark ? null : const [AppShadows.card],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.accentIce,
                    shape: BoxShape.circle,
                  ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.t('home_no_bills'),
                style: GoogleFonts.sarabun(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.neutral900Dark
                      : AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.t('home_empty_sub'),
                style: GoogleFonts.sarabun(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.neutral600Dark
                      : AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/bills'),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Center(
                           child: Text(
                             l.t('bills_create'),
                            style: GoogleFonts.sarabun(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/groups'),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Center(
                           child: Text(
                             l.t('home_create_group'),
                            style: GoogleFonts.sarabun(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.neutral900Dark
                                  : AppColors.neutral900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
