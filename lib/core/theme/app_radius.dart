import 'package:flutter/material.dart';

abstract class AppRadius {
  static final BorderRadius sm = BorderRadius.circular(8);
  static final BorderRadius md = BorderRadius.circular(12);
  static final BorderRadius lg = BorderRadius.circular(16);
  static final BorderRadius xl = BorderRadius.circular(24);
  static final BorderRadius full = BorderRadius.circular(100);
}

abstract class AppShadows {
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x14111111), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x1A111111), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> level3 = [
    BoxShadow(color: Color(0x1F111111), blurRadius: 24, offset: Offset(0, 8)),
  ];
}
