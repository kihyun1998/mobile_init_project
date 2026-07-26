import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'template_locator.dart';
import 'template_path_store.dart';

/// 폴더를 묻는 방법. 진짜 창을 띄우지 않고 시험할 수 있도록 갈라둔다.
typedef DirectoryChooser = Future<String?> Function();

Future<String?> systemDirectoryChooser() =>
    FilePicker.getDirectoryPath(dialogTitle: 'template 폴더를 고르세요');

/// 사용자가 폴더를 고른 결과.
///
/// 셋 중 하나다: 취소했거나(둘 다 null), 템플릿이 아니거나([problem]),
/// 받아들여져 저장됐거나([directory]).
class TemplatePick {
  const TemplatePick.cancelled()
      : directory = null,
        problem = null;
  const TemplatePick.rejected(String this.problem) : directory = null;
  const TemplatePick.accepted(Directory this.directory) : problem = null;

  final Directory? directory;
  final String? problem;
}

/// 폴더를 물어 템플릿이 맞는지 확인하고, 맞을 때만 기억한다.
///
/// **확인이 저장보다 먼저다.** 아니면 엉뚱한 폴더가 저장돼서, 다음 실행에
/// 그것 때문에 또 실패하고 사용자는 이유를 모른 채 같은 창을 다시 본다.
Future<TemplatePick> chooseTemplate(
  TemplatePathStore store,
  DirectoryChooser choose,
) async {
  final picked = await choose();
  if (picked == null) return const TemplatePick.cancelled();

  // 다음 실행의 작업 폴더가 어디일지 알 수 없으므로 절대 경로로 적어둔다.
  final dir = Directory(picked).absolute;
  final problem = TemplateLocator.problemWith(dir);
  if (problem != null) return TemplatePick.rejected(problem);

  await store.write(dir.path);
  return TemplatePick.accepted(dir);
}
