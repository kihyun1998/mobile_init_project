import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import '../generation/app_language.dart';
import '../generation/file_manager.dart';
import '../generation/generation_config.dart';
import '../generation/generation_event.dart';
import '../generation/generation_exception.dart';
import '../generation/organization.dart';
import '../generation/package_name.dart';
import '../generation/process_runner.dart';
import '../generation/project_generator.dart';
import '../generation/project_platform.dart';
import '../generation/theme_css.dart';
import 'generation_log.dart';
import 'log_view.dart';

/// 이름·표시 이름·설명·org·플랫폼·언어·예제 여부·출력 폴더를 받아 새
/// 프로젝트를 만들고,
/// 진행 상황과 명령 출력을 보여주는 화면.
class GenerateFormPage extends StatefulWidget {
  const GenerateFormPage({
    super.key,
    required this.generator,
    required this.processRunner,
    this.themeCss = '',
  });

  static const nameFieldKey = Key('generate.field.name');
  static const displayNameFieldKey = Key('generate.field.displayName');
  static const descriptionFieldKey = Key('generate.field.description');
  static const organizationFieldKey = Key('generate.field.organization');
  static const outputParentFieldKey = Key('generate.field.outputParent');

  static const includeExampleKey = Key('generate.field.includeExample');

  static Key platformKey(ProjectPlatform platform) =>
      Key('generate.platform.${platform.flag}');

  static Key languageKey(AppLanguage language) =>
      Key('generate.language.${language.code}');

  final ProjectGenerator generator;

  /// 결과 폴더를 파일 관리자로 여는 데 쓴다. 생성기 것을 빌려 쓰지 않고
  /// 따로 받는다 — 이 화면이 생성기 내부를 알 이유가 없다.
  final ProcessRunner processRunner;

  /// 미리보기 칸에 지금 들어 있는 CSS **원문**. 비어 있으면 템플릿 기본 테마다.
  ///
  /// 파싱된 결과가 아니라 원문을 받는다. 미리보기는 파싱에 성공했을 때만
  /// 갱신되므로, 이 문자열이 파싱되면 그것이 곧 화면에 보이는 그 테마다.
  /// 파싱되지 않으면 값 타입이 던지고 그 문장이 오류 자리에 뜬다 — 잘못된
  /// 이름과 같은 길이다. **막는 자리를 화면에 따로 만들지 않는다.**
  final String themeCss;

  @override
  State<GenerateFormPage> createState() => _GenerateFormPageState();
}

class _GenerateFormPageState extends State<GenerateFormPage> {
  final _name = TextEditingController();
  final _displayName = TextEditingController();
  final _description = TextEditingController();
  final _organization = TextEditingController(text: 'com.example');
  final _outputParent = TextEditingController();

  /// 기본값은 설정 객체가 정한 것을 그대로 쓴다. 여기에 목록을 한 벌 더
  /// 적어두면 플랫폼이 늘어날 때 둘 중 하나만 고치게 된다.
  final _platforms = PlatformSelection.mobile.platforms.toSet();

  final _languages = LanguageSelection.all.languages.toSet();

  bool _includeExample = true;

  bool _running = false;

  /// 시작조차 못 한 경우의 오류. 프로젝트가 만들어지지 않았다는 뜻이다.
  String? _error;

  /// 만들어진 프로젝트. 후처리가 실패했어도 채워진다.
  GenerationResult? _result;

