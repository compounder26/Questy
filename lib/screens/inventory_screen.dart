import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_button.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Inventory',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, inventoryProvider, child) {
          final items = inventoryProvider.items;
          
          if (items.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.woodenFrameDecoration.copyWith(
                  image: const DecorationImage(
                    image: AssetImage(AppTheme.woodBackgroundPath),
                    fit: BoxFit.cover,
                    opacity: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text(
                  'Your inventory is empty.\nPurchase permanent items from the Reward Shop!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: AppTheme.woodenFrameDecoration.copyWith(
                image: const DecorationImage(
                  image: AssetImage(AppTheme.woodBackgroundPath),
                  fit: BoxFit.cover,
                  opacity: 0.8,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR ITEMS',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildInventoryItem(context, item);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInventoryItem(BuildContext context, InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.brown.shade800,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Item Icon
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown.shade900, width: 2),
            ),
            child: item.iconAsset != null
                ? Image.asset(
                    item.iconAsset!,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.inventory_2,
                      color: Colors.white70,
                      size: 30,
                    ),
                  )
                : const Icon(
                    Icons.inventory_2,
                    color: Colors.white70,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 12),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Acquired: ${_formatDate(item.purchaseDate)}',
                  style: const TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          // Use button
          PixelButton(
            width: 70,
            height: 40,
            padding: const EdgeInsets.all(6),
            onPressed: () => _useItem(context, item),
            child: const Text(
              'USE',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _useItem(BuildContext context, InventoryItem item) {
    // Display a confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              minWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.woodenFrameDecoration.copyWith(
              image: const DecorationImage(
                image: AssetImage(AppTheme.woodBackgroundPath),
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'USE ITEM',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to use ${item.name}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      PixelButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      PixelButton(
                        onPressed: () {
                          _applyItemEffect(item);
                          Navigator.of(context).pop();
                        },
                        backgroundColor: Colors.green.shade800,
                        child: const Text(
                          'USE',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _applyItemEffect(InventoryItem item) {
    // Implementation for applying item effects (will vary based on item type)
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    
    // Show message for now, in a real implementation you would apply the effect
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Used ${item.name}!'),
        backgroundColor: Colors.green.shade800,
      ),
    );
    
    // Remove item from inventory after use
    inventoryProvider.removeItem(item.id);
  }
}
