import 'package:flutter/services.dart';

import 'enum/color_target.dart';
import 'model/enum_svg_asset.dart';

class SVGUtil {
  static final SVGUtil _instance = SVGUtil._internal();

  factory SVGUtil() => _instance;

  SVGUtil._internal();

  static final RegExp _svgNPathRegex = RegExp(r'<(svg|path)(\s+[^>]*?)?/?>');
  static final RegExp _widthRegex = RegExp(r'\swidth="[^"]*"');
  static final RegExp _heightRegex = RegExp(r'\sheight="[^"]*"');

  static final RegExp _fillRegex = RegExp(r'fill="(?!none")[^"]*"');
  static final RegExp _strokeRegex = RegExp(r'stroke="[^"]*"');

  static final RegExp _fillCustomRegex =
      RegExp(r'fill="(?!(none|white))"[^"]*"');
  static final RegExp _strokeCustomRegex =
      RegExp(r'stroke="(?!(none|white))"[^"]*"');

  final Map<SVGAsset, Map<String, String>> _processedSVGCache = {};

  Future<String> getSVG({
    required SVGAsset asset,
    Color? svgColor,
    double? svgSize,
    bool isCustom = false,
    ColorTarget colorTarget = ColorTarget.auto,
  }) async {
    try {
      // 1. 캐시 키 생성
      final cacheKey =
          _generateCacheKey(color: svgColor, size: svgSize, isCustom: isCustom);

      // 2. 캐시된 결과 확인
      if (_processedSVGCache[asset]?[cacheKey] != null) {
        return _processedSVGCache[asset]![cacheKey]!;
      }

      // 3. 원본 SVG 로드
      String svgString = await rootBundle.loadString(asset.path);

      // 4. 크기 적용
      if (svgSize != null) {
        svgString = _applySize(svgString);
      }

      // 5. 색상 적용
      if (svgColor != null) {
        svgString = _applyColor(
          svgString: svgString,
          color: svgColor,
          isCustom: isCustom,
          target: colorTarget,
        );
      }

      // 6. 결과 캐싱
      _processedSVGCache[asset] ??= {};
      _processedSVGCache[asset]![cacheKey] = svgString;

      return svgString;
    } catch (error, stackTrace) {
      return "";
    }
  }

  /// SVG에서 width, height 속성을 제거합니다
  String _applySize(String svgString) {
    return svgString.replaceAll(_widthRegex, '').replaceAll(_heightRegex, '');
  }

  /// SVG에 색상을 적용합니다
  String _applyColor({
    required String svgString,
    required Color color,
    bool isCustom = false,
    ColorTarget target = ColorTarget.auto,
  }) {
    final colorHex = _colorToHex(color);

    return svgString.replaceAllMapped(
      _svgNPathRegex,
      (match) {
        String tag = match.group(0)!;

        switch (target) {
          case ColorTarget.fill:
            tag = _applyFillOnly(tag, colorHex, isCustom);
            break;

          case ColorTarget.stroke:
            tag = _applyStrokeOnly(tag, colorHex, isCustom);
            break;

          case ColorTarget.both:
            tag = _applyBoth(tag, colorHex, isCustom);
            break;

          case ColorTarget.auto:
            tag = _applyAuto(tag, colorHex, isCustom);
            break;
        }

        return tag;
      },
    );
  }

// 각각의 적용 메서드들
  String _applyAuto(String tag, String colorHex, bool isCustom) {
    bool hasFill =
        isCustom ? _fillCustomRegex.hasMatch(tag) : _fillRegex.hasMatch(tag);
    bool hasStroke = isCustom
        ? _strokeCustomRegex.hasMatch(tag)
        : _strokeRegex.hasMatch(tag);

    if (hasFill) {
      // 기존 fill이 있으면 fill 변경
      return _applyFillOnly(tag, colorHex, isCustom);
    } else if (hasStroke) {
      // fill이 없고 stroke가 있으면 stroke 변경
      return _applyStrokeOnly(tag, colorHex, isCustom);
    } else {
      // 둘 다 없으면 fill 추가 (기본값)
      return _applyFillOnly(tag, colorHex, isCustom);
    }
  }

  String _applyFillOnly(String tag, String colorHex, bool isCustom) {
    if (isCustom) {
      if (_fillCustomRegex.hasMatch(tag)) {
        return tag.replaceAllMapped(
            _fillCustomRegex, (match) => 'fill="$colorHex"');
      } else if (!tag.contains('fill=')) {
        return _addAttribute(tag, 'fill', colorHex);
      }
    } else {
      if (_fillRegex.hasMatch(tag)) {
        return tag.replaceAllMapped(_fillRegex, (match) => 'fill="$colorHex"');
      } else if (!tag.contains('fill=')) {
        return _addAttribute(tag, 'fill', colorHex);
      }
    }
    return tag;
  }

  String _applyStrokeOnly(String tag, String colorHex, bool isCustom) {
    if (isCustom) {
      if (_strokeCustomRegex.hasMatch(tag)) {
        return tag.replaceAllMapped(
            _strokeCustomRegex, (match) => 'stroke="$colorHex"');
      } else if (!tag.contains('stroke=')) {
        return _addAttribute(tag, 'stroke', colorHex);
      }
    } else {
      if (_strokeRegex.hasMatch(tag)) {
        return tag.replaceAllMapped(
            _strokeRegex, (match) => 'stroke="$colorHex"');
      } else if (!tag.contains('stroke=')) {
        return _addAttribute(tag, 'stroke', colorHex);
      }
    }
    return tag;
  }

  String _applyBoth(String tag, String colorHex, bool isCustom) {
    // fill 먼저 적용
    tag = _applyFillOnly(tag, colorHex, isCustom);
    // stroke 적용
    tag = _applyStrokeOnly(tag, colorHex, isCustom);
    return tag;
  }

  /// 태그에 속성을 추가하는 헬퍼 메서드
  String _addAttribute(String tag, String attribute, String value) {
    if (tag.endsWith('/>')) {
      return tag.replaceFirst('/>', ' $attribute="$value"/>');
    } else if (tag.endsWith('>')) {
      return tag.replaceFirst('>', ' $attribute="$value">');
    }
    return tag;
  }

  /// Color 객체를 Hex 문자열로 변환합니다
  String _colorToHex(Color color) {
    final int r = (color.r * 255).toInt();
    final int g = (color.g * 255).toInt();
    final int b = (color.b * 255).toInt();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  /// 캐시 키를 생성합니다
  String _generateCacheKey({
    Color? color,
    double? size,
    bool isCustom = false,
  }) {
    String colorPart = 'null';
    if (color != null) {
      colorPart = '${color.a}_${color.r}_${color.g}_${color.b}';
    }

    final sizePart = size?.toString() ?? 'null';
    final customPart = isCustom.toString();

    return '$colorPart..$sizePart..$customPart';
  }

  void clearCache() {
    _processedSVGCache.clear();
  }
}