  GenerationStep? _step;
  final _log = GenerationLog();

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _description.dispose();
    _organization.dispose();
    _outputParent.dispose();
    _log.dispose();
    super.dispose();
  }

  Future<void> _pickOutputFolder() async {
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: '프로젝트를 만들 폴더',
    );
    if (picked != null) _outputParent.text = picked;
  }

  void _onEvent(GenerationEvent event) {
    if (!mounted) return;

    switch (event) {
      // 단계는 화면 상단에 뜨므로 이 위젯을 다시 그려야 한다.
      case GenerationStepStarted(:final step):
        setState(() => _step = step);
        _log.add('── ${step.label}');
      // 출력은 로그 창만 갱신하면 된다. 수천 줄이 들어오는 동안 폼 전체를
      // 다시 그리지 않도록 setState 를 부르지 않는다.
      case GenerationOutput(:final line):
        _log.add(line);
    }
  }

  Future<void> _generate() async {
    setState(() {
      _running = true;
      _error = null;
      _result = null;
      _step = null;
      _log.clear();
    });

    try {
      final result = await widget.generator.generate(
        GenerationConfig(
          // 형식이 틀리면 여기서 던진다. flutter create 는 시작도 하지 않는다.
          projectName: PackageName.parse(_name.text),
          organization: Organization.parse(_organization.text),
          platforms: PlatformSelection.of(_platforms),
          languages: LanguageSelection.of(_languages),
          includeExample: _includeExample,
          // 미리보기가 쓴 그 CSS 가 결과물의 테마 소스가 된다. 읽을 수 없으면
          // 여기서 던진다 — 잘못된 이름과 같은 길을 탄다.
          themeCss: ThemeCss.parseOrNull(widget.themeCss),
          outputParent: Directory(_outputParent.text.trim()),
          // 빈 값을 무엇으로 채울지는 설정 객체가 안다. 여기서 한 번 더
          // 정하면 둘이 어긋나는 날이 온다.
          description: _description.text,
          displayName: _displayName.text,
        ),
        onEvent: _onEvent,
      );
      if (mounted) setState(() => _result = result);
    } on GenerationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '예상하지 못한 오류입니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _step = null;
        });
      }
    }
  }

  Future<void> _openResultFolder() async {
    final result = await revealInFileManager(
      _result!.projectRoot.path,
      widget.processRunner,
    );
    // `result.succeeded` 를 직접 보면 안 된다 — Windows 의 explorer 는 성공해도
    // 1 을 돌려준다. 근거는 revealFailed 의 doc-comment.
    if (revealFailed(result, operatingSystem: Platform.operatingSystem) &&
        mounted) {
      setState(() => _error = '폴더를 열지 못했습니다.\n${result.failureOutput}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '새 프로젝트 만들기',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: colors.foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  'flutter create 로 뼈대를 만들고 그 위에 템플릿을 얹습니다.',
                  style: TextStyle(color: colors.mutedForeground),
                ),
                const SizedBox(height: 28),
                _Field(
                  fieldKey: GenerateFormPage.nameFieldKey,
                  label: '프로젝트 이름',
                  hint: 'my_app',
                  helper: '소문자로 시작하고 소문자·숫자·밑줄만 쓸 수 있습니다.',
                  controller: _name,
                  enabled: !_running,
                ),
                const SizedBox(height: 16),
                _Field(
                  fieldKey: GenerateFormPage.displayNameFieldKey,
                  label: '앱 표시 이름',
                  hint: '내 가계부',
                  // 데스크톱·웹의 표시 이름까지는 아직 손대지 않는다.
                  // 그 자리엔 프로젝트 이름이 그대로 남으므로 여기서
                  // "홈 화면 어디서나" 라고 하면 거짓말이 된다.
                  helper:
                      '앱 타이틀과 안드로이드·iOS 홈 화면 아이콘 밑에 보입니다. '
                      '비워두면 프로젝트 이름을 씁니다.',
                  controller: _displayName,
                  enabled: !_running,
                ),
                const SizedBox(height: 16),
                _Field(
                  fieldKey: GenerateFormPage.descriptionFieldKey,
                  label: '설명',
                  hint: 'A new Flutter project.',
                  helper: 'pubspec 의 description 이 됩니다. 비워두면 기본 문구를 씁니다.',
                  controller: _description,
                  enabled: !_running,
                ),
                const SizedBox(height: 16),
                _Field(
                  fieldKey: GenerateFormPage.organizationFieldKey,
                  label: 'Organization',
                  hint: 'com.example',
                  helper: '안드로이드 applicationId 와 iOS 번들 ID 의 앞부분이 됩니다.',
                  controller: _organization,
                  enabled: !_running,
                ),
                const SizedBox(height: 16),
                _CheckboxGroup<ProjectPlatform>(
                  label: '플랫폼',
                  helper: '고르지 않은 플랫폼은 폴더조차 만들어지지 않습니다.',
                  options: ProjectPlatform.values,
                  labelOf: (platform) => platform.label,
                  keyOf: GenerateFormPage.platformKey,
                  selected: _platforms,
                  enabled: !_running,
                  onToggle: (platform, on) => setState(() {
                    if (on) {
                      _platforms.add(platform);
                    } else {
                      _platforms.remove(platform);
                    }
                  }),
                ),
                const SizedBox(height: 16),
                _CheckboxGroup<AppLanguage>(
                  label: '지원 언어',
                  helper: '고르지 않은 언어의 번역 파일은 결과물에 남지 않습니다.',
                  options: AppLanguage.values,
                  labelOf: (language) => language.label,
                  keyOf: GenerateFormPage.languageKey,
                  selected: _languages,
                  enabled: !_running,
                  onToggle: (language, on) => setState(() {
                    if (on) {
                      _languages.add(language);
                    } else {
                      _languages.remove(language);
                    }
                  }),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  key: GenerateFormPage.includeExampleKey,
                  value: _includeExample,
                  onChanged: _running
                      ? null
                      : (on) => setState(() => _includeExample = on),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.primary,
                  title: Text(
                    '컴포넌트 예제 페이지 포함',
                    style: TextStyle(
                      color: colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '끄면 홈 화면이 빈 채로 시작합니다. '
                    'shadcn 컴포넌트는 꺼도 그대로 남습니다.',
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Field(
                  fieldKey: GenerateFormPage.outputParentFieldKey,
                  label: '만들 위치',
                  hint: '/Users/me/projects',
                  controller: _outputParent,
                  enabled: !_running,
                  trailing: TextButton(
                    onPressed: _running ? null : _pickOutputFolder,
                    child: const Text('찾아보기'),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _running ? null : _generate,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(_running ? '만드는 중…' : '생성'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  _Banner(
                    background: colors.destructive.withValues(alpha: 0.12),
                    border: colors.destructive,
                    child: SelectableText(
                      _error!,
                      style: TextStyle(color: colors.destructive),
                    ),
                  ),
                ],
                if (_step != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _step!.label,
                        style: TextStyle(color: colors.foreground),
                      ),
                    ],
                  ),
                ],
                if (!_log.isEmpty) ...[
                  const SizedBox(height: 12),
                  LogView(log: _log),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _ResultBanner(
                    result: _result!,
                    onOpenFolder: _openResultFolder,
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

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.enabled,
    this.hint,
    this.helper,
    this.trailing,
  });

  /// 입력칸을 집어내는 키. 필드는 뒤따르는 티켓에서 계속 늘어나므로
  /// 순서로 찾으면 그때마다 테스트가 깨진다.
  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? hint;
  final String? helper;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: fieldKey,
                controller: controller,
                enabled: enabled,
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: TextStyle(color: colors.mutedForeground, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// 체크박스 여러 개를 한 묶음으로 보여주는 자리.
///
/// 하나도 안 고른 상태를 여기서 막지 않는다. 생성 버튼을 누르는 순간 값
/// 타입이 던지고 그 문장이 오류 자리에 뜬다 — 잘못된 이름과 같은 길을 타므로
/// "막는 자리" 가 화면 곳곳으로 흩어지지 않는다.
class _CheckboxGroup<T> extends StatelessWidget {
  const _CheckboxGroup({
    required this.label,
    required this.helper,
    required this.options,
    required this.labelOf,
    required this.keyOf,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final String label;
  final String helper;
  final List<T> options;
  final String Function(T option) labelOf;
  final Key Function(T option) keyOf;
  final Set<T> selected;
  final bool enabled;
  final void Function(T option, bool on) onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          children: [
            for (final option in options)
              InkWell(
                key: keyOf(option),
                onTap: enabled
                    ? () => onToggle(option, !selected.contains(option))
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: selected.contains(option),
                      onChanged: enabled
                          ? (on) => onToggle(option, on ?? false)
                          : null,
                      activeColor: colors.primary,
                      checkColor: colors.primaryForeground,
                      side: BorderSide(color: colors.border),
                    ),
                    Text(
                      labelOf(option),
                      style: TextStyle(color: colors.foreground),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: TextStyle(color: colors.mutedForeground, fontSize: 12),
        ),
      ],
    );
  }
}

/// 생성이 끝난 뒤의 안내. 성공과 "만들어졌지만 덜 됐음" 을 구분해서 보여준다.
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result, required this.onOpenFolder});

  final GenerationResult result;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final ok = result.succeeded;
    // 성공했지만 덜 된 것이 있는 상태. 실패와 같은 칸에 두면 안 된다 —
    // 결과물은 그대로 `flutter run` 되므로 빨간 배너는 거짓말이다. 그렇다고
    // 삼키면 빠진 폰트를 사용자가 영영 모른다(런타임에 조용히 기본 폰트로
    // 떨어진다). 그래서 성공 배너 안에서 따로 말한다.
    final hasWarnings = ok && result.warnings.isNotEmpty;

    return _Banner(
      background: ok
          ? colors.muted
          : colors.destructive.withValues(alpha: 0.12),
      border: ok ? colors.border : colors.destructive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ok
                ? (hasWarnings ? '만들었습니다 — 다만 덜 된 것이 있습니다' : '만들었습니다')
                : '${result.failedStep!.label} 에서 실패했습니다',
            style: TextStyle(
              color: ok ? colors.foreground : colors.destructive,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            result.projectRoot.path,
            style: TextStyle(color: colors.mutedForeground),
          ),
          const SizedBox(height: 10),
          Text(
            ok
                ? '이제 그 폴더에서 flutter run 하면 됩니다.'
                : '프로젝트는 남아 있습니다. 아래 원인을 보고 남은 명령을 직접 이어 돌리면 됩니다.',
            style: TextStyle(color: colors.mutedForeground),
          ),
          if (!ok) ...[
            const SizedBox(height: 8),
            SelectableText(
              result.failureMessage ?? '',
              style: TextStyle(color: colors.destructive, fontSize: 12),
            ),
          ],
          if (hasWarnings) ...[
            const SizedBox(height: 8),
            // `destructive` 를 쓰지 않는다 — 그 색은 "실패했다" 를 뜻하는데
            // 여기서는 프로젝트가 멀쩡하다. tweakcn 에 경고용 토큰이 없으므로
            // 본문색을 쓰고, 무슨 상태인지는 위 제목이 말한다.
            SelectableText(
              result.warnings.join('\n\n'),
              style: TextStyle(color: colors.foreground, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpenFolder,
              child: const Text('폴더 열기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.background,
    required this.border,
    required this.child,
  });

  final Color background;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
