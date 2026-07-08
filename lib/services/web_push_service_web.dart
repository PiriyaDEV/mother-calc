// Web implementation — subscribes to Web Push API (VAPID) and saves the
// PushSubscription JSON to Supabase profiles.vapid_subscription.
//
// The heavy lifting (SW registration, permission request, subscribe) is done
// by a small JS helper (`window._kidtangPush`) injected in web/index.html so
// we avoid complex dart:js_interop gymnastics.
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── JS bindings for the helper injected in index.html ────────────────────────

@JS('window._kidtangPush.subscribe')
external JSPromise<JSString?> _jsSubscribe(JSString vapidKey);

@JS('window._kidtangPush.unsubscribe')
external JSPromise<JSBoolean> _jsUnsubscribe();

// ── VAPID key ────────────────────────────────────────────────────────────────

/// VAPID public key — injected at build time via --dart-define=VAPID_PUBLIC_KEY=...
/// or set VAPID_PUBLIC_KEY in .env for local dev.
const _vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

// ── Public API ───────────────────────────────────────────────────────────────

/// Requests notification permission, subscribes to Web Push (VAPID), and
/// saves the PushSubscription JSON to Supabase profiles.vapid_subscription.
/// Safe to call multiple times — reuses existing subscription if present.
Future<void> subscribeWebPush() async {
  if (_vapidPublicKey.isEmpty) {
    debugPrint('[WebPush] VAPID_PUBLIC_KEY not set — skipping');
    return;
  }
  try {
    final subJsonJs = await _jsSubscribe(_vapidPublicKey.toJS).toDart;
    final subJson = subJsonJs?.toDart;
    if (subJson == null) {
      debugPrint('[WebPush] Subscribe returned null (permission denied or unsupported)');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'vapid_subscription': subJson})
        .eq('id', user.id);

    debugPrint('[WebPush] Subscription saved');
  } catch (e) {
    debugPrint('[WebPush] subscribeWebPush error: $e');
  }
}

/// Unsubscribes from Web Push and clears the subscription from Supabase.
Future<void> unsubscribeWebPush() async {
  try {
    await _jsUnsubscribe().toDart;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'vapid_subscription': null})
          .eq('id', user.id);
    }
    debugPrint('[WebPush] Unsubscribed');
  } catch (e) {
    debugPrint('[WebPush] unsubscribeWebPush error: $e');
  }
}
