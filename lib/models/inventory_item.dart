import 'package:hive/hive.dart';
import 'dart:convert';

part 'inventory_item.g.dart';

@HiveType(typeId: 5) // Choose a unique typeId that doesn't conflict with your other models
class InventoryItem {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String? iconAsset; // Path to the item's icon
  
  @HiveField(4)
  final String? type; // Type of item (e.g., "potion", "equipment")
  
  @HiveField(5)
  final String? effectDataJson; // Data for special effects stored as JSON string
  
  @HiveField(6)
  final DateTime purchaseDate;

  // Non-persisted field, computed from effectDataJson
  Map<String, dynamic>? get effectData {
    if (effectDataJson == null) return null;
    try {
      return json.decode(effectDataJson!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    this.iconAsset,
    this.type,
    Map<String, dynamic>? effectData,
    required this.purchaseDate,
  }) : effectDataJson = effectData != null ? json.encode(effectData) : null;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconAsset': iconAsset,
    'type': type,
    'effectDataJson': effectDataJson,
    'purchaseDate': purchaseDate.toIso8601String(),
  };
  
  // Create from JSON for retrieval
  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    iconAsset: json['iconAsset'],
    type: json['type'],
    effectData: json['effectDataJson'] != null 
      ? jsonDecode(json['effectDataJson']) 
      : null,
    purchaseDate: DateTime.parse(json['purchaseDate']),
  );
}
