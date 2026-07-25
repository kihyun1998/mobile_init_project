import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import '../generation/generation_config.dart';
import '../generation/generation_exception.dart';
import '../generation/project_generator.dart';

/// 이름·org·출력 폴더를 받아 새 프로젝트를 만드는 화면.
///
/// 옵션(플랫폼·언어·예제·테마)과 후처리 자동 실행은 뒤따르는 티켓에서 붙는다.
class GenerateFormPage extends StatefulWidget {
  const GenerateFormPage({super.key, required this.generator});

  static const nameFieldKey = Key('generate.field.name');
  static const descriptionFieldKey = Key('generate.field.description');
  static const organizationFieldKey = Key('generate.field.organization');
  static const outputParentFieldKey = Key('generate.field.outputParent');

  final ProjectGenerator generator;

  @override
  State<GenerateFormPage> createState() => _GenerateFormPageState();
}

class _GenerateFormPageState extends State<GenerateFormPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _organization = TextEditingController(text: 'com.example');
  final _outputParent = TextEditingController();

  bool _running = false;
  String? _error;
  Directory? _generated;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _organization.dispose();
    _outputParent.dispose();
    super.dispose();
  }

  Future<void> _pickOutputFolder() async {
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: '프로젝트를 만들 폴더',
    );
    if (picked != null) _outputParent.text = picked;
  }

  Future<void> _generate() async {
    setState(() {
      _running = true;
      _error = null;
      _generated = null;
    });

    try {
      final description = _description.text.trim();
      final root = await widget.generator.generate(
        GenerationConfig(
          projectName: _name.text.trim(),
          organization: _organization.text.trim(),
          outputParent: Directory(_outputParent.text.trim()),
          // 비워두면 GenerationConfig 의 기본 문구를 그대로 쓴다.
          description: description.isEmpty
              ? 'A new Flutter project.'
              : description,
        ),
      );
      if (mounted) setState(() => _generated = root);
    } on GenerationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '예상하지 못한 오류입니다: $e');
    } finally {
      if (mounted) setState(() => _running = false);
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
                if (_generated != null) ...[
                  const SizedBox(height: 20),
                  _Banner(
                    background: colors.muted,
                    border: colors.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '만들었습니다',
                          style: TextStyle(
                            color: colors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          _generated!.path,
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '아직 의존성이 설치되지 않았습니다. '
                          '해당 폴더에서 flutter pub get 을 먼저 실행하세요.',
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                      ],
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
