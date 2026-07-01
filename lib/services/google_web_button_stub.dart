import 'package:flutter/widgets.dart';

/// No-op stub used on non-web platforms — the rendered Google button only
/// ever gets built behind a `kIsWeb` check, so this is never reached there.
Widget renderGoogleSignInButton() => const SizedBox.shrink();
