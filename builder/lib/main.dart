import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';
import 'package:mobile_init_project/ui/components/shadcn_button.dart';
import 'package:mobile_init_project/ui/components/shadcn_card.dart';

/// 아직 껍데기다. 지금은 template/ 의 진짜 컴포넌트가 빌더 안에서
/// 컴파일되고 렌더되는지만 확인한다 — 미리보기 전체가 이 전제 위에 서 있다.
void main() => runApp(const BuilderApp());

class BuilderApp extends StatelessWidget {
  const BuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: 'Mobile Init Builder',
        debugShowCheckedModeBanner: false,
        theme: TweakcnTheme.light,
        darkTheme: TweakcnTheme.dark,
        home: const _SmokeTestPage(),
      ),
    );
  }
}

class _SmokeTestPage extends StatelessWidget {
  const _SmokeTestPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SizedBox(
          width: 320.w,
          child: ShadcnCard(
            title: 'template/ 컴포넌트가 빌더에서 렌더됨',
            description: '미리보기는 사본이 아니라 이 파일 그대로를 그린다.',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadcnButton(onPressed: () {}, child: const Text('Primary')),
                SizedBox(height: 8.h),
                ShadcnButton(
                  onPressed: () {},
                  variant: ShadcnButtonVariant.outline,
                  child: const Text('Outline'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
