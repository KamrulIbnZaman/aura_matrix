import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MatrixEffectApp());
}

// Main Application Entry
class MatrixEffectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MatrixEffect(),
      ),
    );
  }
}

// Dot Model to hold properties for each dot
class Dot {
  double x, y;
  final double originX, originY;
  double vx, vy;

  Dot(
      {required this.x,
      required this.y,
      required this.originX,
      required this.originY,
      this.vx = 0,
      this.vy = 0});
}

// Main Model to manage the dot positions and interaction effects
class MatrixEffectModel extends ChangeNotifier {
  List<Dot> dots = [];
  Offset touchLocation =
      Offset(-1000, -1000); // Initial touch location offscreen
  double dotSize = 3;
  double dotSpacing = 20;
  double touchBoundingSize = 50;
  double dotInertia = 0.4;
  double touchBoundingSizeSquared = 50 * 50;

  // Initializes dot grid based on screen size
  void initializeDots(Size size) {
    int rows = (size.height / dotSpacing).ceil();
    int columns = (size.width / dotSpacing).ceil();
    dots = List.generate(rows * columns, (index) {
      double x = (index % columns) * dotSpacing;
      double y = (index ~/ columns) * dotSpacing;
      return Dot(x: x, y: y, originX: x, originY: y);
    });
  }

  // Updates dot positions based on touch interactions
  void updateDots() {
    for (var dot in dots) {
      double dx = touchLocation.dx - dot.x;
      double dy = touchLocation.dy - dot.y;
      double distanceSquared = dx * dx + dy * dy;

      if (distanceSquared < touchBoundingSizeSquared) {
        // Optimize with cached square
        double distance = sqrt(distanceSquared);
        double force = (touchBoundingSize - distance) / touchBoundingSize;
        double angle = atan2(dy, dx);
        double targetX = dot.x - cos(angle) * force * 20;
        double targetY = dot.y - sin(angle) * force * 20;

        dot.vx += (targetX - dot.x) * dotInertia;
        dot.vy += (targetY - dot.y) * dotInertia;
      }

      // Applying inertia to the dots
      dot.vx *= 0.9;
      dot.vy *= 0.9;

      // Update dot positions based on calculated velocities
      dot.x += dot.vx;
      dot.y += dot.vy;

      // Slowly move dots back to origin
      double dx2 = dot.originX - dot.x;
      double dy2 = dot.originY - dot.y;
      if (dx2 * dx2 + dy2 * dy2 > 1) {
        dot.x += dx2 * 0.03;
        dot.y += dy2 * 0.03;
      }
    }
    notifyListeners();
  }
}

// Custom Painter for Dot Canvas to render dots based on properties
class DotCanvas extends CustomPainter {
  final List<Dot> dots;
  final double dotSize;
  final Color dotColor;
  final Paint _paint; // Cached paint object

  DotCanvas({required this.dots, required this.dotSize, required this.dotColor})
      : _paint = Paint()..color = dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var dot in dots) {
      canvas.drawCircle(Offset(dot.x, dot.y), dotSize / 2, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Main Matrix Effect widget with GestureDetector for touch interactions
class MatrixEffect extends StatefulWidget {
  @override
  _MatrixEffectState createState() => _MatrixEffectState();
}

class _MatrixEffectState extends State<MatrixEffect>
    with SingleTickerProviderStateMixin {
  late final MatrixEffectModel model;
  late final AnimationController controller;
  final ValueNotifier<Color> dotColor =
      ValueNotifier(Colors.red); // Dynamic dot color

  @override
  void initState() {
    super.initState();
    model = MatrixEffectModel();
    controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 16)) // 60 FPS target
      ..addListener(() {
        model.updateDots();
      })
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          model.touchLocation = details.localPosition;
        });
      },
      onPanEnd: (_) => setState(() {
        model.touchLocation =
            Offset(-1000, -1000); // Reset touch location offscreen
      }),
      child: Container(
        color: Colors.black,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (model.dots.isEmpty) {
              model.initializeDots(
                  Size(constraints.maxWidth, constraints.maxHeight));
            }
            return AnimatedBuilder(
              animation: Listenable.merge([model, dotColor]),
              builder: (context, _) {
                return Stack(
                  children: [
                    CustomPaint(
                      painter: DotCanvas(
                        dots: model.dots,
                        dotSize: model.dotSize,
                        dotColor: dotColor.value, // Apply dynamic color
                      ),
                      child: Container(),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Wrap(
                        spacing: 16,
                        children: [
                          Colors.white,
                          Colors.red,
                          Colors.blue,
                          Colors.green,
                          Colors.pink
                        ]
                            .map((c) => GestureDetector(
                                  onTap: () {
                                    dotColor.value = c;
                                  },
                                  child: Card(
                                    margin: EdgeInsets.only(bottom: 40),
                                    color: c,
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    )
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
