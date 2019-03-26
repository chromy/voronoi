part of voronoi;

class Winding {
  static const Winding CLOCKWISE = const Winding._('CLOCKWISE');
  static const Winding COUNTERCLOCKWISE = const Winding._('COUNTERCLOCKWISE');
  static const Winding NONE = const Winding._('NONE');

  static get values => [CLOCKWISE, COUNTERCLOCKWISE, NONE];

  final String name;

  const Winding._(this.name);

  String toString() => "$name";
}
