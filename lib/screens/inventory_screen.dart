import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../theme/app_theme.dart';

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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.brown.shade800,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Item Icon with enhanced decoration
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.brown.shade900, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: item.iconAsset != null
                    ? Image.asset(
                        item.iconAsset!,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.inventory_2,
                          color: Colors.white70,
                          size: 34,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2,
                        color: Colors.white70,
                        size: 34,
                      ),
              ),
              const SizedBox(width: 16),
              // Item Name with fancy style
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'PERMANENT',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Item Description with enhanced style
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.brown.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              item.description,
              style: const TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 14,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Acquisition date with icon
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.amber,
              ),
              const SizedBox(width: 5),
              Text(
                'Acquired: ${_formatDate(item.purchaseDate)}',
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
