// Gera assets/icons/app_icon_fg.png — versão FOREGROUND pro ícone adaptativo
// Android: fundo transparente + lâmpada menor/centralizada (margem de safe zone,
// o sistema corta ~25% das bordas em máscaras circulares).
// Uso: dart run tool/gen_icon_fg.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart';

void main() {
  const s = 1024;
  final img = Image(width: s, height: s, numChannels: 4);
  // transparente (não preenche fundo)

  final amber = ColorRgb8(0xF5, 0xA6, 0x23);
  final amberDark = ColorRgb8(0xC4, 0x7D, 0x0E);
  final amberLight = ColorRgb8(0xFF, 0xE4, 0xB5);
  final filament = ColorRgb8(0xC4, 0x7D, 0x0E);

  // tudo numa escala 0.62 e centralizado pra caber na safe zone (~66%)
  const scale = 0.62;
  const ox = 512; // centro original x
  const oy = 470; // centro original y do bulbo
  // novo centro do conjunto fica no meio do canvas
  double tx(double x) => 512 + (x - ox) * scale;
  double ty(double y) => 512 + (y - oy) * scale;
  int ts(num v) => (v * scale).round();

  void ray(double x1, double y1, double x2, double y2) {
    drawLine(img, x1: tx(x1).round(), y1: ty(y1).round(),
        x2: tx(x2).round(), y2: ty(y2).round(),
        color: amber, thickness: ts(34), antialias: true);
  }
  ray(512, 120, 512, 220);
  ray(245, 230, 316, 301);
  ray(779, 230, 708, 301);
  ray(150, 470, 250, 470);
  ray(874, 470, 774, 470);

  final cx = tx(512).round();
  final cy = ty(470).round();
  final r = ts(190);
  fillCircle(img, x: cx, y: cy, radius: r, color: amberLight, antialias: true);
  for (var t = 0; t <= 10; t++) {
    drawCircle(img, x: cx, y: cy, radius: r - t, color: amber, antialias: true);
  }

  double? px, py;
  for (var i = 0; i <= 60; i++) {
    final fx = tx(452 + (120 * i / 60));
    final fy = ty(470 + 50 * math.sin((i / 60) * 2 * math.pi));
    if (px != null && py != null) {
      drawLine(img, x1: px.round(), y1: py.round(), x2: fx.round(), y2: fy.round(),
          color: filament, thickness: ts(16), antialias: true);
    }
    px = fx; py = fy;
  }

  fillRect(img, x1: tx(437).round(), y1: ty(648).round(), x2: tx(587).round(), y2: ty(688).round(), color: amber, radius: ts(14));
  fillRect(img, x1: tx(452).round(), y1: ty(694).round(), x2: tx(572).round(), y2: ty(728).round(), color: amberDark, radius: ts(12));
  fillRect(img, x1: tx(470).round(), y1: ty(734).round(), x2: tx(554).round(), y2: ty(774).round(), color: ColorRgb8(0x8A,0x6A,0x1A), radius: ts(14));

  File('assets/icons/app_icon_fg.png').writeAsBytesSync(encodePng(img));
  stdout.writeln('OK: assets/icons/app_icon_fg.png');
}
