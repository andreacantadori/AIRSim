// signal_graph_view.dart
import 'package:flutter/material.dart';
import 'common_defines.dart';

class SignalGraphView extends StatefulWidget {
  final List<double> signal;
  final List<int> detection;
  final List<int> algorithm;
  final bool isCrossing;
  final double sensitivity;
  final int minOutputPulseDuration;
  final int maxOutputPulseDuration;
  final Function(bool) onDetectionChanged;
  final Function(int) onAlgorithmOutput;

  const SignalGraphView({
    Key? key,
    required this.signal,
    required this.detection,
    required this.algorithm,
    required this.isCrossing,
    required this.sensitivity,
    required this.minOutputPulseDuration,
    required this.maxOutputPulseDuration,
    required this.onDetectionChanged,
    required this.onAlgorithmOutput,
  }) : super(key: key);

  @override
  _SignalGraphViewState createState() => _SignalGraphViewState();
}

class _SignalGraphViewState extends State<SignalGraphView> {
  bool _isDetection = false;
  int _startupTimer = 1000;
  
  // Algorithm state variables
  int _state = 0;
  int _s0 = 0, _si = 0;
  int _tMinDetTime = 0;
  int _tMaxDetTime = 0;
  int _tSetOffset = 0;
  int _avg = 0;
  final int _tavg = 20000; // ms

  void processAlgorithm() {
    if (widget.signal.isEmpty) return;

    if (_startupTimer > 0) {
      _startupTimer -= CommonDefines.SAMPLING_PERIOD;
      _output(0);
    } else {
      _si = _getSignalFromEnd(0);
      
      switch (_state) {
        case 0:
          _output(0);
          _s0 = _si;
          _tSetOffset = 0;
          _avg = 0;
          _state = 10;
          debugPrint('Moved to state $_state');
          break;
          
        case 10:
          _output(0);
          if ((_si - _s0).abs() > widget.sensitivity) {
            _tMinDetTime = 0;
            _tMaxDetTime = 0;
            _state = 20;
            debugPrint('Moved to state $_state');
          } else {
            _tSetOffset += CommonDefines.SAMPLING_PERIOD;
            _avg += _si;
            if (_tSetOffset > _tavg) {
              _avg ~/= (_tavg / CommonDefines.SAMPLING_PERIOD);
              _s0 = _avg;
              _tSetOffset = 0;
              debugPrint('New offset set to $_s0');
            }
          }
          break;
          
        case 20:
          _output(1);
          if ((_si - _s0).abs() > widget.sensitivity) {
            _tMaxDetTime += CommonDefines.SAMPLING_PERIOD;
            if (widget.maxOutputPulseDuration > 0) {
              if (_tMaxDetTime > widget.maxOutputPulseDuration * 1000) {
                _state = 0;
                debugPrint('Moved to state $_state');
              }
            }
          } else {
            _tMinDetTime += CommonDefines.SAMPLING_PERIOD;
            if (_tMinDetTime > widget.minOutputPulseDuration * 1000) {
              _state = 10;
              debugPrint('Moved to state $_state');
            }
          }
          break;
      }
    }
  }

  void _output(int out) {
    // Send algorithm output to parent widget
    _isDetection = out != 0;
    widget.onDetectionChanged(_isDetection);
    widget.onAlgorithmOutput(out);
  }

  int _getSignalFromEnd(int n) {
    if (widget.signal.isEmpty) return 0;
    int index = widget.signal.length - n - 1;
    if (index < 0) index = 0;
    return widget.signal[index].round();
  }

  @override
  Widget build(BuildContext context) {
    // Process algorithm on each build (when new data arrives)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      processAlgorithm();
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
      ),
      child: CustomPaint(
        painter: SignalGraphPainter(
          signal: widget.signal,
          detection: widget.detection,
          algorithm: widget.algorithm,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class SignalGraphPainter extends CustomPainter {
  final List<double> signal;
  final List<int> detection;
  final List<int> algorithm;

  SignalGraphPainter({
    required this.signal,
    required this.detection,
    required this.algorithm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (signal.length < 2) return;

    // Fill background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    _drawGrid(canvas, size);
    _drawAxisLabels(canvas, size);
    _drawBaseline(canvas, size);
    _drawSignalLine(canvas, size);
    _drawDetectionLine(canvas, size);
    _drawAlgorithmLine(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    for (int i = 0; i <= CommonDefines.N_HORIZONTAL_GRID_LINES; i++) {
      double y = size.height * i / CommonDefines.N_HORIZONTAL_GRID_LINES;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertical grid lines
    for (int i = 0; i <= CommonDefines.N_VERTICAL_GRID_LINES; i++) {
      double x = size.width * i / CommonDefines.N_VERTICAL_GRID_LINES;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 10,
    );

    // Y-axis labels
    for (int i = 0; i <= 10; i++) {
      double value = CommonDefines.GRAPH_MIN_VALUE + 
          (CommonDefines.GRAPH_MAX_VALUE - CommonDefines.GRAPH_MIN_VALUE) * i / 10.0;
      double y = size.height * (10 - i) / 10.0; // Flip Y coordinate
      
      final textPainter = TextPainter(
        text: TextSpan(text: value.round().toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }
  }

  void _drawBaseline(Canvas canvas, Size size) {
    final baselinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    double value = CommonDefines.AIR_OFFSET;
    double y = size.height * (1 - (value - CommonDefines.GRAPH_MIN_VALUE) / 
        (CommonDefines.GRAPH_MAX_VALUE - CommonDefines.GRAPH_MIN_VALUE));

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      baselinePaint,
    );
  }

  void _drawSignalLine(Canvas canvas, Size size) {
    if (signal.isEmpty) return;

    final signalPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    for (int i = 0; i < signal.length; i++) {
      double value = signal[i];
      double x = size.width * i / signal.length;
      double y = size.height * (1 - (value - CommonDefines.GRAPH_MIN_VALUE) / 
          (CommonDefines.GRAPH_MAX_VALUE - CommonDefines.GRAPH_MIN_VALUE));
      
      // Clamp y to bounds
      y = y.clamp(0.0, size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, signalPaint);
  }

  void _drawDetectionLine(Canvas canvas, Size size) {
    if (detection.isEmpty) return;

    final detectionPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    for (int i = 0; i < detection.length; i++) {
      double value = detection[i] * CommonDefines.AMPLI_DETECTION + 
          CommonDefines.OFFSET_DETECTION;
      double x = size.width * i / detection.length;
      double y = size.height * (1 - (value - CommonDefines.GRAPH_MIN_VALUE) / 
          (CommonDefines.GRAPH_MAX_VALUE - CommonDefines.GRAPH_MIN_VALUE));
      
      // Clamp y to bounds
      y = y.clamp(0.0, size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, detectionPaint);
  }

  void _drawAlgorithmLine(Canvas canvas, Size size) {
    if (algorithm.isEmpty) return;

    final algorithmPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    for (int i = 0; i < algorithm.length; i++) {
      double value = algorithm[i] * CommonDefines.AMPLI_DETECTION + 
          CommonDefines.OFFSET_ALGORITHM;
      double x = size.width * i / algorithm.length;
      double y = size.height * (1 - (value - CommonDefines.GRAPH_MIN_VALUE) / 
          (CommonDefines.GRAPH_MAX_VALUE - CommonDefines.GRAPH_MIN_VALUE));
      
      // Clamp y to bounds
      y = y.clamp(0.0, size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, algorithmPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}