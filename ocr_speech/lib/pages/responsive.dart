// ignore_for_file: non_constant_identifier_names, duplicate_ignore

import 'package:flutter/widgets.dart';

// ignore: duplicate_ignore
class Responsive{
  late MediaQueryData data;
  // ignore: non_constant_identifier_names
  double ScreenWidth = 0;
  double ScreenHeight = 0;
  double BlockWidth = 0;
  double BlockHeight = 0;

  double SafeAreawidth = 0;
  double SafeAreaHeight = 0;

  double SafeBlockWidth = 0;
  double SafeBlockHeight = 0;

  Responsive(BuildContext context){
    data = MediaQuery.of(context);
    ScreenWidth = data.size.width;
    ScreenHeight = data.size.height;
    BlockHeight = ScreenHeight / 100;
    BlockWidth = ScreenWidth / 100;

    SafeAreaHeight = data.padding.top + data.padding.bottom;
    SafeAreawidth = data.padding.left + data.padding.right;

    SafeBlockHeight = (ScreenHeight - SafeAreaHeight) / 100; 
    SafeBlockWidth  = (ScreenWidth - SafeAreawidth)/100;
  }
}