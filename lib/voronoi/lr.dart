part of voronoi;

class LR {
  static const LR LEFT = const LR._('LEFT');
  static const LR RIGHT = const LR._('RIGHT');

  static get values => [LEFT, RIGHT];

  final String name;

  const LR._(this.name);
  
  LR get other {
    return this == LEFT ? RIGHT : LEFT;
  }
  
  String toString() => "$name";
}
