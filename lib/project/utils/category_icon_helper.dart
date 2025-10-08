import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:icofont_flutter/icofont_flutter.dart';

/// Utility class để lấy icon cho category
class CategoryIconHelper {
  /// Lấy icon tương ứng cho mỗi category name
  static IconData getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      // Food & Dining
      case 'food':
        return MdiIcons.food;
      case 'breakfast':
        return Icons.free_breakfast_outlined;
      case 'lunch':
        return Icons.restaurant_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'restaurant':
        return Icons.restaurant;

      // Transportation
      case 'transportation':
        return Icons.directions_car;
      case 'taxi':
        return Icons.local_taxi;
      case 'fuel':
      case 'gas':
        return Icons.local_gas_station;
      case 'parking':
        return Icons.local_parking;

      // Shopping
      case 'shopping':
        return Icons.shopping_bag;
      case 'daily necessities':
        return Icons.add_shopping_cart;
      case 'clothes':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;

      // Entertainment
      case 'entertainment':
        return Icons.movie_filter;
      case 'movies':
      case 'cinema':
        return Icons.movie_outlined;
      case 'music':
        return Icons.music_note;
      case 'games':
        return Icons.sports_esports;

      // Bills & Utilities
      case 'electricity':
        return Icons.electric_bolt;
      case 'water':
        return Icons.water_drop;
      case 'internet':
        return IcoFontIcons.globe;
      case 'phone':
        return Icons.phone;
      case 'rent':
        return Icons.home;

      // Health & Fitness
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'fitness':
      case 'gym':
        return Icons.fitness_center;
      case 'pharmacy':
        return Icons.local_pharmacy;

      // Education
      case 'education':
      case 'school':
        return Icons.school;
      case 'books':
        return Icons.menu_book;

      // Income categories
      case 'salary':
        return Icons.payments;
      case 'business':
        return Icons.business_center;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      case 'bonus':
        return Icons.money;

      // Other
      case 'travel':
        return Icons.flight;
      case 'gift & donation':
        return Icons.volunteer_activism;
      case 'pets':
        return Icons.pets;
      case 'beauty':
        return Icons.face;
      case 'insurance':
        return Icons.verified_user;

      // Default
      default:
        return Icons.category_outlined;
    }
  }
}
