import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_init_project/core/localization/generated/l10n.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/example/shadcn_components_page.dart';
import 'package:mobile_init_project/main.dart';
import 'package:mobile_init_project/ui/components/shadcn_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 예제 페이지의 Login 블록을 본다.
///
/// 이 블록은 새 컴포넌트가 아니라 기존 컴포넌트 조합이라 순수 로직이 없다. 그래서
/// 확인할 것은 "조합이 실제로 그려지는가" 와 "색이 테마에서 오는가" 두 가지다 —
/// 후자를 안 보면 하드코딩된 색이 들어가도 초록으로 통과한다.
Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          theme: TweakcnTheme.light,
          home: const ShadcnComponentsPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
  });

  testWidgets('Login 블록이 shadcn login-01 구성을 그대로 담는다', (tester) async {
    await _pump(tester);

    // shadcn login-01 의 자리들. 하나라도 빠지면 원본과 갈린 것이다.
    expect(find.text('Login to your account'), findsOneWidget);
    expect(
      find.text('Enter your email below to login to your account'),
      findsOneWidget,
    );
    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Login with Google'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('원본에 없는 "로그인 유지" 체크박스를 넣지 않는다', (tester) async {
    await _pump(tester);

    // shadcn 의 login-01~05 전부 체크박스가 없다 (실측: checkbox=0, remember=0).
    // 이 티켓 본문이 원래 체크박스를 요구했다가 반증돼서 빠진 자리라, 다시
    // 들어오는 것을 막아둔다.
    expect(find.text('Remember me'), findsNothing);
    expect(find.text('로그인 유지'), findsNothing);
  });

  testWidgets('블록의 색이 테마에서 온다', (tester) async {
    await _pump(tester);

    expect(
      _textColor(tester, 'Forgot your password?'),
      TweakcnColors.light.mutedForeground,
    );
    expect(
      _textColor(tester, "Don't have an account?"),
      TweakcnColors.light.mutedForeground,
    );
    expect(_textColor(tester, 'Sign up'), TweakcnColors.light.foreground);

    // 하드코딩된 색이 들어와도 위가 우연히 맞을 수 있으니, 서로 다른 토큰을
    // 쓰는 두 자리가 실제로 다른 값인 것도 본다.
    expect(
      TweakcnColors.light.mutedForeground,
      isNot(TweakcnColors.light.foreground),
    );
  });

  testWidgets('ko 로 바꾸면 한국어가 나온다', (tester) async {
    await _pump(tester, locale: const Locale('ko'));

    expect(find.text('계정에 로그인'), findsOneWidget);
    expect(find.text('비밀번호를 잊으셨나요?'), findsOneWidget);
    expect(find.text('계정이 없나요?'), findsOneWidget);
    expect(find.text('Login to your account'), findsNothing);
  });

  testWidgets('페이지 어디에서도 오버플로가 나지 않는다', (tester) async {
    // 실측으로 잡은 회귀다. 이 블록을 처음 넣었을 때 2건이 났다 —
    // 비밀번호 라벨 줄이 62px, "계정이 없나요? 가입" 줄이 50px 넘쳤다.
    // 블록을 빼면 0건이었으므로 기존 카드들의 문제가 아니라 이 블록의 것이었다.
    // 앞줄은 Flexible + ellipsis, 뒷줄은 Wrap 으로 고쳤다.
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) =>
        errors.add(details.exception.toString());

    await _pump(tester);

    FlutterError.onError = previous;
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  testWidgets('제출 버튼과 outline 버튼이 둘 다 있다', (tester) async {
    await _pump(tester);

    final login = tester.widget<ShadcnButton>(
      find.ancestor(
        of: find.text('Login'),
        matching: find.byType(ShadcnButton),
      ),
    );
    final google = tester.widget<ShadcnButton>(
      find.ancestor(
        of: find.text('Login with Google'),
        matching: find.byType(ShadcnButton),
      ),
    );

    expect(login.variant, ShadcnButtonVariant.defaultStyle);
    expect(google.variant, ShadcnButtonVariant.outline);
  });
}
