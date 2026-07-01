import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// Renders Google Identity Services' own "Sign in with Google" button.
///
/// GIS deprecated the plain popup flow behind `GoogleSignIn().signIn()` on
/// web (it can't reliably return an idToken there) — this is the officially
/// supported way to trigger sign-in on web. Completion is picked up via
/// `GoogleSignIn().onCurrentUserChanged`, not an awaited return value — see
/// the `kIsWeb` branch in `AuthProvider._init()`.
Widget renderGoogleSignInButton() {
  return gsi_web.renderButton(
    configuration: gsi_web.GSIButtonConfiguration(
      theme: gsi_web.GSIButtonTheme.outline,
      size: gsi_web.GSIButtonSize.large,
      text: gsi_web.GSIButtonText.signinWith,
      shape: gsi_web.GSIButtonShape.pill,
      minimumWidth: 320,
    ),
  );
}
