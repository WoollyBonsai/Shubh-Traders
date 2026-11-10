import 'dart:io';
import 'package:flutter/material.dart';

class BrandInfo {
  final String name;
  final String category;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  const BrandInfo({
    required this.name,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });
}

class BrandLogos {
  static const List<BrandInfo> presetBrands = [
    BrandInfo(
      name: 'UltraTech',
      category: 'Cement',
      primaryColor: Color(0xFFFBBF24), // UltraTech Yellow
      secondaryColor: Color(0xFF1E3A8A), // Blue
      icon: Icons.architecture,
    ),
    BrandInfo(
      name: 'Ambuja',
      category: 'Cement',
      primaryColor: Color(0xFFDC2626), // Ambuja Red
      secondaryColor: Color(0xFF1E40AF), // Blue
      icon: Icons.shield,
    ),
    BrandInfo(
      name: 'ACC',
      category: 'Cement',
      primaryColor: Color(0xFFB91C1C), // ACC Deep Red
      secondaryColor: Color(0xFFFEF3C7),
      icon: Icons.handyman,
    ),
    BrandInfo(
      name: 'Dalmia',
      category: 'Cement',
      primaryColor: Color(0xFF0369A1), // Dalmia Sky Blue
      secondaryColor: Color(0xFFE0F2FE),
      icon: Icons.foundation,
    ),
    BrandInfo(
      name: 'Tata Tiscon',
      category: 'Steel',
      primaryColor: Color(0xFF1E40AF), // Tata Blue
      secondaryColor: Color(0xFFEF4444), // Red
      icon: Icons.dehaze,
    ),
    BrandInfo(
      name: 'Jindal Panther',
      category: 'Steel',
      primaryColor: Color(0xFF047857), // Panther Green
      secondaryColor: Color(0xFFF59E0B),
      icon: Icons.view_headline,
    ),
    BrandInfo(
      name: 'Kamdhenu',
      category: 'Steel',
      primaryColor: Color(0xFF7C3AED), // Kamdhenu Purple
      secondaryColor: Color(0xFFEDE9FE),
      icon: Icons.reorder,
    ),
    BrandInfo(
      name: 'Asian Paints',
      category: 'Paint',
      primaryColor: Color(0xFFEA580C), // Orange
      secondaryColor: Color(0xFFFEF08A),
      icon: Icons.format_paint,
    ),
    BrandInfo(
      name: 'Berger',
      category: 'Paint',
      primaryColor: Color(0xFF0284C7),
      secondaryColor: Color(0xFFBAE6FD),
      icon: Icons.brush,
    ),
    BrandInfo(
      name: 'River Sand',
      category: 'Aggregates',
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFFFEF3C7),
      icon: Icons.terrain,
    ),
    BrandInfo(
      name: 'Clay Bricks',
      category: 'Bricks',
      primaryColor: Color(0xFF991B1B),
      secondaryColor: Color(0xFFFEE2E2),
      icon: Icons.view_quilt,
    ),
    BrandInfo(
      name: 'Aggregate',
      category: 'Aggregates',
      primaryColor: Color(0xFF475569),
      secondaryColor: Color(0xFFF1F5F9),
      icon: Icons.grain,
    ),
    BrandInfo(
      name: 'Astral Pipes',
      category: 'Plumbing',
      primaryColor: Color(0xFF0284C7),
      secondaryColor: Color(0xFFE0F2FE),
      icon: Icons.plumbing,
    ),
  ];

  static BrandInfo getBrand(String? brandName) {
    if (brandName == null || brandName.isEmpty) {
      return const BrandInfo(
        name: 'General',
        category: 'Material',
        primaryColor: Color(0xFF2563EB),
        secondaryColor: Color(0xFFDBEAFE),
        icon: Icons.inventory_2,
      );
    }
    return presetBrands.firstWhere(
      (b) => b.name.toLowerCase() == brandName.toLowerCase(),
      orElse: () => BrandInfo(
        name: brandName,
        category: 'Item',
        primaryColor: const Color(0xFF1E3A8A),
        secondaryColor: const Color(0xFFDBEAFE),
        icon: Icons.category,
      ),
    );
  }
}

class BrandBadgeWidget extends StatelessWidget {
  final String? brand;
  final String? imagePath;
  final double size;

  const BrandBadgeWidget({
    super.key,
    this.brand,
    this.imagePath,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync()) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          image: DecorationImage(
            image: FileImage(File(imagePath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final info = BrandLogos.getBrand(brand);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: info.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: info.primaryColor.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Icon(
          info.icon,
          size: size * 0.58,
          color: info.primaryColor,
        ),
      ),
    );
  }
}
