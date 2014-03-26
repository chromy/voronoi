/*
 * 
 */

library demo;

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:diagram/voronoi.dart';

void main() {
  print("Starting...");
  CanvasElement canvas = querySelector("#area");
  scheduleMicrotask(new VoronoiDemo(canvas).start);
}

Element notes = querySelector("#fps");
num fpsAverage;

/// Display the animation's FPS in a div.
void showFps(num fps) {
  if (fpsAverage == null) fpsAverage = fps;
  fpsAverage = fps * 0.05 + fpsAverage * 0.95;
  notes.text = "${fpsAverage.round()} fps";
}

class VoronoiDemo {
  CanvasElement canvas;

  num width;
  num height;

  Voronoi voronoi;

  num renderTime;

  VoronoiDemo(this.canvas);

  // Initialize the diagram and start the simulation.
  void start() {
    // Measure the canvas element.
    Rectangle rect = canvas.parent.client;
    width = rect.width;
    height = rect.height;
    canvas.width = width;
    
    // Create random points.
    var rng = new Random();
    Point randomPoint() => new Point(rng.nextInt(width), rng.nextInt(height));
    var randomPoints = new List.generate(400, (i) => randomPoint());
    var randomUniquePoints = new Set.from(randomPoints);
    
    // Compute the diagram.
    voronoi = new Voronoi(new List.from(randomUniquePoints), null, new Rectangle(0, 0, width, height));
    
    // Draw diagram.
    requestRedraw();
  }

  void draw(num _) {
    // Update FPS
    num time = new DateTime.now().millisecondsSinceEpoch;
    if (renderTime != null) showFps(1000 / (time - renderTime));
    renderTime = time;

    // Draw 
    var context = canvas.context2D;
    drawBackground(context);
    drawLines(context);
    drawSites(context);
    requestRedraw();
  }
  
  /**
   * Clear the background to white.
   */
  void drawBackground(CanvasRenderingContext2D context) {
    context.clearRect(0, 0, width, height);
  }

  /**
   * Draw the sites of the cells on context.
   */
  void drawSites(CanvasRenderingContext2D context) {
    for (var site in voronoi.siteCoords()) {
      context
        ..fillStyle = '#000'
        ..beginPath()
        ..arc(site.x, site.y, 1, 0, PI*2, true)
        ..closePath()
        ..fill();
    }
  }
  
  /**
   * Draw the edges of the cells on context.
   */
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
      lingrad
        ..addColorStop(0, '#f00')
        ..addColorStop(1, '#0f0');
        
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