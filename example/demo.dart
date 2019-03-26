library demo;

import 'dart:html';
import 'dart:math';

import 'package:voronoi/voronoi.dart';

final InputElement slider = querySelector("#slider");
final InputElement button = querySelector("#button");
final CanvasElement canvas = querySelector("#area");
final Element notes = querySelector("#notes");
final VoronoiDemo demo =
    new VoronoiDemo(canvas, 10, (new Random()).nextInt(100000));
num fpsAverage;

void main() {
  demo.start();
  slider.onChange.listen((e) => update());
  button.onClick.listen((e) => randomiseSeed());
  update();
}

void update() {
  demo.sites = int.parse(slider.value);
  demo.recompute();
  notes.text = "${demo.sites} sites";
}

void randomiseSeed() {
  demo.seed = (new Random()).nextInt(100000);
  update();
}

class VoronoiDemo {
  CanvasElement canvas;

  num width;
  num height;
  int sites;
  int seed;

  Voronoi voronoi;

  num renderTime;

  VoronoiDemo(this.canvas, this.sites, this.seed);

  // Initialize the diagram.
  void start() {
    // Measure the canvas element.
    Rectangle rect = canvas.parent.client;
    width = rect.width;
    height = rect.height;
    canvas.width = width;

    // Compute diagram.
    recompute();

    // Draw diagram.
    requestRedraw();
  }

  void recompute() {
    // Create random points.
    var rng = new Random(seed);
    Point randomPoint() => new Point(rng.nextInt(width), rng.nextInt(height));
    var randomPoints = new List.generate(sites, (i) => randomPoint());
    var randomUniquePoints = new Set.from(randomPoints);

    // Compute the diagram.
    voronoi = new Voronoi(new List.from(randomUniquePoints), null,
        new Rectangle(0, 0, width, height));
  }

  void draw(num _) {
    // Draw
    var context = canvas.context2D;
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
    for (var site in voronoi.siteCoords()) {
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
    var edges = voronoi.edges.where((x) => x.visible);

    for (var edge in edges) {
      // Create gradient
      var lingrad = context.createLinearGradient(
          edge.leftClippedEnd.x,
          edge.leftClippedEnd.y,
          edge.rightClippedEnd.x,
          edge.rightClippedEnd.y);
      lingrad..addColorStop(0, '#f00')..addColorStop(1, '#0f0');

      context
        ..strokeStyle = lingrad
        ..lineWidth = 1
        ..beginPath()
        ..moveTo(edge.leftClippedEnd.x, edge.leftClippedEnd.y)
        ..lineTo(edge.rightClippedEnd.x, edge.rightClippedEnd.y)
        ..stroke();
    }
  }

  void requestRedraw() {
    window.requestAnimationFrame(draw);
  }
}
