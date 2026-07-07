import 'package:flutter/widgets.dart';

typedef GoogleCredentialCallback = void Function(String idToken, String rawNonce);

/// No-op stub used on non-web platforms — the rendered Google button only
/// ever gets built behind a `kIsWeb` check, so this is never reached there.
Widget renderGoogleSignInButton({
  required String clientId,
  required GoogleCredentialCallback onCredential,
  double minimumWidth = 320,
}) => const SizedBox.shrink();
