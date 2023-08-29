part of voronoi;

class Circle {
  Point<num> center;
  num radius;

  Circle(this.center, this.radius);

  @override
  String toString() => "Circle (center: $center radius: $radius)";
}
