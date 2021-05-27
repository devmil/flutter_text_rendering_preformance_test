import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Rendering Performance Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Text Rendering Performance Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _fontSize = 10;
  FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          child: RawKeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKey: (value) {
              if (value.character == '+') {
                setState(() {
                  _fontSize++;
                });
              } else if (value.character == '-') {
                setState(() {
                  _fontSize--;
                });
              }
            },
            child: CustomPaint(
              painter: SomePainter(
                  fontSize: _fontSize,
                  paintFinishedCallback: () {
                    //continous redraw
                    SchedulerBinding.instance?.addPostFrameCallback((_) {
                      setState(() {});
                    });
                  }),
            ),
          ),
        ),
      ),
    );
  }
}

class SomePainter extends CustomPainter {
  static final _textPainterCache = Map<String, TextPainter>();
  static double _cachedFontSize = 0;

  final _random = Random();
  final _chars = List<String>.generate(
      26, (index) => String.fromCharCode('a'.runes.first + index));

  final Function() _paintFinishedCallback;
  final double _fontSize;

  SomePainter(
      {required double fontSize, required Function() paintFinishedCallback})
      : _paintFinishedCallback = paintFinishedCallback,
        _fontSize = fontSize {
    if (_cachedFontSize != fontSize) {
      _textPainterCache.clear();
      _cachedFontSize = fontSize;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.blueGrey;
//    canvas.drawRect(
//        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    double currentY = 0;

    while (currentY < size.height) {
      double currentX = 0;
      double maxHeight = 0;

      while (currentX < size.width) {
        final nextCharIndex = _random.nextInt(_chars.length - 1);
        final nextChar = _chars[nextCharIndex];
        var painter = _textPainterCache[nextChar];
        if (painter == null) {
          final style = TextStyle(
            fontSize: _fontSize,
            color: Colors.white,
          );
          final span = TextSpan(
            text: nextChar,
            style: style,
          );
          painter = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          );
          painter.layout();
          _textPainterCache[nextChar] = painter;
        }

        canvas.drawRect(
            Rect.fromLTWH(currentX, currentY, painter.width, painter.height),
            backgroundPaint);

        painter.paint(canvas, Offset(currentX, currentY));

        currentX += painter.width;
        if (maxHeight < painter.height) {
          maxHeight = painter.height;
        }
      }
      currentY += maxHeight;
    }
    _paintFinishedCallback();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    //always repaint
    return true;
  }
}
