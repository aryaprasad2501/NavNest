import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(12.0);
  static const EdgeInsets horizontalL = EdgeInsets.symmetric(horizontal: 16.0);
}

class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double s = 10.0;
  static const double m = 14.0;
  static const double l = 18.0;
  static const double xl = 22.0;
  static const double full = 999.0;

  static const BorderRadius roundedXS = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius roundedS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius roundedM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius roundedL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius roundedXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(full));
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> softCard = [
    BoxShadow(
      color: Color(0x0A162B1F),
      offset: Offset(0, 3),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x12162B1F),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x0C162B1F),
      offset: Offset(0, -4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
}
