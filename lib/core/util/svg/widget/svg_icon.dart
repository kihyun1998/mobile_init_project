// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../model/enum_svg_asset.dart';
import '../svg_util.dart';

class SVGIcon extends StatelessWidget {
  final SVGAsset asset;
  final Color? color;
  final double? size;
  final bool isCustom;

  const SVGIcon({
    super.key,
    required this.asset,
    this.color,
    this.size,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SVGUtil().getSVG(
          asset: asset, svgColor: color, svgSize: size, isCustom: isCustom),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        return SvgPicture.string(
          snapshot.data!,
          width: size,
          height: size,
        );
      },
    );
  }
}
