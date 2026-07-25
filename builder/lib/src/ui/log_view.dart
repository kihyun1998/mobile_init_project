import 'package:flutter/material.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

import 'generation_log.dart';

/// 명령 출력이 흐르는 창.
///
/// `build_runner` 가 몇 분씩 도는 동안 여기가 유일하게 "살아 있다" 를 보여주는
/// 곳이라, 항상 마지막 줄이 보여야 한다.
class LogView extends StatefulWidget {
  const LogView({super.key, required this.log});

  static const viewKey = Key('generate.log');

  final GenerationLog log;

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.log.addListener(_onLogChanged);
  }

  @override
  void dispose() {
    widget.log.removeListener(_onLogChanged);
    _scroll.dispose();
    super.dispose();
  }

  void _onLogChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Container(
      key: LogView.viewKey,
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.muted,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListenableBuilder(
        listenable: widget.log,
        builder: (context, _) {
          final lines = widget.log.lines;
          return ListView.builder(
            controller: _scroll,
            itemCount: lines.length,
            itemBuilder: (context, i) => Text(
              lines[i],
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: colors.mutedForeground,
              ),
            ),
          );
        },
      ),
    );
  }
}
