import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/app_config_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  static String _adUnitId() {
    if (kDebugMode) {
      // Google-provided test IDs — safe to use during development
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? dotenv.env['ADMOB_BANNER_ANDROID'] ?? ''
        : dotenv.env['ADMOB_BANNER_IOS'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    if (!AppConfigService.adsEnabled) return;
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
    if (!AppConfigService.adsEnabled || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: _ad!.size.height.toDouble(),
      width: double.infinity,
      child: AdWidget(ad: _ad!),
    );
  }
}
