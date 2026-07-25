import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_init_project/core/localization/generated/l10n.dart';
import 'package:mobile_init_project/example/shadcn_components_page.dart';

/// 붙여넣은 테마로 **진짜 템플릿 컴포넌트**를 그리는 미리보기 화면.
///
/// 기본 자식은 템플릿의 예제 페이지다. 사본이 아니라 `template/` 의 그 파일을
/// 그대로 컴파일해 쓴다 — 사본을 두는 순간 미리보기가 생성 결과와 어긋나기
/// 시작하고, 그러면 이 도구를 만든 이유가 없어진다.
///
/// 폰 크기로 가둬야 하는 이유가 있다. 템플릿 컴포넌트는 전부 `.w/.h/.sp` 를
/// 쓰는데 ScreenUtil 은 가로와 세로 배율을 따로 계산한다. 데스크톱 창 크기로
/// 두면 가로는 3배 넘게 늘고 세로는 그대로여서 실제 기기에서 나지 않는 모양이
/// 나온다. 그래서 빌더 앱 루트가 아니라 **이 위젯 안에서만** ScreenUtil 을
/// 초기화한다.
class PreviewCanvas extends StatelessWidget {
  const PreviewCanvas({super.key, required this.theme, this.child});

  /// [PreviewTheme] 이 만든 라이트 또는 다크 테마.
  final ThemeData theme;

  /// 캔버스에 띄울 것. 비우면 템플릿 예제 페이지.
  final Widget? child;

  /// 기준 디자인 크기. 템플릿의 `ScreenUtilInit` 과 같아야 한다.
  static const phoneSize = Size(375, 812);

  static const _phoneMediaQuery = MediaQueryData(
    size: phoneSize,
    devicePixelRatio: 1,
  );

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit 을 쓰지 않는다. 그 위젯은 View.maybeOf(context) 로 **실제
    // 창**을 읽어서 상속된 MediaQuery 를 무시하기 때문에, 데스크톱 창 기준으로
    // 배율이 잡혀 가로가 3배 넘게 부푼다. configure 는 MediaQueryData 를 직접
    // 받으므로 폰 크기를 강제할 수 있다.
    // 세 값을 모두 넘겨야 한다. 생략하면 configure 가 아직 초기화되지 않은
    // late 필드를 읽어서 LateInitializationError 로 죽는다.
    ScreenUtil.configure(
      data: _phoneMediaQuery,
      designSize: phoneSize,
      minTextAdapt: true,
      splitScreenMode: false,
    );

    return SizedBox(
      width: phoneSize.width,
      height: phoneSize.height,
      child: MediaQuery(
        data: _phoneMediaQuery,
        child: ProviderScope(
          // 예제 페이지가 ConsumerWidget 이라 스코프가 필요하다.
          // 빌더 루트를 riverpod 으로 물들이지 않도록 여기서만 연다.
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: child ?? const ShadcnComponentsPage(),
          ),
        ),
      ),
    );
  }
}
