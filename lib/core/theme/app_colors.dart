import 'package:flutter/material.dart';

/// NavNest cohesive color palette.
/// Visual direction: Sage Green, Deep Forest Green, Warm Cream, Ivory, Soft Pink, and Amber.
/// Plus Moonlit Forest Dark Mode.
class AppColors {
  AppColors._();

  // Canvas and Backgrounds (Light)
  static const Color ivoryCanvas = Color(0xFFF9F7F1);
  static const Color warmCream = Color(0xFFF2EEE2);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFFBF8F1);

  // Canvas and Backgrounds (Moonlit Forest Dark Mode)
  static const Color darkCanvas = Color(0xFF0C1911);
  static const Color darkSurface = Color(0xFF13251B);
  static const Color darkCard = Color(0xFF182D21);
  static const Color darkElevated = Color(0xFF1F372A);
  static const Color darkBorder = Color(0xFF264232);
  static const Color darkTextPrimary = Color(0xFFE8F0EA);
  static const Color darkTextSecondary = Color(0xFFA6BAAE);
  static const Color darkTextMuted = Color(0xFF6F8778);

  // Forest Greens (Primary)
  static const Color deepForest = Color(0xFF1B3B2B);
  static const Color deepForestDark = Color(0xFF12271D);
  static const Color forestPine = Color(0xFF244D38);
  static const Color forestEmerald = Color(0xFF2D6A4F);
  static const Color sageGreen = Color(0xFF5E8B68);
  static const Color sageLight = Color(0xFF86A88E);
  static const Color sageTint = Color(0xFFE5EEE6);
  static const Color sageBorder = Color(0xFFC8DACB);

  // Warmth & Gamification (Amber / Gold)
  static const Color amberHoney = Color(0xFFDF8A36);
  static const Color amberWarm = Color(0xFFEAA84F);
  static const Color amberSoft = Color(0xFFFFF2DF);
  static const Color coinGold = Color(0xFFE5A93C);

  // NavBloom Flora (Cherry Blossom & Accents)
  static const Color cherryPink = Color(0xFFF48B9E);
  static const Color softRose = Color(0xFFD97D81);
  static const Color petalPink = Color(0xFFF7D9DC);
  static const Color petalLight = Color(0xFFFDF0F2);
  static const Color morningSky = Color(0xFFE8F2F6);
  static const Color skyBlue = Color(0xFF5B92B0);
  static const Color moonlightBlue = Color(0xFF1E3545);

  // Status & Urgency Colors
  static const Color urgentRed = Color(0xFFD64D4D);
  static const Color urgentRedLight = Color(0xFFFCE8E8);
  static const Color warningAmber = Color(0xFFE6953B);
  static const Color warningAmberLight = Color(0xFFFEF3E4);
  static const Color safeGreen = Color(0xFF438A5E);
  static const Color safeGreenLight = Color(0xFFE8F4EC);
  static const Color revisionPurple = Color(0xFF8170B5);
  static const Color revisionPurpleLight = Color(0xFFF1EEF9);
  static const Color restudyCoral = Color(0xFFDC6549);
  static const Color restudyCoralLight = Color(0xFFFCEEEA);

  // Subject Accent Colors (Matching Mockup)
  static const Color subjectPhysics = Color(0xFFE8833A);
  static const Color subjectChemistry = Color(0xFFDE5D83);
  static const Color subjectMaths = Color(0xFF3B8A6E);
  static const Color subjectBiology = Color(0xFF5E9C76);
  static const Color subjectEnglish = Color(0xFFD49B3E);
  static const Color subjectSchool = Color(0xFF4B88B4);

  // Text and Typography (Light)
  static const Color textPrimary = Color(0xFF1B261F);
  static const Color textSecondary = Color(0xFF4D5E53);
  static const Color textMuted = Color(0xFF7A8C81);
  static const Color textLight = Color(0xFFA6B5AB);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFE6E1D4);
  static const Color borderStrong = Color(0xFFD4CEC0);
  static const Color divider = Color(0xFFECE7DA);
}

/// Cohesive gradients for premium glass cards, hero banners, and atmospheric portals
class AppGradients {
  AppGradients._();

  static const LinearGradient forestAura = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E4331), Color(0xFF0D1D14)],
  );

  static const LinearGradient radiantEmerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2ECC71), Color(0xFF1A6B44)],
  );

  static const LinearGradient goldenHarvest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient magicalPortal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF08120B), Color(0xFF12281C), Color(0xFF060F09)],
  );

  static const LinearGradient glassSurfaceDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x332D6A4F), Color(0x1A13251B)],
  );

  static const LinearGradient heroCardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF183827), Color(0xFF10241A)],
  );
}

/// Dawn Design System — Warm, fresh, dewy morning nature.
class DawnColors {
  DawnColors._();

