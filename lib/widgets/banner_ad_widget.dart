import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/app_config_service.dart';

// Conditional import: AdSenseBannerWeb on web, stub on mobile
import 'adsense_banner_stub.dart'
    if (dart.library.html) 'adsense_banner_web.dart';

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfigService.adsEnabled) return const SizedBox.shrink();

    // Web: use Google AdSense
    if (kIsWeb) return const AdSenseBannerWeb();

    // Mobile: use Google AdMob
    return const _MobileAdMobBanner();
  }
}

// ── Mobile AdMob banner (Android / iOS only) ──────────────────────────────────

class _MobileAdMobBanner extends StatefulWidget {
  const _MobileAdMobBanner();

  @override
  State<_MobileAdMobBanner> createState() => _MobileAdMobBannerState();
}

class _MobileAdMobBannerState extends State<_MobileAdMobBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  static String _adUnitId() {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? (dotenv.env['ADMOB_BANNER_ANDROID']?.isNotEmpty == true
            ? dotenv.env['ADMOB_BANNER_ANDROID']!
            : const String.fromEnvironment('ADMOB_BANNER_ANDROID'))
        : (dotenv.env['ADMOB_BANNER_IOS']?.isNotEmpty == true
            ? dotenv.env['ADMOB_BANNER_IOS']!
            : const String.fromEnvironment('ADMOB_BANNER_IOS'));
  }

  @override
  void initState() {
    super.initState();
    final unitId = _adUnitId();
    if (unitId.isEmpty) return;

    _ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] Banner failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      height: _ad!.size.height.toDouble(),
      width: double.infinity,
      child: AdWidget(ad: _ad!),
    );
  }
}
