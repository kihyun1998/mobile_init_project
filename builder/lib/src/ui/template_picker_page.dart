import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import '../template/template_locator.dart';

/// 템플릿을 못 찾았을 때 뜨는 화면.
///
/// 여기까지 왔다는 건 기본 위치에도 없고 저장된 것도 못 쓴다는 뜻이다.
/// 물어보는 것 말고 할 수 있는 게 없다.
///
/// 고른 폴더를 확인하고 기억하는 일은 하지 않는다. 그 흐름은 폴더를 도중에
/// 바꾸는 경우와 똑같아서, 두 벌로 두면 한쪽만 고치는 날이 온다.
class TemplatePickerPage extends StatelessWidget {
  const TemplatePickerPage({
    super.key,
    required this.onBrowse,
    this.problem,
  });

  static const browseKey = Key('template.browse');

  final VoidCallback onBrowse;

  /// 방금 고른 폴더를 쓸 수 없었던 이유. 없으면 null.
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'template 폴더를 알려주세요',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: colors.foreground),
                ),
                const SizedBox(height: 8),
                Text(
                  '뿌릴 템플릿을 옆에서 찾지 못했습니다. '
                  '한 번만 알려주면 다음부터는 묻지 않습니다.',
                  style: TextStyle(color: colors.mutedForeground),
                ),
                const SizedBox(height: 20),
                Text(
                  '이 폴더에 ${TemplateLocator.requiredEntries.join(', ')} 이(가) '
                  '있어야 합니다.',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: TemplatePickerPage.browseKey,
                  onPressed: onBrowse,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('폴더 고르기'),
                ),
                if (problem != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.destructive.withValues(alpha: 0.12),
                      border: Border.all(color: colors.destructive),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      problem!,
                      style: TextStyle(color: colors.destructive),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
