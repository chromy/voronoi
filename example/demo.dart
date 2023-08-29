library demo;

import 'dart:html';
import 'dart:math';

import 'package:voronoi/voronoi.dart';

final InputElement slider = querySelector("#slider")! as InputElement;
final InputElement button = querySelector("#button")! as InputElement;
final CanvasElement canvas = querySelector("#area")! as CanvasElement;
final Element notes = querySelector("#notes")!;
final VoronoiDemo demo = VoronoiDemo(canvas, 10, Random().nextInt(100000));
num fpsAverage = 0;

void main() {
  demo.start();
  slider.onChange.listen((Event e) => update());
  button.onClick.listen((MouseEvent e) => randomiseSeed());
  update();
}

void update() {
  demo.sites = int.parse(slider.value ?? "");
  demo.recompute();
  notes.text = "${demo.sites} sites";
}

void randomiseSeed() {
  demo.seed = Random().nextInt(100000);
  update();
}

class VoronoiDemo {
  CanvasElement canvas;

  num width = 100;
  num height = 100;
  int sites;
  int seed;

  late Voronoi voronoi;

  num renderTime = 0;

  VoronoiDemo(this.canvas, this.sites, this.seed);

  // Initialize the diagram.
  void start() {
    // Measure the canvas element.
    final Rectangle<num> rect = canvas.parent!.client;
    width = rect.width;
    height = rect.height;
    canvas.width = width as int?;

    // Compute diagram.
    recompute();

    // Draw diagram.
    requestRedraw();
  }

  void recompute() {
    // Create random points.
    final Random rng = Random(seed);
    Point<int> randomPoint() => Point<int>(rng.nextInt(width.floor()), rng.nextInt(height.floor()));
    final List<Point<num>> randomPoints = List<Point<num>>.generate(sites, (int i) => randomPoint());
    final Set<Point<num>> randomUniquePoints = Set<Point<num>>.from(randomPoints);

    // Compute the diagram.
    voronoi = Voronoi(
        List<Point<num>>.from(randomUniquePoints), List<int>.filled(randomUniquePoints.length, 0), Rectangle<num>(0, 0, width, height));
  }

  void draw(num _) {
    // Draw
    final CanvasRenderingContext2D context = canvas.context2D;
    drawBackground(context);
    drawLines(context);
    drawSites(context);
    requestRedraw();
  }

  /// Clear the background to white.
  void drawBackground(CanvasRenderingContext2D context) {
    context.clearRect(0, 0, width, height);
  }

  /// Draw the sites of the cells on context.
  void drawSites(CanvasRenderingContext2D context) {
    for (final Point<num> site in voronoi.siteCoords()) {
      context
        ..fillStyle = '#000'
        ..beginPath()
        ..arc(site.x, site.y, 1, 0, pi * 2, true)
        ..closePath()
        ..fill();
    }
  }

  /// Draw the edges of the cells on context.
  void drawLines(CanvasRenderingContext2D context) {
    // Don't consider edges which have been clipped completely away.
    final Iterable<Edge> edges = voronoi.edges.where((Edge x) => x.visible);

    for (final Edge edge in edges) {
      // Create gradient
      final CanvasGradient lingrad = context.createLinearGradient(
          edge.leftClippedEnd!.x,
          edge.leftClippedEnd!.y,
          edge.rightClippedEnd!.x,
          edge.rightClippedEnd!.y)
        ..addColorStop(0, '#f00')..addColorStop(1, '#0f0');

      context
        ..strokeStyle = lingrad
        ..lineWidth = 1
        ..beginPath()
        ..moveTo(edge.leftClippedEnd!.x, edge.leftClippedEnd!.y)
        ..lineTo(edge.rightClippedEnd!.x, edge.rightClippedEnd!.y)
        ..stroke();
    }
  }

  void requestRedraw() {
    window.requestAnimationFrame(draw);
  }
}
