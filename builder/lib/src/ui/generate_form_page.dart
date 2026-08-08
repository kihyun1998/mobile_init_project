import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import '../generation/app_language.dart';
import '../generation/application_id.dart';
import '../generation/bundle_identifier.dart';
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

  /// org 칸 아래에서 "이 값으로 만들면 식별자가 이것이 된다" 를 말하는 두
  /// 자리. **읽기 전용이다** — 우리가 정하는 값이 아니라 `flutter create` 가
  /// 정하는 값을 되비추는 칸이라, 고칠 수 있게 열어두면 고친 글자가 조용히
  /// 무시된다.
  static const applicationIdKey = Key('generate.preview.applicationId');
  static const bundleIdKey = Key('generate.preview.bundleId');

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

  /// 되비추는 두 칸. 사람이 치는 칸이 아니라 [_recomputeIdentifiers] 가
  /// 채우는 칸이다.
  final _applicationId = TextEditingController();
  final _bundleId = TextEditingController();

  /// 기본값은 설정 객체가 정한 것을 그대로 쓴다. 여기에 목록을 한 벌 더
  /// 적어두면 플랫폼이 늘어날 때 둘 중 하나만 고치게 된다.
  final _platforms = PlatformSelection.mobile.platforms.toSet();

  final _languages = LanguageSelection.all.languages.toSet();

  bool _includeExample = true;

  /// 표시 이름 칸이 프로젝트 이름을 따라가는 중인지.
  ///
  /// 사람이 표시 이름을 직접 고치면 끊기고, 완전히 비우면 다시 이어진다.
  bool _displayNameFollowsName = true;

  bool _running = false;

  /// 시작조차 못 한 경우의 오류. 프로젝트가 만들어지지 않았다는 뜻이다.
  String? _error;

  /// 만들어진 프로젝트. 후처리가 실패했어도 채워진다.
  GenerationResult? _result;

  GenerationStep? _step;
  final _log = GenerationLog();

  @override
  void initState() {
    super.initState();
    _name.addListener(_mirrorNameIntoDisplayName);
    // 두 식별자는 이름과 org 를 **둘 다** 먹으므로 양쪽을 듣는다.
    _name.addListener(_recomputeIdentifiers);
    _organization.addListener(_recomputeIdentifiers);
  }

  /// 되비추는 두 칸을 다시 채운다.
  ///
  /// **이 칸들이 있는 이유**는 `Organization.parse` 가 형식만 보기 때문이다.
  /// org 칸에 프로젝트 이름을 한 번 더 넣는 것도(`com.example.my_app` +
  /// `my_app` → `com.example.my_app.my_app`), `com.example` 의 `e` 를
  /// 빠뜨리는 것도 **형식으로는 올바라서** 검증으로는 영영 안 걸린다. 그리고
  /// 두 식별자는 스토어에 올라간 뒤에는 못 바꾼다 — 폴더를 지우고 다시
  /// 만들면 되는 다른 오타와 다르다. 그래서 막는 대신 **보여준다.**
  ///
  /// **채워주거나 고쳐주지 않는다.** org 를 프로젝트 이름에서 파생시키면 그
  /// 파생이 만들어내는 것이 정확히 위의 `com.<name>.<name>` 이다. 같은
  /// 이유로 두 칸을 편집할 수 있게 열지도 않는다 — 고친 글자를 되먹이려면
  /// `com.foo.bar.my_app` 에서 어디까지가 org 인지 우리가 찍어야 한다.
  ///
  /// 하나라도 형식이 아니면 **비운다.** 무엇이 잘못됐는지는 여기서 말하지
  /// 않는다 — 생성 버튼을 누를 때 값 타입이 말한다. 빈 칸에는 hint 가
  /// 드러나므로 화면은 여전히 무엇이 들어올 자리인지 말한다.
  ///
  /// `setState` 를 부르지 않는다. 이 함수는 타이핑 한 글자마다 불리는데,
  /// 컨트롤러에 써넣는 것만으로 두 칸이 갱신되므로 폼 전체를 다시 그릴
  /// 이유가 없다.
  void _recomputeIdentifiers() {
    final organization = _organization.text;
    final projectName = _name.text;

    _applicationId.text =
        ApplicationId.tryParse(
          organization: organization,
          projectName: projectName,
        )?.value ??
        '';
    _bundleId.text =
        BundleIdentifier.tryParse(
          organization: organization,
          projectName: projectName,
        )?.value ??
        '';
  }

  /// 프로젝트 이름을 표시 이름 칸에 그대로 써넣는다.
  ///
  /// `GenerationConfig` 가 빈 표시 이름을 프로젝트 이름으로 바꾸므로, 빈 칸은
  /// "표시 이름이 없다" 가 아니라 **"프로젝트 이름이 들어갈 것이다"** 를 뜻한다.
  /// 그것을 빈 칸으로 그려두면 화면이 제출될 값과 다른 말을 한다.
  void _mirrorNameIntoDisplayName() {
    if (!_displayNameFollowsName) return;
    final next = _name.text;
    if (_displayName.text == next) return;
    _displayName.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  /// 표시 이름 칸을 **사람이** 고쳤을 때.
  ///
  /// 컨트롤러 리스너로 들으면 안 된다 — [_mirrorNameIntoDisplayName] 이 써넣은
  /// 것까지 여기로 되돌아와서, 미러링 첫 글자에 추적이 스스로 끊긴다.
  /// `onChanged` 는 사람이 친 것에만 불린다.
  void _onDisplayNameEdited(String value) {
    // 공백뿐인 것도 비운 것으로 본다. `GenerationConfig` 가 trim 한 뒤에
    // 비었는지를 보므로, 그렇게 제출하면 어차피 프로젝트 이름이 들어간다.
    if (value.trim().isNotEmpty) {
      _displayNameFollowsName = false;
      return;
    }
    // 다음 타이핑을 기다리지 않고 그 자리에서 되채운다. 빈 칸으로 남겨두면
    // 이 화면이 고치려던 그 거짓말로 되돌아간다.
    _displayNameFollowsName = true;
    _mirrorNameIntoDisplayName();
  }

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _description.dispose();
    _organization.dispose();
    _outputParent.dispose();
    _applicationId.dispose();
    _bundleId.dispose();
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
                  // "비워두면 프로젝트 이름을 씁니다" 라고 하면 이제 어긋난다 —
                  // 비워둘 수가 없다. 지우는 순간 다시 채워지기 때문이고, 그
                  // 이유는 _mirrorNameIntoDisplayName 의 doc-comment 에 있다.
                  helper:
                      '앱 타이틀과 안드로이드·iOS 홈 화면 아이콘 밑에 보입니다. '
                      '프로젝트 이름을 따라갑니다 — 직접 고치면 멈추고, 비우면 다시 따라갑니다.',
                  controller: _displayName,
                  enabled: !_running,
                  onChanged: _onDisplayNameEdited,
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
                  // 두 식별자가 어떻게 다른지를 여기서 문장으로 설명하지
                  // 않는다. 아래 두 칸이 실제 값을 나란히 보여주므로, 글로
                  // 적으면 화면이 같은 말을 두 번 하게 된다.
                  helper: '안드로이드 applicationId 와 iOS 번들 ID 의 앞부분이 됩니다.',
                  controller: _organization,
                  enabled: !_running,
                ),
                const SizedBox(height: 16),
                _Field(
                  fieldKey: GenerateFormPage.applicationIdKey,
                  label: '안드로이드 applicationId',
                  hint: 'com.example.my_app',
                  // 잠긴 이유를 두 칸 중 첫 칸에서 한 번만 말한다.
                  helper:
                      'flutter create 가 정하는 값이라 고칠 수 없습니다. 이름과 org 를 그대로 이어붙입니다.',
                  controller: _applicationId,
                  enabled: !_running,
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                _Field(
                  fieldKey: GenerateFormPage.bundleIdKey,
                  label: 'iOS 번들 ID',
                  hint: 'com.example.myApp',
                  // 왜 다른지를 여기서 한 줄로 말한다. 값 자체는 위아래 칸을
                  // 나란히 보면 보이므로, 문장은 "왜" 만 맡는다.
                  helper:
                      '같은 두 칸에서 나오지만 규칙이 다릅니다 — 이름이 camelCase 가 되고 밑줄이 사라집니다.',
                  controller: _bundleId,
                  enabled: !_running,
                  readOnly: true,
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
    this.onChanged,
    this.readOnly = false,
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

  /// **사람이 친 것에만** 불린다. 컨트롤러에 프로그램으로 써넣은 값에는 불리지
  /// 않는다 — 표시 이름의 따라가기가 정확히 그 차이 위에 서 있다.
  final ValueChanged<String>? onChanged;

  /// 되비추기만 하는 칸. 글자를 고칠 수 없되 **고를 수는 있다** — 번들 ID 는
  /// 스토어 콘솔에 붙여넣을 일이 있는 값이라 복사를 막으면 안 된다.
  ///
  /// `enabled: false` 로 잠그지 않는 이유가 그것이다. 그쪽은 선택도 함께
  /// 막힌다.
  final bool readOnly;

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
                readOnly: readOnly,
                onChanged: onChanged,
                style: TextStyle(
                  color: readOnly ? colors.mutedForeground : colors.foreground,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                  // 잠긴 칸은 배경으로 구분한다. 테두리를 지우면 어디까지가
                  // 한 칸인지 안 보이고, 글자를 더 흐리게 하면 붙여넣으려고
                  // 읽는 값이 읽기 힘들어진다.
                  filled: readOnly,
                  fillColor: readOnly ? colors.muted : null,
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
