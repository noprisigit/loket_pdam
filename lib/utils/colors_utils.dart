// lib/util/color_utils.dart

import 'package:flutter/material.dart' show Color;

class HexColor extends Color {

  static _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return int.parse("0x$hexColor");
    }
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}