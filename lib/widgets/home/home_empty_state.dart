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
            color: isDark
                ? AppColors.surfaceDark
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF2D5BFF).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.accentIceDark
                      : AppColors.accentIce,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
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
                style: GoogleFonts.anuphan(
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
                style: GoogleFonts.notoSansThai(
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
                          gradient: AppGradients.primaryButtonLight,
                          borderRadius:
                              BorderRadius.circular(AppRadii.full),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                           child: Text(
                             l.t('bills_create'),
                            style: GoogleFonts.notoSansThai(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadii.full),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.neutral100,
                          ),
                        ),
                        child: Center(
                           child: Text(
                             l.t('home_create_group'),
                            style: GoogleFonts.notoSansThai(
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
