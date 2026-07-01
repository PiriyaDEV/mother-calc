// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Renders a Google AdSense banner on Flutter Web using HtmlElementView.
/// Each instance gets a unique view-type so multiple banners can coexist.
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
        ..style.overflow = 'hidden';

      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..style.width = '100%'
        ..style.height = '90px'
        ..setAttribute('data-ad-client', publisherId)
        ..setAttribute('data-ad-slot', adSlot)
        ..setAttribute('data-ad-format', 'horizontal')
        ..setAttribute('data-full-width-responsive', 'true');

      container.append(ins);

      // Push the ad unit after the element is attached to the DOM
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          final adsbygoogle = js.context['adsbygoogle'];
          if (adsbygoogle != null) {
            (adsbygoogle as js.JsArray).callMethod('push', [js.JsObject.jsify({})]);
          }
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
