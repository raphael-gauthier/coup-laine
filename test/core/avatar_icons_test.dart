import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/avatar_icons.dart';
import 'package:forui/forui.dart';

void main() {
  test('default key (null) returns compass icon', () {
    expect(iconForAvatarKey(null), FIcons.compass);
  });

  test('unknown key falls back to compass', () {
    expect(iconForAvatarKey('not-a-real-key'), FIcons.compass);
  });

  test('all six curated keys resolve', () {
    expect(iconForAvatarKey('compass'), FIcons.compass);
    expect(iconForAvatarKey('map'), FIcons.map);
    expect(iconForAvatarKey('scissors'), FIcons.scissors);
    expect(iconForAvatarKey('stethoscope'), FIcons.stethoscope);
    expect(iconForAvatarKey('hammer'), FIcons.hammer);
    expect(iconForAvatarKey('heart'), FIcons.heart);
  });

  test('kAvatarKeys lists all six', () {
    expect(kAvatarKeys, hasLength(6));
    expect(kAvatarKeys.first, 'compass');
  });
}
