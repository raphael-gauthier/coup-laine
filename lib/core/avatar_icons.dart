import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

const List<String> kAvatarKeys = [
  'compass',
  'map',
  'scissors',
  'stethoscope',
  'hammer',
  'heart',
];

const String kDefaultAvatarKey = 'compass';

IconData iconForAvatarKey(String? key) {
  switch (key) {
    case 'map':
      return FIcons.map;
    case 'scissors':
      return FIcons.scissors;
    case 'stethoscope':
      return FIcons.stethoscope;
    case 'hammer':
      return FIcons.hammer;
    case 'heart':
      return FIcons.heart;
    case 'compass':
    default:
      return FIcons.compass;
  }
}
