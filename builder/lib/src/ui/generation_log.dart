import 'package:flutter/foundation.dart';

/// 생성 중 흘러나온 출력을 담는다.
///
/// 새 프로젝트에서 처음 도는 `build_runner` 는 수천 줄을 뱉는다. 전부 들고
/// 있으면 메모리도 메모리지만 화면이 버벅인다. 위쪽은 어차피 아무도 안 보므로
/// 최근 것만 남긴다.
class GenerationLog extends ChangeNotifier {
  static const maxLines = 500;

  final _lines = <String>[];

  List<String> get lines => List.unmodifiable(_lines);

  bool get isEmpty => _lines.isEmpty;

  void add(String line) {
    _lines.add(line);
    if (_lines.length > maxLines) {
      _lines.removeRange(0, _lines.length - maxLines);
    }
    notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}
