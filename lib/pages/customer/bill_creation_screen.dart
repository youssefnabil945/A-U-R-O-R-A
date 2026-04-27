import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/aurora_customer.dart';
import '../../models/aurora_product.dart';
import '../../services/customers_db.dart';
import '../../services/product_provider.dart';

/// Bill Creation Screen - Create new bill for customer
/// Allows selecting customer, products, quantity, discount
/// Triggers analysis engine after saving
class BillCreationScreen extends StatefulWidget {
  final AuroraCustomer? existingCustomer;

  const BillCreationScreen({Key? key, this.existingCustomer}) : super(key: key);

  @override
  State<BillCreationScreen> createState() => _BillCreationScreenState();
}

class _BillCreationScreenState extends State<BillCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  
  AuroraCustomer? _selectedCustomer;
  String? _selectedPaymentMethod;
  List<Map<String, dynamic>> _selectedProducts = [];
  
  List<AuroraProduct> _availableProducts = [];

  final List<String> _paymentMethods = ['Cash', 'Card', 'Bank Transfer', 'Credit', 'Mobile Payment'];

  @override
  void initState() {
    super.initState();
    if (widget.existingCustomer != null) {
      _selectedCustomer = widget.existingCustomer;
    }
    // Load products in background without blocking UI
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // Don't show full screen loader, just load in background
    try {
      final provider = context.read<ProductProvider>();
      await provider.loadProducts();
      
      if (mounted) {
        setState(() {
          _availableProducts = provider.products;
        });
      }
    } catch (e) {
      // Silently fail, will show error when user tries to add product
      debugPrint('Error loading products: $e');
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _selectedProducts.fold(0.0, (sum, p) => sum + (p['subtotal'] as double));
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0.0;
  }

  double get _totalAmount {
    return _subtotal - _discount;
  }

  void _selectCustomer() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final db = CustomersDB();
      // Load customers asynchronously without blocking
      final customers = await db.getAllCustomers();
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (customers.isEmpty) {
        // No customers, navigate to add customer
        _navigateToAddCustomer();
        return;
      }

      final selected = await showDialog<AuroraCustomer>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Customer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customers.length,
              itemBuilder: (ctx, i) {
                final c = customers[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(c.fullName[0].toUpperCase()),
                  ),
                  title: Text(c.fullName),
                  subtitle: Text(c.phoneNumber),
                  trailing: Text('\$${(c.analysis['totalSpent'] as num? ?? 0.0).toStringAsFixed(0)}'),
                  onTap: () => Navigator.pop(ctx, c),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _navigateToAddCustomer();
              },
              child: const Text('+ Add New Customer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selected != null && mounted) {
        setState(() => _selectedCustomer = selected);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customers: $e')),
      );
    }
  }

  void _navigateToAddCustomer() async {
    final result = await Navigator.pushNamed(context, '/customer-form');
    if (result == true) {
      _selectCustomer(); // Reload and select
    }
  }

  void _addProduct() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // Reload products to ensure we have latest data
      final provider = context.read<ProductProvider>();
      await provider.loadProducts();
      
      if (mounted) Navigator.pop(context); // Close loading
      
      final products = provider.products;
      
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No products available. Add products first.')),
        );
        return;
      }

      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => _ProductSelectionDialog(products: products),
      );

      if (selected != null && mounted) {
        setState(() {
          // Check if product already exists, update quantity
          final existingIndex = _selectedProducts.indexWhere(
            (p) => p['id'] == selected['id'],
          );
          
          if (existingIndex >= 0) {
            final existing = _selectedProducts[existingIndex];
            final newQuantity = existing['quantity'] + selected['quantity'];
            _selectedProducts[existingIndex] = {
              ...existing,
              'quantity': newQuantity,
              'subtotal': newQuantity * (existing['price'] as double),
            };
          } else {
            _selectedProducts.add(selected);
          }
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select payment method'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid bill amount'), backgroundColor: Colors.red),
      );
      return;
    }

    // Show saving indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create transaction items
      final items = _selectedProducts.map((p) => TransactionItem(
        productId: p['id'],
        productName: p['name'],
        quantity: p['quantity'],
        unitPrice: p['price'],
        subtotal: p['subtotal'],
      )).toList();

      // Create transaction
      final transaction = CustomerTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        items: items,
        totalAmount: _subtotal,
        discount: _discount,
        finalAmount: _totalAmount,
        paymentMethod: _selectedPaymentMethod!,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Save to customer database (this triggers analysis engine)
      final db = CustomersDB();
      await db.addTransaction(_selectedCustomer!.username, transaction);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill created successfully! Analysis updated.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating bill: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Help',
            onPressed: () => _showHelp(),
          ),
        ],
      ),
      body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer Selection Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Customer',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: _selectCustomer,
                                icon: const Icon(Icons.person_add),
                                label: Text(_selectedCustomer == null ? 'Select' : 'Change'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_selectedCustomer != null) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  child: Text(_selectedCustomer!.fullName[0].toUpperCase()),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedCustomer!.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        _selectedCustomer!.phoneNumber,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_selectedCustomer!.analysis['status'] ?? 'New'),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedCustomer!.analysis['status'] ?? 'New',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const ListTile(
                              leading: Icon(Icons.person_outline, size: 40),
                              title: Text('No customer selected'),
                              subtitle: Text('Tap Select to choose or add a customer'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Products Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Products',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: _addProduct,
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_selectedProducts.isEmpty) ...[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text('No products added', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedProducts.length,
                              separatorBuilder: (ctx, i) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final product = _selectedProducts[i];
                                return Dismissible(
                                  key: Key(product['id']),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (_) => _removeProduct(i),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(product['name']),
                                    subtitle: Text(
                                      '${product['quantity']} x \$${(product['price'] as double).toStringAsFixed(2)}',
                                    ),
                                    trailing: Text(
                                      '\$${(product['subtotal'] as double).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment & Discount Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Payment Method
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethod,
                            decoration: const InputDecoration(
                              labelText: 'Payment Method *',
                              prefixIcon: Icon(Icons.payment),
                              border: OutlineInputBorder(),
                            ),
                            items: _paymentMethods.map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedPaymentMethod = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Discount
                          TextFormField(
                            controller: _discountController,
                            decoration: const InputDecoration(
                              labelText: 'Discount',
                              prefixIcon: Icon(Icons.percent),
                              border: OutlineInputBorder(),
                              helperText: 'Enter discount amount',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              prefixIcon: Icon(Icons.note),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary Card
                  Card(
                    elevation: 2,
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
                          _buildSummaryRow('Discount', '-\$${_discount.toStringAsFixed(2)}'),
                          const Divider(),
                          _buildSummaryRow(
                            'Total',
                            '\$${_totalAmount.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveBill,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Save Bill & Update Analysis',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'VIP': return Colors.purple;
      case 'Regular': return Colors.blue;
      case 'At Risk': return Colors.orange;
      default: return Colors.green;
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How to Create a Bill'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Select a customer from your customer list'),
              SizedBox(height: 8),
              Text('2. Add products from your inventory'),
              SizedBox(height: 8),
              Text('3. Set quantity for each product'),
              SizedBox(height: 8),
              Text('4. Apply discount if needed'),
              SizedBox(height: 8),
              Text('5. Choose payment method'),
              SizedBox(height: 8),
              Text('6. Save the bill - Analysis will be updated automatically'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Product Selection Dialog
class _ProductSelectionDialog extends StatefulWidget {
  final List<AuroraProduct> products;

  const _ProductSelectionDialog({required this.products});

  @override
  State<_ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  final _searchController = TextEditingController();
  int _selectedQuantity = 1;
  AuroraProduct? _selectedProduct;
  String _searchQuery = '';

  List<AuroraProduct> get _filteredProducts {
    if (_searchQuery.isEmpty) return widget.products;
    return widget.products.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 16),
            if (_selectedProduct != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        _selectedProduct!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '\$${_selectedProduct!.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_selectedQuantity > 1) {
                                setState(() => _selectedQuantity--);
                              }
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            '$_selectedQuantity',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _selectedQuantity++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Flexible(
              child: SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: _filteredProducts.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final product = _filteredProducts[i];
                    final isSelected = _selectedProduct?.id == product.id;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[200],
                        child: Text(
                          product.name[0].toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text(product.description ?? ''),
                      trailing: Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedProduct = product;
                          _selectedQuantity = 1;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedProduct == null
              ? null
              : () {
                  Navigator.pop(context, {
                    'id': _selectedProduct!.id,
                    'name': _selectedProduct!.name,
                    'price': _selectedProduct!.price,
                    'quantity': _selectedQuantity,
                    'subtotal': _selectedProduct!.price * _selectedQuantity,
                  });
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
