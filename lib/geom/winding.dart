part of voronoi;

class Winding {
  static const Winding CLOCKWISE = Winding._('CLOCKWISE');
  static const Winding COUNTERCLOCKWISE = Winding._('COUNTERCLOCKWISE');
  static const Winding NONE = Winding._('NONE');

  static get values => [CLOCKWISE, COUNTERCLOCKWISE, NONE];

  final String name;

  const Winding._(this.name);

  String toString() => "$name";
}
