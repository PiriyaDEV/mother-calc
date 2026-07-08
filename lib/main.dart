import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'package:kidtang_flutter/screens/shared/line_web_return_screen.dart';
import 'services/app_config_service.dart';
import 'services/push_notification_service.dart';
import 'providers/theme_provider.dart';
import 'stores/bills_store.dart';
import 'stores/friends_store.dart';
import 'stores/groups_store.dart';
import 'providers/notifications_provider.dart';
import 'providers/locale_provider.dart';
import 'theme/app_theme.dart';
import 'router.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // On web, .env is never loaded — secrets are baked in via --dart-define at
  // build time (Netlify) or passed via --dart-define in run.sh (local web dev).
  // Loading .env as a Flutter asset on web would expose secrets publicly at
  // /assets/.env, so we skip it entirely for kIsWeb.
  //
  // On mobile/desktop, load .env from the filesystem for local development.
  // On CI/CD the file won't exist — silently skip.
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // File not found — no-op.
    }
  }

  // Helper: prefer dotenv value (mobile/desktop only), fall back to
  // --dart-define compile-time constant (always used on web).
  // NOTE: String.fromEnvironment MUST be called with a literal string — not a variable.
  String env(String key, String compiledValue) => (!kIsWeb && dotenv.env[key]?.isNotEmpty == true) ? dotenv.env[key]! : compiledValue;

  // Initialize Thai locale data for DateFormat
  await initializeDateFormatting('th', null);

  final supabaseUrl = env('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL'));
  final supabaseKey = env('SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY'));
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    debugPrint('[Supabase] Missing SUPABASE_URL or SUPABASE_ANON_KEY — check env vars');
    // Show error app instead of crashing
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Initialize AdMob SDK (mobile only — no web implementation) + fetch remote ads toggle
  try {
    if (!kIsWeb) await MobileAds.instance.initialize();
    await AppConfigService.load();
  } catch (e) {
    debugPrint('[AdMob] Init error: $e');
  }

  // Initialize Firebase only when properly configured.
  // Placeholder values (REPLACE_WITH_*) cause a native fatalError on iOS
  // that Dart try-catch cannot intercept, so we guard before calling in.
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (!options.projectId.startsWith('REPLACE_')) {
      await Firebase.initializeApp(options: options);
      await PushNotificationService.initialize();
    } else {
      debugPrint('[Firebase] Placeholder config — skipping init. Run: flutterfire configure');
    }
  } catch (e) {
    debugPrint('[Firebase] Not configured yet: $e');
  }

  // Initialize LINE SDK (mobile only — no web implementation)
  if (!kIsWeb) {
    await LineSDK.instance.setup(
      env('LINE_CHANNEL_ID', const String.fromEnvironment('LINE_CHANNEL_ID')),
    );
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BillsStore()),
        ChangeNotifierProvider(create: (_) => FriendsStore()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => GroupsStore()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const KidtangApp(),
    ),
  );
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Configuration error: SUPABASE_URL or SUPABASE_ANON_KEY is missing.\n\n'
              'Please set the required environment variables.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class KidtangApp extends StatefulWidget {
  const KidtangApp({super.key});

  @override
  State<KidtangApp> createState() => _KidtangAppState();
}

class _KidtangAppState extends State<KidtangApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    // Wire sibling providers so profile data flows into locale + stats.
    authProvider.setSiblingProviders(
      localeProvider: context.read<LocaleProvider>(),
      groupsStore: context.read<GroupsStore>(),
      billsStore: context.read<BillsStore>(),
      friendsStore: context.read<FriendsStore>(),
    );
    _router = AppRouter.router(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Narrow selects — only rebuild when the specific field changes.
    final isDark = context.select<ThemeProvider, bool>((t) => t.isDark);
    final needsLineReturn = context.select<AuthProvider, bool>(
      (a) => a.lineWebLoginNeedsReturnToApp,
    );

    return MaterialApp.router(
      title: 'Kidtang! - มาจ่ายเงินกัน',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            // A LINE web login that lands in a plain Safari tab (instead of
            // the installed PWA) finishes here — override the router's
            // child entirely and tell the user to switch back to the app
            // rather than showing the normal app UI in this throwaway tab.
            child: needsLineReturn
                ? const LineWebReturnScreen()
                : child!,
          ),
        );
      },
    );
  }
}
