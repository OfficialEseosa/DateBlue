import 'package:flutter/material.dart';

/// DateBlue app theme constants
/// Centralizes all colors, text styles, and common decorations
class DateBlueTheme {
  DateBlueTheme._();

  // Primary Colors
  static const Color primaryBlue = Color(0xFF0039A6);
  static const Color lightBlue = Color(0xFF97CAEB);
  
  // Background Colors
  static const Color scaffoldBackground = Color(0xFF97CAEB);
  static const Color cardBackground = Colors.white;
  static const Color surfaceGrey = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Colors.white;
  
  // Gradient Colors
  static const Color gradientStart = Color(0xFF0039A6);
  static const Color gradientEnd = Color(0xFF97CAEB);

  // Campus info - using IconData for professional look
  static const Map<String, CampusInfo> campusInfo = {
    'Atlanta Campus': CampusInfo(
      name: 'Atlanta Campus',
      shortName: 'Atlanta',
      iconData: Icons.location_city,
      location: 'Downtown Atlanta',
    ),
    'Alpharetta Campus': CampusInfo(
      name: 'Alpharetta Campus',
      shortName: 'Alpharetta',
      iconData: Icons.business,
      location: 'Alpharetta',
    ),
    'Clarkston Campus': CampusInfo(
      name: 'Clarkston Campus',
      shortName: 'Clarkston',
      iconData: Icons.school,
      location: 'Clarkston',
    ),
    'Decatur Campus': CampusInfo(
      name: 'Decatur Campus',
      shortName: 'Decatur',
      iconData: Icons.menu_book,
      location: 'Decatur',
    ),
    'Dunwoody Campus': CampusInfo(
      name: 'Dunwoody Campus',
      shortName: 'Dunwoody',
      iconData: Icons.account_balance,
      location: 'Dunwoody',
    ),
    'Newton Campus': CampusInfo(
      name: 'Newton Campus',
      shortName: 'Newton',
      iconData: Icons.museum,
      location: 'Newton',
    ),
  };

  // Common Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // Card Decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Gradient overlay for profile cards
  static BoxDecoration get profileGradientOverlay => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.7),
      ],
    ),
  );

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // Profile Card specific styles
  static const TextStyle profileName = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textLight,
  );

  static const TextStyle profileAge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    color: textLight,
  );

  static const TextStyle promptQuestion = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryBlue,
  );

  static const TextStyle promptAnswer = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
  );
}

/// Campus information model
class CampusInfo {
  final String name;
  final String shortName;
  final IconData iconData;
  final String location;

  const CampusInfo({
    required this.name,
    required this.shortName,
    required this.iconData,
    required this.location,
  });
}

