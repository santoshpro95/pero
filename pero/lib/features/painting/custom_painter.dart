/// Provides a widget and an associated controller for simple painting using touch.
library painter;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/widgets.dart' hide Image;

/// A very simple widget that supports drawing using touch.
class Painter extends StatefulWidget {
  final CustomPainterController painterController;

  /// Creates an instance of this widget that operates on top of the supplied [CustomPainterController].
  Painter(CustomPainterController painterController)
      : this.painterController = painterController,
        super(key: new ValueKey<CustomPainterController>(painterController));

  @override
  _PainterState createState() => new _PainterState();
}

class _PainterState extends State<Painter> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.painterController._widgetFinish = _finish;
  }

  Size _finish() {
    setState(() {
      _finished = true;
    });
    return context.size ?? const Size(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = CustomPaint(
      willChange: true,
      painter: _PainterPainter(widget.painterController.pathHistory, repaint: widget.painterController),
    );
    child = ClipRect(child: child);
    if (!_finished) {
      child = GestureDetector(onPanStart: _onPanStart, onPanUpdate: _onPanUpdate, onPanEnd: _onPanEnd, child: child);
    }
    return SizedBox(width: double.infinity, height: double.infinity, child: child);
  }

  void _onPanStart(DragStartDetails start) {
    Offset pos = (context.findRenderObject() as RenderBox).globalToLocal(start.globalPosition);
    widget.painterController.startData = pos;
    widget.painterController.pathHistory.add(pos);
    widget.painterController.refreshPaint();
    widget.painterController.startPaintListener();
  }

  void _onPanUpdate(DragUpdateDetails update) {
    Offset pos = (context.findRenderObject() as RenderBox).globalToLocal(update.globalPosition);
    widget.painterController.updateData = pos;
    widget.painterController.pathHistory.updateCurrent(pos);
    widget.painterController.refreshPaint();
    widget.painterController.updatePaintListener();
  }

  void _onPanEnd(DragEndDetails end) {
    widget.painterController.pathHistory.endCurrent();
    widget.painterController.refreshPaint();
    widget.painterController.endPaintListener();
  }
}

class _PainterPainter extends CustomPainter {
  final PathHistory _path;

  _PainterPainter(this._path, {Listenable? repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    _path.draw(canvas, size);
  }

  @override
  bool shouldRepaint(_PainterPainter oldDelegate) {
    return true;
  }
}

class PathHistory {
  List<MapEntry<Path, Paint>> _paths;
  Paint currentPaint;
  Paint _backgroundPaint;
  bool _inDrag;

  bool get isEmpty => _paths.isEmpty || (_paths.length == 1 && _inDrag);

  PathHistory()
      : _paths = <MapEntry<Path, Paint>>[],
        _inDrag = false,
        _backgroundPaint = new Paint()..blendMode = BlendMode.dstOver,
        currentPaint = new Paint()
          ..color = Colors.black
          ..strokeWidth = 1.0
          ..style = PaintingStyle.fill;

  void setBackgroundColor(Color backgroundColor) {
    _backgroundPaint.color = backgroundColor;
  }

  void undo() {
    if (!_inDrag) {
      _paths.removeLast();
    }
  }

  void clear() {
    if (!_inDrag) {
      _paths.clear();
    }
  }

  void add(Offset startPoint) {
    if (!_inDrag) {
      _inDrag = true;
      Path path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      _paths.add(MapEntry<Path, Paint>(path, currentPaint));
    }
  }

  void updateCurrent(Offset nextPoint) {
    if (_inDrag) {
      Path path = _paths.last.key;
      path.lineTo(nextPoint.dx, nextPoint.dy);
    }
  }

  void endCurrent() {
    _inDrag = false;
  }

  void draw(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    for (MapEntry<Path, Paint> path in _paths) {
      Paint p = path.value;
      canvas.drawPath(path.key, p);
    }
    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height), _backgroundPaint);
    canvas.restore();
  }
}

/// Container that holds the size of a finished drawing and the drawed data as [Picture].
class PictureDetails {
  /// The drawings data as [Picture].
  final Picture picture;

  /// The width of the drawing.
  final int width;

  /// The height of the drawing.
  final int height;

  /// Creates an immutable instance with the given drawing information.
  const PictureDetails(this.picture, this.width, this.height);

  /// Converts the [picture] to an [Image].
  Future<Image> toImage() => picture.toImage(width, height);

