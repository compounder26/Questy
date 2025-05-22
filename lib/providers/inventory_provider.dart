import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../models/inventory_item.dart';
import '../models/reward.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _items = [];
  late Box<InventoryItem> _inventoryBox;
  bool _isInitialized = false;

  // Getter for inventory items
  List<InventoryItem> get items => [..._items];
  
  // Initialize inventory from Hive
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _inventoryBox = await Hive.openBox<InventoryItem>('inventory');
    _loadInventory();
    _isInitialized = true;
  }
  
  // Load inventory items from Hive
  void _loadInventory() {
    _items = _inventoryBox.values.toList();
    notifyListeners();
  }
  
  // Save inventory items to Hive
  Future<void> _saveInventory() async {
    await _inventoryBox.clear();
    for (var item in _items) {
      await _inventoryBox.put(item.id, item);
    }
  }

  // Add item to inventory
  Future<void> addItem(Reward reward) async {
    // Create a new inventory item with a unique ID each time
    final item = InventoryItem(
      id: const Uuid().v4(),
      name: reward.name,
      description: reward.description,
      iconAsset: reward.iconAsset,
      type: reward.type,
      effectData: reward.effectData,
      purchaseDate: DateTime.now(),
    );
    
    _items.add(item);
    await _saveInventory();
    notifyListeners();
  }

  // Remove item from inventory
  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveInventory();
    notifyListeners();
  }

  // Check if inventory has an item by name
  bool hasItemByName(String name) {
    return _items.any((item) => item.name == name);
  }

  // Get items by type
  List<InventoryItem> getItemsByType(String type) {
    return _items.where((item) => item.type == type).toList();
  }
}
