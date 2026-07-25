import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import 'preview_canvas.dart';
import 'preview_theme.dart';

/// CSS 입력과 미리보기 캔버스를 묶은 오른쪽 패널.
///
/// CSS 를 붙여넣으면 캔버스가 즉시 그 테마로 다시 그려진다. 파싱에 실패하면
/// 앱을 죽이지 않고 마지막으로 성공한 테마를 유지한 채 무엇이 문제인지 알린다.
class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.cssController,
    required this.onCssChanged,
    required this.themes,
    required this.error,
    required this.brightness,
    required this.onBrightnessChanged,
  });

  static const cssFieldKey = Key('preview.field.css');

  final TextEditingController cssController;
  final ValueChanged<String> onCssChanged;

  /// 파싱에 성공한 테마. 아직 아무것도 붙여넣지 않았으면 null 이고,
  /// 그때는 템플릿이 지금 쓰는 테마를 보여준다.
  final PreviewTheme? themes;

  /// 마지막 파싱 실패 메시지.
  final String? error;

  final Brightness brightness;
  final ValueChanged<Brightness> onBrightnessChanged;

  bool get _isDark => brightness == Brightness.dark;

  ThemeData get _activeTheme {
    if (themes == null) {
      return _isDark ? TweakcnTheme.dark : TweakcnTheme.light;
    }
    return _isDark ? themes!.dark : themes!.light;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '미리보기',
              style: TextStyle(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            SegmentedButton<Brightness>(
              segments: const [
                ButtonSegment(value: Brightness.light, label: Text('라이트')),
                ButtonSegment(value: Brightness.dark, label: Text('다크')),
              ],
              selected: {brightness},
              onSelectionChanged: (s) => onBrightnessChanged(s.first),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: cssFieldKey,
          controller: cssController,
          onChanged: onCssChanged,
          minLines: 4,
          maxLines: 6,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            labelText: 'tweakcn CSS',
            hintText: 'tweakcn 에서 복사한 :root { --background: ... } 를 붙여넣으세요',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(color: colors.destructive, fontSize: 12),
          ),
        ],
        if (themes == null && error == null) ...[
          const SizedBox(height: 8),
          Text(
            '아직 붙여넣지 않았습니다. 지금은 템플릿의 기본 테마입니다.',
            style: TextStyle(color: colors.mutedForeground, fontSize: 12),
          ),
        ],
        // 미리보기가 생성 결과와 갈릴 수 있는 지점은 숨기지 않고 말해준다.
        if (themes != null && themes!.missingTokens.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '색 토큰 ${themes!.missingTokens.length}개가 CSS 에 없어 투명하게 그려집니다 '
            '(${themes!.missingTokens.take(3).join(', ')}'
            '${themes!.missingTokens.length > 3 ? ' 외' : ''}). '
            '생성된 앱도 똑같이 나옵니다.',
            style: TextStyle(color: colors.mutedForeground, fontSize: 12),
          ),
        ],
        if (themes?.unsupportedFont != null) ...[
          const SizedBox(height: 8),
          Text(
            '폰트 "${themes!.unsupportedFont}" 는 미리보기에 반영되지 않습니다. '
            '생성된 앱에는 적용됩니다.',
            style: TextStyle(color: colors.mutedForeground, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            // 캔버스는 375x812 로 그린다. 창이 그보다 낮아도 잘리지 않도록
            // 비율을 지킨 채 줄인다.
            child: FittedBox(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PreviewCanvas(theme: _activeTheme),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
