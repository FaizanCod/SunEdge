

import 'package:flutter/material.dart';

import '../../Helper/Color.dart';

ThemeData lightTheme=ThemeData(
  canvasColor: ThemeData().colorScheme.lightWhite,
  cardColor: colors.cardColor,
  dialogBackgroundColor: ThemeData().colorScheme.white,
  iconTheme:
  ThemeData().iconTheme.copyWith(color: colors.primary),
  primarySwatch: colors.primary_app,
  primaryColor: ThemeData().colorScheme.lightWhite,
  fontFamily: 'OpenSans',
  colorScheme:
  ColorScheme.fromSwatch(primarySwatch: colors.primary_app)
      .copyWith(
      secondary: colors.secondary,
      brightness: Brightness.light),
  textTheme: TextTheme(
      headline6: TextStyle(
        color: ThemeData().colorScheme.fontColor,
        fontWeight: FontWeight.w600,
      ),
      subtitle1: TextStyle(
          color: ThemeData().colorScheme.fontColor,
          fontWeight: FontWeight.bold))
      .apply(bodyColor: ThemeData().colorScheme.fontColor),
);


// ThemeData darkTheme=ThemeData(
//   canvasColor: colors.darkColor,
//   cardColor: colors.darkColor2,
//   dialogBackgroundColor: colors.darkColor2,
//   primaryColor: colors.darkColor,
//   textSelectionTheme: TextSelectionThemeData(
//       cursorColor: colors.darkIcon,
//       selectionColor: colors.darkIcon,
//       selectionHandleColor: colors.darkIcon),
//   toggleableActiveColor: colors.primary,
//   fontFamily: 'OpenSans',
//   //brightness: Brightness.dark,
//   iconTheme:
//   ThemeData().iconTheme.copyWith(color: colors.primary),
//   textTheme: TextTheme(
//       headline6: TextStyle(
//         color: ThemeData().colorScheme.fontColor,
//         fontWeight: FontWeight.w600,
//       ),
//       subtitle1: TextStyle(
//           color: ThemeData().colorScheme.fontColor,
//           fontWeight: FontWeight.bold))
//       .apply(bodyColor: ThemeData().colorScheme.fontColor),
//   colorScheme:
//   ColorScheme.fromSwatch(primarySwatch: colors.primary_app)
//       .copyWith(
//       secondary: colors.darkIcon,
//       brightness: Brightness.dark),
// );