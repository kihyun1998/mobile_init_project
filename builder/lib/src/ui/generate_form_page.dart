import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import '../generation/file_manager.dart';
import '../generation/generation_config.dart';
import '../generation/generation_event.dart';
import '../generation/generation_exception.dart';
import '../generation/organization.dart';
import '../generation/package_name.dart';
import '../generation/process_runner.dart';
import '../generation/project_generator.dart';
import 'generation_log.dart';
import 'log_view.dart';

/// 이름·org·설명·출력 폴더를 받아 새 프로젝트를 만들고, 진행 상황과 명령
/// 출력을 보여주는 화면.
///
/// 옵션(플랫폼·언어·예제)과 붙여넣은 테마 반영은 뒤따르는 티켓에서 붙는다.
class GenerateFormPage extends StatefulWidget {
  const GenerateFormPage({
    super.key,
    required this.generator,
    required this.processRunner,
  });

  static const nameFieldKey = Key('generate.field.name');
  static const descriptionFieldKey = Key('generate.field.description');
  static const organizationFieldKey = Key('generate.field.organization');
  static const outputParentFieldKey = Key('generate.field.outputParent');

  final ProjectGenerator generator;

  /// 결과 폴더를 파일 관리자로 여는 데 쓴다. 생성기 것을 빌려 쓰지 않고
  /// 따로 받는다 — 이 화면이 생성기 내부를 알 이유가 없다.
  final ProcessRunner processRunner;

  @override
  State<GenerateFormPage> createState() => _GenerateFormPageState();
}

class _GenerateFormPageState extends State<GenerateFormPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _organization = TextEditingController(text: 'com.example');
  final _outputParent = TextEditingController();

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
      final description = _description.text.trim();
      final result = await widget.generator.generate(
        GenerationConfig(
          // 형식이 틀리면 여기서 던진다. flutter create 는 시작도 하지 않는다.
          projectName: PackageName.parse(_name.text),
          organization: Organization.parse(_organization.text),
          outputParent: Directory(_outputParent.text.trim()),
          description: description.isEmpty
              ? GenerationConfig.defaultDescription
              : description,
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
    if (!result.succeeded && mounted) {
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
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: colors.foreground),
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

/// 생성이 끝난 뒤의 안내. 성공과 "만들어졌지만 덜 됐음" 을 구분해서 보여준다.
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result, required this.onOpenFolder});

  final GenerationResult result;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final ok = result.succeeded;

    return _Banner(
      background: ok ? colors.muted : colors.destructive.withValues(alpha: 0.12),
      border: ok ? colors.border : colors.destructive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ok ? '만들었습니다' : '${result.failedStep!.label} 에서 실패했습니다',
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
