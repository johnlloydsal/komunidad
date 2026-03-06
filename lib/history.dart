import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view history')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "My History",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            onPressed: () => _showClearAllDialog(),
            tooltip: 'Clear All History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Reports', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Service Requests', 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Lost Items', 2),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _buildTabContent(user.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String userId) {
    switch (_selectedTab) {
      case 0:
        return _buildReportsList(userId);
      case 1:
        return _buildServiceRequestsList(userId);
      case 2:
        return _buildLostItemsList(userId);
      default:
        return const SizedBox();
    }
  }

  Widget _buildReportsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState('No reports found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildReportCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildServiceRequestsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('service_requests')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState('No service requests found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildServiceRequestCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildLostItemsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('lost_items')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState('No lost items found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildLostItemCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'pending';
    final category = data['category'] ?? 'General';
    final description = data['description'] ?? 'No description';
    final timestamp = data['createdAt'] as Timestamp?;
    final dateStr = _formatDate(timestamp);
    
    // DEBUG: Print all fields to see what's actually in Firestore
    print('🔍 DEBUG Report Data: ${data.keys.toList()}');
    print('🔍 Status: $status');
    print('🔍 solutionDescription: ${data['solutionDescription']}');
    print('🔍 resolution: ${data['resolution']}');
    print('🔍 solution: ${data['solution']}');
    print('🔍 actionNotes: ${data['actionNotes']}');
    print('🔍 actionNote: ${data['actionNote']}');
    print('🔍 action_notes: ${data['action_notes']}');
    
    // Support multiple field name variations from admin dashboard
    final solutionDescription = data['solutionDescription'] as String? ?? 
                                 data['resolution'] as String? ?? 
                                 data['solution'] as String?;
    final actionNotes = data['actionNotes'] as String? ?? 
                        data['actionNote'] as String? ?? 
                        data['action_notes'] as String?;
    final isResolved = status.toLowerCase() == 'resolved' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'solved';
    final isActioned = status.toLowerCase() == 'actioned' || status.toLowerCase() == 'in-progress' || status.toLowerCase() == 'in_progress' || status.toLowerCase().replaceAll(' ', '_') == 'in_progress';
    
    print('🔍 Final solutionDescription: $solutionDescription');
    print('🔍 Final actionNotes: $actionNotes');
    print('🔍 isResolved: $isResolved, isActioned: $isActioned');
    print('---');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (actionNotes != null && actionNotes.isNotEmpty && (isActioned || isResolved)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        actionNotes,
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (solutionDescription != null && solutionDescription.isNotEmpty && isResolved) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        solutionDescription,
                        style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                IconButton(
                  onPressed: () => _confirmDelete('report', docId),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRequestCard(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'pending';
    final category = data['category'] ?? 'General';
    final description = data['description'] ?? 'No description';
    final timestamp = data['createdAt'] as Timestamp?;
    final dateStr = _formatDate(timestamp);
    // Support multiple field name variations from admin dashboard
    final solutionDescription = data['solutionDescription'] as String? ?? 
                                 data['resolution'] as String? ?? 
                                 data['solution'] as String?;
    final actionNotes = data['actionNotes'] as String? ?? 
                        data['actionNote'] as String? ?? 
                        data['action_notes'] as String?;
    final isResolved = status.toLowerCase() == 'resolved' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'fulfilled';
    final isActioned = status.toLowerCase() == 'actioned' || status.toLowerCase() == 'in-progress' || status.toLowerCase() == 'in_progress' || status.toLowerCase().replaceAll(' ', '_') == 'in_progress';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(status, isServiceRequest: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (actionNotes != null && actionNotes.isNotEmpty && (isActioned || isResolved)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        actionNotes,
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (solutionDescription != null && solutionDescription.isNotEmpty && isResolved) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        solutionDescription,
                        style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                IconButton(
                  onPressed: () => _confirmDelete('service_request', docId),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostItemCard(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'lost';
    final item = data['item'] ?? 'Unknown item';
    final location = data['location'] ?? 'Unknown location';
    final description = data['description'] ?? '';
    final timestamp = data['createdAt'] as Timestamp?;
    final dateStr = _formatDate(timestamp);
    // Support multiple field name variations from admin dashboard
    final adminNotes = data['adminNotes'] as String? ?? 
                       data['adminNote'] as String? ?? 
                       data['admin_notes'] as String? ?? 
                       data['actionNotes'] as String?;
    final foundBy = data['foundByName'] as String?;
    final isFound = status.toLowerCase() == 'found' || status.toLowerCase() == 'returned';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFound ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
               const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            if (foundBy != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Found by: $foundBy',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (adminNotes != null && isFound) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Admin Update:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminNotes,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _showLostItemDetails(data, docId),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: const Text('View Details', style: TextStyle(fontSize: 12)),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete('lost_item', docId),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {bool isServiceRequest = false}) {
    Color color;
    String label;

    if (isServiceRequest) {
      switch (status.toLowerCase()) {
        case 'completed':
          color = Colors.green;
          label = 'COMPLETED';
          break;
        case 'in-progress':
          color = Colors.blue;
          label = 'IN PROGRESS';
          break;
        default:
          color = Colors.orange;
          label = 'PENDING';
      }
    } else {
      switch (status.toLowerCase()) {
        case 'resolved':
          color = Colors.green;
          label = 'RESOLVED';
          break;
        case 'in-progress':
          color = Colors.blue;
          label = 'IN PROGRESS';
          break;
        default:
          color = Colors.orange;
          label = 'PENDING';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _confirmDelete(String type, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(type, docId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String type, String docId) async {
    try {
      String collection;
      switch (type) {
        case 'report':
          collection = 'reports';
          break;
        case 'service_request':
          collection = 'service_requests';
          break;
        case 'lost_item':
          collection = 'lost_items';
          break;
        default:
          return;
      }

      await _firestore.collection(collection).doc(docId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all items in the current tab? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllHistory();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String collection;
      switch (_selectedTab) {
        case 0:
          collection = 'reports';
          break;
        case 1:
          collection = 'service_requests';
          break;
        case 2:
          collection = 'lost_items';
          break;
        default:
          return;
      }

      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${snapshot.docs.length} items deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLostItemDetails(Map<String, dynamic> data, String docId) {
    final item = data['item'] ?? 'Unknown Item';
    final description = data['description'] ?? '';
    final location = data['location'] ?? 'Unknown';
    final status = data['status'] ?? 'lost';
    // Support multiple field name variations from admin dashboard
    final adminNotes = data['adminNotes'] as String? ?? 
                       data['adminNote'] as String? ?? 
                       data['admin_notes'] as String? ?? 
                       data['actionNotes'] as String?;
    final foundBy = data['foundByName'] as String?;
    final imageUrl = data['imageUrl'] as String?;
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '';
    final isFound = status.toLowerCase() == 'found' || status.toLowerCase() == 'returned';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', status.toUpperCase()),
              _buildDetailRow('Location', location),
              if (description.isNotEmpty)
                _buildDetailRow('Description', description),
              if (email.isNotEmpty)
                _buildDetailRow('Email', email),
              if (phone.isNotEmpty)
                _buildDetailRow('Phone', phone),
              if (foundBy != null)
                _buildDetailRow('Found By', foundBy),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Photo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showFullImage(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 64),
                        );
                      },
                    ),
                  ),
                ),
              ],
              if (adminNotes != null && adminNotes.isNotEmpty && isFound) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Admin Update:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    adminNotes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Image'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 64),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
