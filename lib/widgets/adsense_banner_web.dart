// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Renders a Google AdSense banner on Flutter Web.
///
/// Flutter Web wraps HtmlElementView inside a <flt-platform-view> which is
/// placed directly in the DOM (not inside a shadow root) when using the
/// CanvasKit renderer with --web-renderer=canvaskit, or as a regular element
/// with the HTML renderer. Either way the <ins> element ends up in the real
/// DOM where adsbygoogle.js can find it.
class AdSenseBannerWeb extends StatefulWidget {
  const AdSenseBannerWeb({super.key});

  @override
  State<AdSenseBannerWeb> createState() => _AdSenseBannerWebState();
}

class _AdSenseBannerWebState extends State<AdSenseBannerWeb> {
  late final String _viewType;
  static int _counter = 0;

  @override
  void initState() {
    super.initState();
    _counter++;
    _viewType = 'adsense-banner-$_counter';

    final publisherId = dotenv.env['ADSENSE_PUBLISHER_ID'] ?? '';
    final adSlot = dotenv.env['ADSENSE_SLOT_ID'] ?? '';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '90px'
        ..style.display = 'block'
        ..style.overflow = 'visible'
        ..style.backgroundColor = 'transparent';

      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..style.width = '100%'
        ..style.height = '90px'
        ..setAttribute('data-ad-client', publisherId)
        ..setAttribute('data-ad-slot', adSlot)
        ..setAttribute('data-ad-format', 'auto')
        ..setAttribute('data-full-width-responsive', 'true');

      container.append(ins);

      // Push the ad after the element is in the DOM.
      // We use eval so the call runs in the top-level window scope where
      // adsbygoogle lives, regardless of any shadow-DOM boundary.
      Future.delayed(const Duration(milliseconds: 800), () {
        try {
          js.context.callMethod(
            'eval',
            ['(window.adsbygoogle = window.adsbygoogle || []).push({})'],
          );
        } catch (_) {}
      });

      return container;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