  /// Converts the [picture] to a PNG and returns the bytes of the PNG.
  ///
  /// This might throw a [FlutterError], if flutter is not able to convert
  /// the intermediate [Image] to a PNG.
  Future<Uint8List> toPNG() async {
    Image image = await toImage();
    ByteData? data = await image.toByteData(format: ImageByteFormat.png);
    if (data != null) {
      return data.buffer.asUint8List();
    } else {
      throw FlutterError('Flutter failed to convert an Image to bytes!');
    }
  }
}

/// Used with a [Painter] widget to control drawing.
class CustomPainterController extends ChangeNotifier {
  Color _drawColor = const Color.fromARGB(255, 0, 0, 0);
  Color _backgroundColor = const Color.fromARGB(255, 255, 255, 255);
  bool _eraseMode = false;

  double _thickness = 1.0;
  PictureDetails? _cached;
  PathHistory pathHistory;
  final VoidCallback startPaintListener;
  final VoidCallback updatePaintListener;
  final VoidCallback endPaintListener;
  Offset updateData = const Offset(0, 0);
  Offset startData = const Offset(0, 0);
  ValueGetter<Size>? _widgetFinish;

  /// Creates a new instance for the use in a [Painter] widget.
  CustomPainterController(this.startPaintListener, this.updatePaintListener, this.endPaintListener) : pathHistory = PathHistory();

  /// Returns true if nothing has been drawn yet.
  bool get isEmpty => pathHistory.isEmpty;

  /// Returns true if the the [CustomPainterController] is currently in erase mode,
  /// false otherwise.
  bool get eraseMode => _eraseMode;

  /// If set to true, erase mode is enabled, until this is called again with
  /// false to disable erase mode.
  set eraseMode(bool enabled) {
    _eraseMode = enabled;
    _updatePaint();
  }

  /// Retrieves the current draw color.
  Color get drawColor => _drawColor;

  /// Sets the draw color.
  set drawColor(Color color) {
    _drawColor = color;
    _updatePaint();
  }

  /// Retrieves the current background color.
  Color get backgroundColor => _backgroundColor;

  /// Updates the background color.
  set backgroundColor(Color color) {
    _backgroundColor = color;
    _updatePaint();
  }

  /// Returns the current thickness that is used for drawing.
  double get thickness => _thickness;

  /// Sets the draw thickness..
  set thickness(double t) {
    _thickness = t;
    _updatePaint();
  }

  void _updatePaint() {
    Paint paint = Paint();
    if (_eraseMode) {
      paint.blendMode = BlendMode.clear;
      paint.color = const Color.fromARGB(0, 255, 0, 0);
    } else {
      paint.color = drawColor;
      paint.blendMode = BlendMode.srcOver;
    }
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = thickness;
    pathHistory.currentPaint = paint;
    pathHistory.setBackgroundColor(backgroundColor);
    notifyListeners();
  }

  /// Undoes the last drawing action (but not a background color change).
  /// If the picture is already finished, this is a no-op and does nothing.
  void undo() {
    if (!isFinished()) {
      if (!pathHistory.isEmpty){
        pathHistory.undo();
        notifyListeners();
      }
    }
  }

  void refreshPaint() {
    notifyListeners();
  }

  /// Deletes all drawing actions, but does not affect the background.
  /// If the picture is already finished, this is a no-op and does nothing.
  void clear() {
    if (!isFinished()) {
      pathHistory.clear();
      notifyListeners();
    }
  }

  /// Finishes drawing and returns the rendered [PictureDetails] of the drawing.
  /// The drawing is cached and on subsequent calls to this method, the cached
  /// drawing is returned.
  ///
  /// This might throw a [StateError] if this PainterController is not attached
  /// to a widget, or the associated widget's [Size.isEmpty].
  PictureDetails finish() {
    if (!isFinished()) {
      if (_widgetFinish != null) {
        _cached = _render(_widgetFinish!());
      } else {
        throw StateError('Called finish on a PainterController that was not connected to a widget yet!');
      }
    }
    return _cached!;
  }

  PictureDetails _render(Size size) {
    if (size.isEmpty) {
      throw StateError('Tried to render a picture with an invalid size!');
    } else {
      PictureRecorder recorder = PictureRecorder();
      Canvas canvas = Canvas(recorder);
      pathHistory.draw(canvas, size);
      return PictureDetails(recorder.endRecording(), size.width.floor(), size.height.floor());
    }
  }

  /// Returns true if this drawing is finished.
  ///
  /// Trying to modify a finished drawing is a no-op.
  bool isFinished() {
    return _cached != null;
  }
}