  static const Color canvas = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF7F4EC);
  static const Color surfaceVariant = Color(0xFFF2EEE4);
  static const Color border = Color(0xFFE8E2D5);
  static const Color borderSubtle = Color(0xFFF0EBE1);

  static const Color primary = Color(0xFF1B3B2B);
  static const Color primaryLight = Color(0xFF2D6A4F);
  static const Color primaryContainer = Color(0xFFE6EFE8);
  static const Color secondary = Color(0xFF5E8B68);
  static const Color secondaryContainer = Color(0xFFEFF5F0);

  static const Color accent = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFF59E0B);
  static const Color accentContainer = Color(0xFFFEF3C7);

  static const Color textPrimary = Color(0xFF1A241E);
  static const Color textSecondary = Color(0xFF4A5A50);
  static const Color textMuted = Color(0xFF7A8B80);
  static const Color textLight = Color(0xFFA0B0A5);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
}

/// Midnight Design System — Quiet, immersive, moonlit pine nature.
class MidnightColors {
  MidnightColors._();

  static const Color canvas = Color(0xFF0B1510);
  static const Color surface = Color(0xFF13251B);
  static const Color surfaceElevated = Color(0xFF182D22);
  static const Color surfaceVariant = Color(0xFF1E372A);
  static const Color border = Color(0xFF234030);
  static const Color borderSubtle = Color(0xFF1B3326);

  static const Color primary = Color(0xFF34D399);
  static const Color primaryLight = Color(0xFF6EE7B7);
  static const Color primaryContainer = Color(0xFF163C2A);
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryContainer = Color(0xFF143323);

  static const Color accent = Color(0xFFA5B4FC);
  static const Color accentLight = Color(0xFFC7D2FE);
  static const Color accentContainer = Color(0xFF1E223D);

  static const Color textPrimary = Color(0xFFF3F7F4);
  static const Color textSecondary = Color(0xFFA6BAAE);
  static const Color textMuted = Color(0xFF6F8778);
  static const Color textLight = Color(0xFF4D6355);

  static const Color success = Color(0xFF34D399);
  static const Color successLight = Color(0xFF064E3B);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFF451A03);
  static const Color error = Color(0xFFF87171);
  static const Color errorLight = Color(0xFF450A0A);
}

/// Unified Theme Color Resolver for contextual styling
class NavThemeColors {
  final bool isDark;

  const NavThemeColors({required this.isDark});

  factory NavThemeColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NavThemeColors(isDark: isDark);
  }

  Color get canvas => isDark ? MidnightColors.canvas : DawnColors.canvas;
  Color get surface => isDark ? MidnightColors.surface : DawnColors.surface;
  Color get surfaceElevated => isDark ? MidnightColors.surfaceElevated : DawnColors.surfaceElevated;
  Color get surfaceVariant => isDark ? MidnightColors.surfaceVariant : DawnColors.surfaceVariant;
  Color get surfaceCard => surface;
  Color get card => surface;
  Color get border => isDark ? MidnightColors.border : DawnColors.border;
  Color get borderSubtle => isDark ? MidnightColors.borderSubtle : DawnColors.borderSubtle;

  Color get primary => isDark ? MidnightColors.primary : DawnColors.primary;
  Color get primaryLight => isDark ? MidnightColors.primaryLight : DawnColors.primaryLight;
  Color get primaryContainer => isDark ? MidnightColors.primaryContainer : DawnColors.primaryContainer;
  Color get secondary => isDark ? MidnightColors.secondary : DawnColors.secondary;
  Color get secondaryContainer => isDark ? MidnightColors.secondaryContainer : DawnColors.secondaryContainer;

  Color get accent => isDark ? MidnightColors.accent : DawnColors.accent;
  Color get accentLight => isDark ? MidnightColors.accentLight : DawnColors.accentLight;
  Color get accentContainer => isDark ? MidnightColors.accentContainer : DawnColors.accentContainer;

  Color get textPrimary => isDark ? MidnightColors.textPrimary : DawnColors.textPrimary;
  Color get textSecondary => isDark ? MidnightColors.textSecondary : DawnColors.textSecondary;
  Color get textMuted => isDark ? MidnightColors.textMuted : DawnColors.textMuted;
  Color get textLight => isDark ? MidnightColors.textLight : DawnColors.textLight;

  Color get success => isDark ? MidnightColors.success : DawnColors.success;
  Color get successLight => isDark ? MidnightColors.successLight : DawnColors.successLight;
  Color get warning => isDark ? MidnightColors.warning : DawnColors.warning;
  Color get warningLight => isDark ? MidnightColors.warningLight : DawnColors.warningLight;
  Color get error => isDark ? MidnightColors.error : DawnColors.error;
  Color get errorLight => isDark ? MidnightColors.errorLight : DawnColors.errorLight;
}
