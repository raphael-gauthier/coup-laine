import 'package:meta/meta.dart';

@immutable
class AnimalCount {
  final int categoryId;
  final int count;
  const AnimalCount({required this.categoryId, required this.count});

  @override
  bool operator ==(Object other) =>
      other is AnimalCount &&
      other.categoryId == categoryId &&
      other.count == count;

  @override
  int get hashCode => Object.hash(categoryId, count);
}
