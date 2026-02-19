import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/service_request_service.dart';
import 'services/supplies_service.dart';

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({super.key});

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  final ServiceRequestService _serviceRequestService = ServiceRequestService();
  final SuppliesService _suppliesService = SuppliesService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedCategory;
  String? selectedLocation;
  bool _isSubmitting = false;
  
  // For funeral supplies (borrowing)
  Map<String, int> funeralQuantities = {}; // supplyId -> quantity
  List<Map<String, dynamic>> funeralSupplies = [];

  final List<String> categories = [
    'Funeral & Bereavement Assistance',
    'Event & Community Requests',
    'Social Welfare Assistance',
    'Other (Please Specify in the description)',
  ];

  final List<String> zones = [
    'Zone 1',
    'Zone 2',
    'Zone 3',
    'Zone 4',
    'Zone 5',
    'Zone 6',
    'Zone 7',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      nameController.text = user.displayName ?? user.email?.split('@')[0] ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
            "Request Service",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Name Field (Read-only)
              TextField(
                controller: nameController,
                enabled: false,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Name",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Field
              TextField(
                controller: descriptionController,
                maxLines: 4,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: "Select Category",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Show funeral supplies if Funeral & Bereavement Assistance is selected
              if (selectedCategory == 'Funeral & Bereavement Assistance') ...[
                _buildFuneralSuppliesList(),
                const SizedBox(height: 16),
              ],

              // Location Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedLocation,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: "Select Location (Zone)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: zones.map((String zone) {
                  return DropdownMenuItem<String>(
                    value: zone,
                    child: Text(zone),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedLocation = newValue;
                  });
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitServiceRequest,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitServiceRequest() async {
    // Validate fields
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        selectedCategory == null ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }



    setState(() {
      _isSubmitting = true;
    });

    try {
      String finalDescription = descriptionController.text.trim();
      
      // If funeral assistance with supplies selected, borrow them and update description
      if (selectedCategory == 'Funeral & Bereavement Assistance' && 
          funeralQuantities.isNotEmpty && 
          funeralQuantities.values.any((q) => q > 0)) {
        
        final requestedItems = <String>[];
        for (var entry in funeralQuantities.entries) {
          if (entry.value > 0) {
            final supply = funeralSupplies.firstWhere(
              (s) => s['id'] == entry.key,
              orElse: () => {},
            );
            if (supply.isNotEmpty) {
              // Get supply name with fallback
              final supplyName = supply['name'] ?? supply['itemName'] ?? supply['item'] ?? 'Unknown';
              
              // Actually borrow the supply to sync with admin dashboard
              await _suppliesService.borrowSupply(
                supplyId: entry.key,
                quantity: entry.value,
                borrowerName: nameController.text.trim(),
                purpose: 'Funeral & Bereavement Assistance: ${descriptionController.text.trim()}',
              );
              requestedItems.add('$supplyName: ${entry.value}');
            }
          }
        }
        
        if (requestedItems.isNotEmpty) {
          finalDescription += '\n\nBorrowed Funeral Supplies:\n${requestedItems.join('\n')}';
        }
      }

      // Submit service request
      await _serviceRequestService.submitServiceRequest(
        name: nameController.text.trim(),
        description: finalDescription,
        category: selectedCategory!,
        location: selectedLocation!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Service request submitted successfully! 🎉"),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      descriptionController.clear();
      setState(() {
        selectedCategory = null;
        selectedLocation = null;
        funeralQuantities.clear();
      });

      // Navigate back after short delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildFuneralSuppliesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _suppliesService.streamSupplies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No funeral supplies available at the moment',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        funeralSupplies = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2, color: Color(0xFF1E3A8A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Borrow Funeral Assistance Supplies:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select quantities to borrow (synced with admin)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ...funeralSupplies.map((supply) {
              final supplyId = supply['id'] as String;
              final supplyName = supply['name'] ?? supply['itemName'] ?? supply['item'] ?? 'Unknown';
              final category = supply['category'] ?? '-';
              final imageUrl = supply['imageUrl'] ?? supply['image'];
              final availableQty = supply['availableQuantity'] ?? 0;
              final totalQty = supply['quantity'] ?? 0;
              final borrowedQty = totalQty - availableQty;
              final status = availableQty > 0 ? 'Available' : 'Unavailable';
              final currentQty = funeralQuantities[supplyId] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: currentQty > 0 ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
                    width: currentQty > 0 ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: currentQty > 0 ? Colors.blue.shade50 : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.inventory_2,
                                        size: 30,
                                        color: Colors.grey[600],
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.inventory_2,
                                  size: 30,
                                  color: Colors.grey[600],
                                ),
                        ),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item Name
                              Text(
                                supplyName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Category
                              Text(
                                'Category: $category',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Quantities Row
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildInfoChip('Total', totalQty.toString(), Colors.blue),
                                  _buildInfoChip('Available', availableQty.toString(), Colors.green),
                                  _buildInfoChip('Borrowed', borrowedQty.toString(), Colors.orange),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: availableQty > 0
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: availableQty > 0
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (availableQty > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Request Quantity:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              // Decrease button
                              IconButton(
                                onPressed: currentQty > 0
                                    ? () {
                                        setState(() {
                                          funeralQuantities[supplyId] = currentQty - 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle),
                                color: Colors.red,
                                iconSize: 30,
                              ),
                              // Quantity display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentQty.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Increase button
                              IconButton(
                                onPressed: currentQty < availableQty
                                    ? () {
                                        setState(() {
                                          funeralQuantities[supplyId] = currentQty + 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.add_circle),
                                color: Colors.green,
                                iconSize: 30,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Currently unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          color: Color.fromRGBO(
            (color.red * 0.3).toInt(),
            (color.green * 0.3).toInt(),
            (color.blue * 0.3).toInt(),
            1,
          ),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}