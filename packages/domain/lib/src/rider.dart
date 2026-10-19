import 'package:meta/meta.dart';

import 'identifiers.dart';

@immutable
final class Rider {
  const Rider({required this.id, required this.number, required this.name});

  final RiderId id;
  final int number;
  final String name;

  @override
  bool operator ==(Object other) => other is Rider && other.id == id && other.number == number && other.name == name;

  @override
  int get hashCode => Object.hash(id, number, name);

  @override
  String toString() => 'Rider(#$number $name)';
}
