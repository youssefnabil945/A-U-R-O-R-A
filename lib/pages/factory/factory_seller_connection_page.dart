import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/aurora_factory.dart';
import '../../models/bill_model.dart';
import '../../services/factories_db.dart';
import '../../services/supabase.dart';

/// Factory-side page to receive seller connections and share products
class FactorySellerConnectionPage extends StatefulWidget {
  const FactorySellerConnectionPage({super.key});

  @override
  State<FactorySellerConnectionPage> createState() => _FactorySellerConnectionPageState();
}

class _FactorySellerConnectionPageState extends State<FactorySellerConnectionPage> {
  bool _isDiscoverable = false;
  List<Map<String, dynamic>> _connectedSellers = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Sellers'),
      ),
      body: Column(
        children: [
          // Discoverable Status Banner
          if (_isDiscoverable)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Scan seller QR codes to connect',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _isDiscoverable = false),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanSellerQR,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Seller'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() => _isDiscoverable = !_isDiscoverable),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDiscoverable ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isDiscoverable ? 'Stop' : 'Show My QR'),
                ),
              ],
            ),
          ),
          
          // Sellers List
          Expanded(
            child: _connectedSellers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('No connected sellers yet'),
                        const SizedBox(height: 8),
                        const Text('Scan a seller\'s QR code to connect'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _connectedSellers.length,
                    itemBuilder: (context, index) {
                      final seller = _connectedSellers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text((seller['name'] ?? 'S')[0].toUpperCase()),
                          ),
                          title: Text(seller['name'] ?? 'Unknown Seller'),
                          subtitle: Text('Connected: ${_formatDate(seller['connectedAt'])}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showSellerDetails(seller),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanSellerQR,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Connect Seller'),
      ),
    );
  }
  
  Future<void> _scanSellerQR() async {
    // In production, open camera to scan QR
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to Seller'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan seller\'s QR code or enter UUID'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Seller UUID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await _connectToSeller(result);
    }
  }
  
  Future<void> _connectToSeller(String encodedData) async {
    try {
      // Decode seller data
      final decoded = jsonDecode(utf8.decode(base64Decode(encodedData)));
      final sellerUuid = decoded['uuid'] as String;
      final sellerName = decoded['name'] as String;
      
      // Check if already connected
      final exists = _connectedSellers.any((s) => s['uuid'] == sellerUuid);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already connected to this seller')),
        );
        return;
      }
      
      // Add to connected sellers
      setState(() {
        _connectedSellers.add({
          'uuid': sellerUuid,
          'name': sellerName,
          'connectedAt': DateTime.now(),
          'productsShared': 0,
          'totalDeals': 0,
        });
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to $sellerName!')),
      );
      
      // Navigate to product sharing screen
      if (mounted) {
        _showShareProductsDialog(_connectedSellers.last);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR code: $e')),
      );
    }
  }
  
  void _showSellerDetails(Map<String, dynamic> seller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              seller['name'] ?? 'Unknown Seller',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('UUID: ${seller['uuid']}'),
            Text('Connected: ${_formatDate(seller['connectedAt'])}'),
            const Divider(),
            _buildStatRow('Products Shared', '${seller['productsShared']}'),
            _buildStatRow('Total Deals', '${seller['totalDeals']}'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showShareProductsDialog(seller),
              icon: const Icon(Icons.send),
              label: const Text('Share Products'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // View deal history
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Deals'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
  
  void _showShareProductsDialog(Map<String, dynamic> seller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Products'),
        content: const Text('Select products from your factory catalog to share with this seller.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to product selection screen
              // In full implementation, this would let factory select products to share
            },
            child: const Text('Select Products'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
