// Gera assets/icons/app_icon.png (1024x1024) — ícone do app Raitõ:
// lâmpada âmbar com raios sobre fundo escuro + inicial R.
// Uso: dart run tool/gen_icon.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart';

void main() {
  const s = 1024;
  final img = Image(width: s, height: s, numChannels: 4);

  // Paleta da marca
  final obsidian = ColorRgb8(0x11, 0x11, 0x11);
  final amber = ColorRgb8(0xF5, 0xA6, 0x23);
  final amberDark = ColorRgb8(0xC4, 0x7D, 0x0E);
  final amberLight = ColorRgb8(0xFF, 0xE4, 0xB5);
  final filament = ColorRgb8(0xC4, 0x7D, 0x0E);

  // Fundo
  fill(img, color: obsidian);

  const cx = 512;
  const cy = 470;
  const r = 190;

  // Raios (linhas grossas saindo do bulbo)
  void ray(int x1, int y1, int x2, int y2) {
    drawLine(img, x1: x1, y1: y1, x2: x2, y2: y2,
        color: amber, thickness: 34, antialias: true);
  }
  ray(512, 120, 512, 220);
  ray(245, 230, 316, 301);
  ray(779, 230, 708, 301);
  ray(150, 470, 250, 470);
  ray(874, 470, 774, 470);

  // Bulbo
  fillCircle(img, x: cx, y: cy, radius: r, color: amberLight, antialias: true);
  drawCircle(img, x: cx, y: cy, radius: r, color: amber, antialias: true);
  // engrossa a borda do bulbo
  for (var t = 1; t <= 10; t++) {
    drawCircle(img, x: cx, y: cy, radius: r - t, color: amber, antialias: true);
  }

  // Filamento estilizado (curva senoidal dentro do bulbo)
  double? prevx, prevy;
  for (var i = 0; i <= 60; i++) {
    final fx = 452 + (120 * i / 60);
    final fy = cy + 50 * math.sin((i / 60) * 2 * math.pi);
    if (prevx != null && prevy != null) {
      drawLine(img,
          x1: prevx.round(), y1: prevy.round(),
          x2: fx.round(), y2: fy.round(),
          color: filament, thickness: 16, antialias: true);
    }
    prevx = fx;
    prevy = fy;
  }

  // Base / rosca da lâmpada (retângulos arredondados empilhados)
  fillRect(img, x1: 437, y1: 648, x2: 587, y2: 688, color: amber, radius: 14);
  fillRect(img, x1: 452, y1: 694, x2: 572, y2: 728, color: amberDark, radius: 12);
  fillRect(img, x1: 470, y1: 734, x2: 554, y2: 774,
      color: ColorRgb8(0x8A, 0x6A, 0x1A), radius: 14);

  File('assets/icons/app_icon.png').writeAsBytesSync(encodePng(img));
  stdout.writeln('OK: assets/icons/app_icon.png (${s}x$s)');
}
