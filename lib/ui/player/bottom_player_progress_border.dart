import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BottomPlayerProgressBorder extends StatelessWidget {
  static const double _borderRadius = 16;
  static const double _strokeWidth = 1.5;

  final Widget child;

  const BottomPlayerProgressBorder({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBloc>();

    return StreamBuilder<PlayerPlaybackProgress>(
      stream: playerBloc.playbackProgressStream,
      initialData: const PlayerPlaybackProgress(
        position: Duration.zero,
        duration: Duration.zero,
      ),
      builder: (context, snapshot) {
        final playbackProgress =
            snapshot.data ??
            const PlayerPlaybackProgress(
              position: Duration.zero,
              duration: Duration.zero,
            );

        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            border: _BottomPlayerPlaybackBoxBorder(
              progress: _progressValue(playbackProgress),
              playedSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: _strokeWidth,
                strokeAlign: BorderSide.strokeAlignCenter,
              ),
              remainingSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer.withValues(alpha: 0.18),
                width: _strokeWidth,
                strokeAlign: BorderSide.strokeAlignCenter,
              ),
            ),
          ),
          child: child,
        );
      },
    );
  }

  double _progressValue(PlayerPlaybackProgress playbackProgress) {
    final durationMilliseconds = playbackProgress.duration.inMilliseconds;
    if (durationMilliseconds <= 0) {
      return 0;
    }

    final positionMilliseconds = playbackProgress.position.inMilliseconds.clamp(
      0,
      durationMilliseconds,
    );

    return positionMilliseconds / durationMilliseconds;
  }
}

class _BottomPlayerPlaybackBoxBorder extends BoxBorder {
  final BorderSide playedSide;
  final BorderSide remainingSide;
  final double progress;

  const _BottomPlayerPlaybackBoxBorder({
    required this.playedSide,
    required this.remainingSide,
    required this.progress,
  });

  @override
  BorderSide get top => remainingSide;

  @override
  BorderSide get bottom => remainingSide;

  BorderSide get left => remainingSide;

  BorderSide get right => remainingSide;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  bool get isUniform => false;

  @override
  ShapeBorder scale(double t) {
    return _BottomPlayerPlaybackBoxBorder(
      playedSide: playedSide.scale(t),
      remainingSide: remainingSide.scale(t),
      progress: progress,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (shape == BoxShape.circle) {
      throw UnsupportedError(
        '_BottomPlayerPlaybackBoxBorder supports only rectangular shapes.',
      );
    }

    if (remainingSide.style == BorderStyle.none ||
        remainingSide.width == 0 ||
        remainingSide.color.a == 0) {
      return;
    }

    final resolvedBorderRadius = (borderRadius ?? BorderRadius.zero).resolve(
      textDirection,
    );
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final borderPath = _createClockwiseBorderPath(
      rect: rect,
      borderRadius: resolvedBorderRadius.toRRect(rect),
    );
    final borderMetric = borderPath.computeMetrics().singleOrNull;
    if (borderMetric == null) {
      return;
    }

    canvas.drawPath(borderPath, _createPaint(remainingSide, roundCap: false));

    if (normalizedProgress == 0 ||
        playedSide.style == BorderStyle.none ||
        playedSide.width == 0 ||
        playedSide.color.a == 0) {
      return;
    }

    final playedPath = borderMetric.extractPath(
      0,
      borderMetric.length * normalizedProgress,
    );
    canvas.drawPath(playedPath, _createPaint(playedSide, roundCap: true));
  }

  Paint _createPaint(BorderSide side, {required bool roundCap}) {
    return side.toPaint()
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = roundCap ? StrokeCap.round : StrokeCap.butt;
  }

  Path _createClockwiseBorderPath({
    required Rect rect,
    required RRect borderRadius,
  }) {
    final path = Path()..moveTo(rect.center.dx, rect.top);

    path.lineTo(rect.right - borderRadius.trRadiusX, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + borderRadius.trRadiusY),
      radius: Radius.elliptical(borderRadius.trRadiusX, borderRadius.trRadiusY),
      clockwise: true,
    );
    path.lineTo(rect.right, rect.bottom - borderRadius.brRadiusY);
    path.arcToPoint(
      Offset(rect.right - borderRadius.brRadiusX, rect.bottom),
      radius: Radius.elliptical(borderRadius.brRadiusX, borderRadius.brRadiusY),
      clockwise: true,
    );
    path.lineTo(rect.left + borderRadius.blRadiusX, rect.bottom);
    path.arcToPoint(
      Offset(rect.left, rect.bottom - borderRadius.blRadiusY),
      radius: Radius.elliptical(borderRadius.blRadiusX, borderRadius.blRadiusY),
      clockwise: true,
    );
    path.lineTo(rect.left, rect.top + borderRadius.tlRadiusY);
    path.arcToPoint(
      Offset(rect.left + borderRadius.tlRadiusX, rect.top),
      radius: Radius.elliptical(borderRadius.tlRadiusX, borderRadius.tlRadiusY),
      clockwise: true,
    );
    path.lineTo(rect.center.dx, rect.top);

    return path;
  }
}
