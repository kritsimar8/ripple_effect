import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Ripple Shader Demo',
        style: TextStyle(
          color: Colors.white
        ),
        ),
        backgroundColor: Colors.black,
        ),
        body: const ShaderWidget(),
      ),
    );
  }
}

class ShaderWidget extends StatefulWidget {
  const ShaderWidget({super.key});

  @override
  State<ShaderWidget> createState() => _ShaderWidgetState();
}

class _ShaderWidgetState extends State<ShaderWidget>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? shader;
  ui.Image? inputImage;
  Offset mousePosition = Offset.zero;
  late AnimationController _controller;
  double iTime = 0.0;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _loadImage();
    // Initialize AnimationController for iTime
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000), // Long duration for continuous animation
    )..addListener(() {
        setState(() {
          iTime = _controller.value * 1000; // Update iTime based on animation
        });
      });
    _controller.forward();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('lib/shaders/ripple_effect.frag');
    setState(() {
      shader = program.fragmentShader();
    });
  }

  Future<void> _loadImage() async {
    // Load an image for iChannel0
    final imageProvider = AssetImage('assets/pg-coral.png');
    final completer = Completer<ui.Image>();
    final imageStream = imageProvider.resolve(ImageConfiguration());
    ImageStreamListener? imageStreamListener;
    imageStreamListener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
        imageStream.removeListener(imageStreamListener!);
      },
      onError: (exception, stackTrace) {
        completer.completeError(exception, stackTrace);
      },
    );
    imageStream.addListener(imageStreamListener);
    inputImage = await completer.future;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (shader == null || inputImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            mousePosition = details.localPosition;
          });
        },
        onTapDown: (details) {
          setState(() {
            mousePosition = details.localPosition;
            _controller.reset(); // Reset time on tap to restart ripple
            _controller.forward();
          });
        },
        child: CustomPaint(
          painter: ShaderPainter(
            shader: shader!,
            image: inputImage!,
            size: const Size(300, 300), // Adjust size as needed
            mousePosition: mousePosition,
            time: iTime,
          ),
          size: const Size(300, 300),
        ),
      ),
    );
  }

  @override
  void dispose() {
    shader?.dispose();
    inputImage?.dispose();
    _controller.dispose();
    super.dispose();
  }
}

class ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image image;
  final Size size;
  final Offset mousePosition;
  final double time;

  ShaderPainter({
    required this.shader,
    required this.image,
    required this.size,
    required this.mousePosition,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set shader uniforms
    shader
      ..setFloat(0, size.width) // iResolution.x
      ..setFloat(1, size.height) // iResolution.y
      ..setFloat(2, mousePosition.dx) // iMouse.x
      ..setFloat(3, mousePosition.dy) // iMouse.y
      ..setFloat(4, time) // iTime
      ..setImageSampler(0, image); // iChannel0

    final paint = Paint()..shader = shader;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) {
    return oldDelegate.mousePosition != mousePosition ||
        oldDelegate.time != time ||
        oldDelegate.size != size ||
        oldDelegate.image != image;
  }
}