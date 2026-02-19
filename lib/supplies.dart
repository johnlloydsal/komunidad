import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/supplies_service.dart';

class SuppliesPage extends StatefulWidget {
  const SuppliesPage({super.key});

  @override
  State<SuppliesPage> createState() => _SuppliesPageState();
}

class _SuppliesPageState extends State<SuppliesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SuppliesService _suppliesService = SuppliesService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Barangay Supplies",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF1E3A8A),
              indicatorWeight: 2,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "Available Supplies"),
                Tab(text: "My Borrowed Items"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableSupplies(),
          _buildBorrowedSupplies(),
        ],
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _checkIfAdmin(),
        builder: (context, snapshot) {
          if (snapshot.data == true && _tabController.index == 0) {
            return FloatingActionButton(
              backgroundColor: const Color(0xFF1E3A8A),
              onPressed: _showAddSupplyDialog,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAvailableSupplies() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _suppliesService.streamSupplies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No supplies available yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final supply = snapshot.data![index];
            return _buildSupplyCard(supply);
          },
        );
      },
    );
  }

  Widget _buildSupplyCard(Map<String, dynamic> supply) {
    final availableQty = supply['availableQuantity'] ?? 0;
    final totalQty = supply['quantity'] ?? 0;
    final isAvailable = availableQty > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    supply['name'] ?? 'Unknown Supply',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Out of Stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
            if (supply['description'] != null &&
                supply['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                supply['description'],
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Available: $availableQty / $totalQty',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isAvailable)
                  ElevatedButton.icon(
                    onPressed: () => _showBorrowDialog(supply),
                    icon: const Icon(Icons.handshake, size: 16),
                    label: const Text('Borrow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                FutureBuilder<bool>(
                  future: _checkIfAdmin(),
                  builder: (context, snapshot) {
                    if (snapshot.data != true) return const SizedBox.shrink();
                    return Row(
                      children: [
                        if (isAvailable) const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showEditSupplyDialog(supply),
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                          iconSize: 20,
                        ),
                        IconButton(
                          onPressed: () => _confirmDeleteSupply(supply['id']),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          iconSize: 20,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowedSupplies() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _suppliesService.streamUserBorrowedSupplies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No borrowed items yet.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final borrowed = snapshot.data![index];
            return _buildBorrowedCard(borrowed);
          },
        );
      },
    );
  }

  Widget _buildBorrowedCard(Map<String, dynamic> borrowed) {
    final status = borrowed['status'] ?? 'borrowed';
    final isReturned = status == 'returned';
    final borrowedAt = borrowed['borrowedAt'] as Timestamp?;
    final returnedAt = borrowed['returnedAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    borrowed['supplyName'] ?? 'Unknown Supply',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isReturned ? Colors.grey.shade300 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isReturned ? Colors.grey.shade700 : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quantity: ${borrowed['quantity']}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            if (borrowed['purpose'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Purpose: ${borrowed['purpose']}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Borrowed: ${_formatTimestamp(borrowedAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (isReturned && returnedAt != null)
              Text(
                'Returned: ${_formatTimestamp(returnedAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (!isReturned) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmReturnSupply(borrowed['id']),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Return'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<bool> _checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return userDoc.exists && (userDoc.data()?['isAdmin'] == true);
  }

  void _showAddSupplyDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Supply'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Supply Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter quantity';
                  if (int.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _suppliesService.addSupply(
                    name: nameController.text.trim(),
                    quantity: int.parse(quantityController.text),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );

                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Supply added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSupplyDialog(Map<String, dynamic> supply) {
    final quantityController = TextEditingController(
      text: supply['quantity'].toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${supply['name']}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: quantityController,
            decoration: const InputDecoration(
              labelText: 'Total Quantity',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter quantity';
              if (int.tryParse(value) == null) return 'Please enter a valid number';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _suppliesService.updateSupplyQuantity(
                    supply['id'],
                    int.parse(quantityController.text),
                  );

                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Supply updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showBorrowDialog(Map<String, dynamic> supply) {
    final user = FirebaseAuth.instance.currentUser;
    final nameController = TextEditingController(
      text: user?.displayName ?? user?.email?.split('@')[0] ?? '',
    );
    final quantityController = TextEditingController();
    final purposeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final maxQty = supply['availableQuantity'] as int;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Borrow ${supply['name']}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity (Max: $maxQty)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter quantity';
                  final qty = int.tryParse(value);
                  if (qty == null) return 'Please enter a valid number';
                  if (qty <= 0) return 'Quantity must be greater than 0';
                  if (qty > maxQty) return 'Maximum $maxQty available';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter purpose' : null,
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _suppliesService.borrowSupply(
                    supplyId: supply['id'],
                    quantity: int.parse(quantityController.text),
                    borrowerName: nameController.text.trim(),
                    purpose: purposeController.text.trim(),
                  );

                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Supply borrowed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Borrow'),
          ),
        ],
      ),
    );
  }

  void _confirmReturnSupply(String borrowedId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Supply'),
        content: const Text('Are you sure you want to mark this as returned?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _suppliesService.returnSupply(borrowedId);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supply returned successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Return'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupply(String supplyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supply'),
        content: const Text('Are you sure you want to delete this supply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _suppliesService.deleteSupply(supplyId);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supply deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
