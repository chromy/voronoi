library demo;

import 'dart:html';
import 'dart:math' as math;

import 'package:voronoi/voronoi.dart';

final InputElement slider = querySelector("#slider")! as InputElement;
final InputElement button = querySelector("#button")! as InputElement;
final CanvasElement canvas = querySelector("#area")! as CanvasElement;
final Element notes = querySelector("#notes")!;
final VoronoiDemo demo = VoronoiDemo(canvas, 10, math.Random().nextInt(100000));
num fpsAverage = 0;

void main() {
  slider.onChange.listen((Event e) => update());
  button.onClick.listen((MouseEvent e) => randomiseSeed());
  update(); // Call update() once to generate the diagram without waiting for user input.
}

void update() {
  demo.sites = math.pow(2, num.parse(slider.value ?? "")).toInt();
  demo
    ..recompute()
    ..requestRedraw();
}

void randomiseSeed() {
  demo.seed = math.Random().nextInt(100000);
  update();
}

class VoronoiDemo {
  CanvasElement canvas;

  late num width;
  late num height;
  int sites;
  int seed;

  late Voronoi voronoi;

  VoronoiDemo(this.canvas, this.sites, this.seed) {
    width = canvas.clientWidth;
    height = canvas.clientHeight;
  }

  void recompute() {
    // Create random points.
    final math.Random rng = math.Random(seed);
    Point<int> randomPoint() => Point<int>(rng.nextInt(width.floor()), rng.nextInt(height.floor()));
    final List<Point<num>> randomPoints = List<Point<num>>.generate(sites, (int i) => randomPoint());
    final Set<Point<num>> randomUniquePoints = Set<Point<num>>.from(randomPoints);

    // Compute the diagram.
    final DateTime startTime = DateTime.timestamp();
    voronoi = Voronoi(List<Point<num>>.from(randomUniquePoints), math.Rectangle<num>(0, 0, width, height));
    final DateTime endTime = DateTime.timestamp();
    notes.text = "Voronoi with ${demo.sites} sites calculated in ${endTime.difference(startTime).inMilliseconds} ms.";
  }

  void draw(num _) {
    final CanvasRenderingContext2D context = canvas.context2D;
    drawBackground(context);
    drawLines(context);
    drawSites(context);
  }

  /// Clear the background to white.
  void drawBackground(CanvasRenderingContext2D context) {
    context.clearRect(0, 0, width, height);
  }

  /// Draw the sites of the cells on context.
  void drawSites(CanvasRenderingContext2D context) {
    // Make the indicator for each site a different size depending on how many there are, with larger ones when there are fewer sites and smaller ones when there are more (down to a size of 1 at around 3300 sites).
    final num size = (50 / math.log(voronoi.sites.length * 4) - 4.3).clamp(0.5, 20);
    for (final Point<num> site in voronoi.sites) {
      if (size <=
          1) /* Past a certain point drawing circles looks bad, so just set single pixel rectangles instead. */ {
        context
          ..fillStyle = '#f55'
          ..fillRect(site.x, site.y, 1, 1);
      } else {
        context
          ..fillStyle = '#f55'
          ..beginPath()
          ..arc(site.x, site.y, size, 0, math.pi * 2)
          ..closePath()
          ..fill();
      }
    }
  }

  /// Draw the edges of the cells on context.
  void drawLines(CanvasRenderingContext2D context) {
    // Don't draw edges which have been clipped completely away.
    final List<Edge> edges = voronoi.edges.where((Edge edge) => edge.isVisible).toList();

    const int maxFancyEdgeLimit = 25000;

    context
      ..strokeStyle = '#ccf'
      // If there are too many edges, make them thinner so they can be seen better.
      ..lineWidth = edges.length < maxFancyEdgeLimit ? 1 : 0.7;

    for (final Edge edge in edges) {
      // Past a certain point, defining the gradients takes a significant amount of time, and the edges become too small to notice it anyway, so only add the gradient when it's worthwhile.
      if (edges.length < maxFancyEdgeLimit) {
        context.strokeStyle = context.createLinearGradient(edge.clippedVertices.left!.x, edge.clippedVertices.left!.y,
            edge.clippedVertices.right!.x, edge.clippedVertices.right!.y)
          ..addColorStop(0, '#85f')
          ..addColorStop(1, '#0f0');
      }
      context
        ..beginPath()
        ..moveTo(edge.clippedVertices.left!.x, edge.clippedVertices.left!.y)
        ..lineTo(edge.clippedVertices.right!.x, edge.clippedVertices.right!.y)
        ..stroke();
    }
  }

  void requestRedraw() {
    window.requestAnimationFrame(draw);
  }
}
