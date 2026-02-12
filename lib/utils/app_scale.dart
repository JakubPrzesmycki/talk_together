import 'dart:math' as math;
import 'package:flutter/widgets.dart';

class AppScale {
  static const double _baseWidth = 412.0;
  static const double _baseHeight = 915.0;

  final double _widthScale;
  final double _heightScale;
  final double _textScale;
  final double _maxSizeFactor;
  final double _maxTextFactor;

  AppScale._(
    this._widthScale,
    this._heightScale,
    this._textScale,
    this._maxSizeFactor,
    this._maxTextFactor,
  );

  factory AppScale.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthScale = size.width / _baseWidth;
    final heightScale = size.height / _baseHeight;
    final textScale = math.min(widthScale, heightScale);
    final shortestSide = math.min(size.width, size.height);
    final isTabletLike = shortestSide >= 600;
    return AppScale._(
      widthScale,
      heightScale,
      textScale,
      isTabletLike ? 1.4 : 1.22,
      isTabletLike ? 1.3 : 1.16,
    );
  }

  double w(double value) => _clamp(value * _widthScale, value, 0.86, _maxSizeFactor);
  double h(double value) => _clamp(value * _heightScale, value, 0.86, _maxSizeFactor);
  double r(double value) => _clamp(value * _textScale, value, 0.9, _maxTextFactor);
  double sp(double value) => _clamp(value * _textScale, value, 0.9, _maxTextFactor);

  static double _clamp(
    double scaled,
    double original,
    double minFactor,
    double maxFactor,
  ) {
    final min = original * minFactor;
    final max = original * maxFactor;
    return scaled.clamp(min, max);
  }
}

