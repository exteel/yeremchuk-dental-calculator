import 'package:flutter/material.dart';

/// Brand color tokens for Yeremchuk Dental, sourced from the Figma design
/// (teal accent, navy dark sections, light/white content backgrounds).
abstract class AppColors {
  // Sampled directly from the Figma export pixels (dominant-color extraction),
  // not eyeballed — keep these exact for 1:1 fidelity to the mockups.
  static const teal = Color(0xFF2EBCB5);
  // Flat fill of the dark-teal decorative diamond/chevron graphic (e.g. the
  // shape behind the "Стоматологічний туризм" panel). Pixel-sampled: modal
  // value (27,70,68)/#1B4644 across two independent slices (design_5 p04,
  // категорія p06), >99% pixel consensus in both — a genuine flat color,
  // not a gradient or an alpha variant of `teal`.
  static const tealDark = Color(0xFF1B4644);
  static const tealSoft = Color(0xFFD7EEEE);

  static const navy = Color(0xFF202C3D);
  // The Figma export renders this panel (the "Знайдемо рішення" CTA card
  // background) with a subtle vertical gradient, not a flat fill — measured
  // ~#2E3F5A at the top down to ~#253347 at the bottom, consistently across
  // two independent instances (design_5 p06, про_нас p05). This hex is the
  // pixel-count-weighted average color across both panels (~(42,58,81)).
  // For 1:1 fidelity at a use site, prefer a LinearGradient between the two
  // measured endpoints over this flat approximation.
  static const navySoft = Color(0xFF2A3A51);

  static const ink = Color(0xFF1E2939);
  static const inkSoft = Color(0xFF4B5A63);
  static const muted = Color(0xFF7C8B91);

  static const paper = Color(0xFFFFFFFF);
  static const paperDim = Color(0xFFF5F7F8);
  static const cardBg = Color(0xFFE6E8E9);

  static const line = Color(0xFFD7E0DF);

  static const danger = Color(0xFFC0392B);
  static const amber = Color(0xFF9A6A26);
}
