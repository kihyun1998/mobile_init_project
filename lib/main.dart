import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/const/enum_hive_key.dart';
import 'core/theme/provider/theme_provider.dart';
import 'example/shadcn_components_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();
  await Hive.openBox<String>(HiveKey.boxSettings.key);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  void printDeviceInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    print('화면 크기: ${size.width} x ${size.height}');
    print('픽셀 밀도: ${pixelRatio}x');
    print('실제 픽셀: ${size.width * pixelRatio} x ${size.height * pixelRatio}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    printDeviceInfo(context);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X 기준 크기
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Mobile Init Project',
          debugShowCheckedModeBanner: false,
          theme: ref.theme.themeData,
          home: const ShadcnComponentsPage(),
        );
      },
    );
  }
}
