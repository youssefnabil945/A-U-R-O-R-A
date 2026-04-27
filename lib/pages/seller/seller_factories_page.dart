import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import '../../models/aurora_factory.dart';
import '../../models/seller.dart';
import '../../services/factories_db.dart';
import '../../services/supabase.dart';
import '../../helpers/secure_data_helper.dart';

/// Seller's page to connect with factories via NFC/Bluetooth/QR
class SellerFactoriesPage extends StatefulWidget {
  const SellerFactoriesPage({super.key});

  @override
  State<SellerFactoriesPage> createState() => _SellerFactoriesPageState();
}

class _SellerFactoriesPageState extends State<SellerFactoriesPage> {
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Connection state
  bool _isDiscoverable = false;
  String? _myUuid;
  String? _sellerName;
  List<Map<String, dynamic>> _nearbyFactories = [];
  StreamSubscription? _discoverySubscription;
  
  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _discoverySubscription?.cancel();
    stopDiscovery();
    super.dispose();
  }
  
  Future<void> _loadSellerInfo() async {
    try {
      final supabase = context.read<SupabaseProvider>();
      final userId = supabase.currentUser?.id;
      if (userId != null) {
        setState(() {
          _myUuid = userId;
          _sellerName = supabase.currentUser?.userMetadata?['full_name'] ?? 'Seller';
        });
      }
    } catch (e) {
      debugPrint('Error loading seller info: $e');
    }
  }
  
  /// Start being discoverable by factories
  void startBeingDiscoverable() async {
    setState(() => _isDiscoverable = true);
    
    // In a real implementation, this would use NFC or Bluetooth LE
    // For now, we'll show QR code that factories can scan
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan to Connect'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Factory should scan this QR code to connect with you'),
            const SizedBox(height: 16),
            if (_myUuid != null)
              QrImageView(
                data: _encryptSellerData(),
                version: QrVersions.auto,
                size: 250.0,
              ),
            const SizedBox(height: 16),
            Text('UUID: ${_myUuid?.substring(0, 8)}...', 
                 style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            const Text('Keep this screen open while factory scans'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isDiscoverable = false);
              Navigator.pop(context);
            },
            child: const Text('Stop'),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.share(_encryptSellerData());
            },
          ),
        ],
      ),
    );
  }
  
  /// Encrypt seller data for secure sharing
  String _encryptSellerData() {
    if (_myUuid == null) return '';
    
    final data = {
      'uuid': _myUuid,
      'name': _sellerName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Use simple base64 encoding (in production, use proper encryption)
    return base64Encode(jsonEncode(data).codeUnits);
  }
  
  /// Scan factory QR code to connect
  Future<void> _scanFactoryCode() async {
    // In production, this would open camera to scan QR
    // For now, show a dialog to simulate scanning
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to Factory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter factory UUID or scan QR code'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Factory UUID',
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
      await _connectToFactory(result);
    }
  }
  
  Future<void> _connectToFactory(String factoryUuid) async {
    try {
      final db = context.read<FactoriesDB>();
      
      // Check if factory already exists
      var factory = await db.getFactoryByUuid(factoryUuid);
      
      if (factory == null) {
        // Create placeholder factory
        factory = AuroraFactory.create(
          name: 'Unknown Factory',
          ownerName: 'Pending',
          email: 'pending@factory.com',
          phone: '',
          location: 'Unknown',
          specialization: 'General',
        );
        factory = AuroraFactory(
          id: factory.id,
          uuid: factoryUuid,
          name: 'Unknown Factory',
          ownerName: 'Pending',
          email: 'pending@factory.com',
          phone: '',
          location: 'Unknown',
          specialization: 'General',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'pending',
        );
        await db.saveFactory(factory);
      }
      
      // Navigate to factory details to share products
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FactoryConnectionDetailPage(factory: factory),
          ),
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to factory!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }
  
  void stopDiscovery() {
    setState(() => _isDiscoverable = false);
    _discoverySubscription?.cancel();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Factories'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Banner
          if (_isDiscoverable)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_connected, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You are discoverable. Factories can scan your QR code.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: stopDiscovery,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search connected factories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer<FactoriesDB>(
              builder: (context, db, child) {
                return FutureBuilder<List<AuroraFactory>>(
                  future: db.getAllFactories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.factory_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('No connected factories yet'),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _scanFactoryCode,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Connect to Factory'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: startBeingDiscoverable,
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Show My QR Code'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final factories = snapshot.data!;
                    
                    if (_isGridView) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: factories.length,
                        itemBuilder: (context, index) {
                          return _FactoryConnectionCard(
                            factory: factories[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FactoryConnectionDetailPage(factory: factories[index]),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: factories.length,
                        itemBuilder: (context, index) {
                          return _FactoryConnectionListTile(
                            factory: factories[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FactoryConnectionDetailPage(factory: factories[index]),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'discoverableFab',
            onPressed: startBeingDiscoverable,
            backgroundColor: _isDiscoverable ? Colors.red : Colors.green,
            child: Icon(_isDiscoverable ? Icons.stop : Icons.qr_code),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'connectFab',
            onPressed: _scanFactoryCode,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _FactoryConnectionCard extends StatelessWidget {
  final AuroraFactory factory;
  final VoidCallback onTap;
  
  const _FactoryConnectionCard({
    required this.factory,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(factory.status).withOpacity(0.1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      factory.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(factory.status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      factory.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      factory.specialization,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _MiniStat(icon: Icons.shopping_bag, label: '${factory.totalDeals}'),
                        const SizedBox(width: 8),
                        _MiniStat(icon: Icons.attach_money, label: '${factory.totalVolume.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.grey;
      case 'pending': return Colors.orange;
      default: return Colors.blue;
    }
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _MiniStat({required this.icon, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Theme.of(context).primaryColor),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FactoryConnectionListTile extends StatelessWidget {
  final AuroraFactory factory;
  final VoidCallback onTap;
  
  const _FactoryConnectionListTile({
    required this.factory,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(factory.status),
          child: Text(factory.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
        ),
        title: Text(factory.name),
        subtitle: Text('${factory.specialization} • ${factory.totalDeals} deals'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.grey;
      case 'pending': return Colors.orange;
      default: return Colors.blue;
    }
  }
}

/// Detail page for factory connection - share products, view deals
class FactoryConnectionDetailPage extends StatefulWidget {
  final AuroraFactory factory;
  
  const FactoryConnectionDetailPage({super.key, required this.factory});
  
  @override
  State<FactoryConnectionDetailPage> createState() => _FactoryConnectionDetailPageState();
}

class _FactoryConnectionDetailPageState extends State<FactoryConnectionDetailPage> {
  int _selectedTab = 0; // 0: Products, 1: Deals, 2: Analytics
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.factory.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Share with ${widget.factory.name}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: widget.factory.uuid,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      const SizedBox(height: 16),
                      const Text('Factory can scan this to verify connection'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Factory Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    widget.factory.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.factory.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        widget.factory.specialization,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Status: ${widget.factory.status.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(widget.factory.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Selector
          Row(
            children: [
              _buildTabButton(0, 'Products', Icons.inventory_2),
              _buildTabButton(1, 'Deals', Icons.receipt_long),
              _buildTabButton(2, 'Analytics', Icons.analytics),
            ],
          ),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showShareProductsDialog(),
              icon: const Icon(Icons.send),
              label: const Text('Share Products'),
            )
          : null,
    );
  }
  
  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildProductsTab();
      case 1:
        return _buildDealsTab();
      case 2:
        return _buildAnalyticsTab();
      default:
        return const Center(child: Text('Coming soon'));
    }
  }
  
  Widget _buildProductsTab() {
    // This would fetch products shared by this factory
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No products shared yet'),
          const SizedBox(height: 8),
          const Text('Factory needs to share their product catalog'),
        ],
      ),
    );
  }
  
  Widget _buildDealsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No deals yet'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create deal with factory
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Deal'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard('Total Deals', '${widget.factory.totalDeals}', Icons.shopping_bag),
          const SizedBox(height: 12),
          _buildStatCard('Total Volume', '\$${widget.factory.totalVolume.toStringAsFixed(2)}', Icons.attach_money),
          const SizedBox(height: 12),
          _buildStatCard('Rating', '${"⭐" * widget.factory.rating}', Icons.star),
          const SizedBox(height: 24),
          const Text('Performance Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          // Add charts here in full implementation
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Chart placeholder')),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600])),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.grey;
      case 'pending': return Colors.orange;
      default: return Colors.blue;
    }
  }
  
  void _showShareProductsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Products'),
        content: const Text('Select products from your inventory to share with this factory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to product selection screen
            },
            child: const Text('Select Products'),
          ),
        ],
      ),
    );
  }
}
