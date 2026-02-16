import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/generated/l10n.dart';
import 'core/localization/provider/locale_state_provider.dart';
import 'core/theme/foundation/app_mode.dart';
import 'core/theme/provider/theme_provider.dart';
import 'core/theme/tweakcn_theme.g.dart';
import 'core/util/logger/app_logger.dart';
import 'example/shadcn_components_page.dart';

/// main()에서 초기화된 SharedPreferences 인스턴스
/// Provider의 동기 build()에서 접근 가능하도록 전역 캐싱
late final SharedPreferences sharedPrefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences 초기화 및 캐싱
  sharedPrefs = await SharedPreferences.getInstance();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  void printDeviceInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    logger.d('화면 크기: ${size.width} x ${size.height}');
    logger.d('픽셀 밀도: ${pixelRatio}x');
    logger.d('실제 픽셀: ${size.width * pixelRatio} x ${size.height * pixelRatio}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    printDeviceInfo(context);

    final mode = ref.watch(themeProvider);
    final locale = ref.watch(localeStateProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X 기준 크기
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Mobile Init Project',
          debugShowCheckedModeBanner: false,
          theme: TweakcnTheme.light,
          darkTheme: TweakcnTheme.dark,
          themeMode: mode == AppMode.light ? ThemeMode.light : ThemeMode.dark,
          locale: locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const ShadcnComponentsPage(),
        );
      },
    );
  }
}
