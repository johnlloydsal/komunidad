import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'services/supplies_service.dart';
import 'services/user_service.dart';

class AdminBorrowedSuppliesPage extends StatefulWidget {
  const AdminBorrowedSuppliesPage({super.key});

  @override
  State<AdminBorrowedSuppliesPage> createState() =>
      _AdminBorrowedSuppliesPageState();
}

class _AdminBorrowedSuppliesPageState extends State<AdminBorrowedSuppliesPage>
    with SingleTickerProviderStateMixin {
  final SuppliesService _suppliesService = SuppliesService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final isAdmin = await _userService.isAdmin(user.uid);
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Text(
            'You do not have admin privileges',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Borrowed Supplies',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Borrowed'),
            Tab(text: 'Returned'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBorrowedList(null), // All
          _buildBorrowedList('pending'), // Pending
          _buildBorrowedList('borrowed'), // Currently Borrowed
          _buildBorrowedList('returned'), // Returned
        ],
      ),
    );
  }

  Widget _buildBorrowedList(String? statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: statusFilter == null
          ? FirebaseFirestore.instance
              .collection('borrowed_supplies')
              .snapshots()
          : FirebaseFirestore.instance
              .collection('borrowed_supplies')
              .where('status', isEqualTo: statusFilter)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No borrowed supplies found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Sort in memory by requestedAt/borrowedAt descending
        final borrowedItems = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = (aData['requestedAt'] ?? aData['borrowedAt']) as Timestamp?;
            final bTime = (bData['requestedAt'] ?? bData['borrowedAt']) as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 40, child: Text('ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Supply Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Borrower', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 60, child: Text('Qty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Purpose', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Borrowed Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Return Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 100, child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 100, child: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                // Table Rows
                ...borrowedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildBorrowedRow(data, index + 1, doc.id);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBorrowedRow(Map<String, dynamic> data, int index, String docId) {
    final status = data['status'] ?? 'pending';
    final isPending = status == 'pending';
    final isBorrowed = status == 'borrowed';
    final isRejected = status == 'rejected';
    final quantity = data['quantity'] ?? 0;
    
    final requestedAt = data['requestedAt'] as Timestamp?;
    final borrowedAt = data['borrowedAt'] as Timestamp?;
    final returnDate = data['returnDate'] as Timestamp?;
    final returnedAt = data['returnedAt'] as Timestamp?;

    final dateFormat = DateFormat('MMM dd, yyyy');
    final displayDate = requestedAt ?? borrowedAt;
    final borrowedDateStr = displayDate != null 
        ? dateFormat.format(displayDate.toDate())
        : '-';
    final returnDateStr = returnDate != null 
        ? dateFormat.format(returnDate.toDate())
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              index.toString(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data['supplyName'] ?? 'Unknown',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['borrowerName'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  data['userEmail'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              data['purpose'] ?? '-',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              borrowedDateStr,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              returnedAt != null 
                  ? dateFormat.format(returnedAt.toDate())
                  : returnDateStr,
              style: TextStyle(
                fontSize: 12,
                color: returnedAt != null ? Colors.green : Colors.grey[700],
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPending
                    ? Colors.orange.shade100
                    : isRejected
                        ? Colors.red.shade100
                        : isBorrowed
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPending
                    ? 'Pending'
                    : isRejected
                        ? 'Rejected'
                        : isBorrowed
                            ? 'Borrowed'
                            : 'Returned',
                style: TextStyle(
                  fontSize: 11,
                  color: isPending
                      ? Colors.orange.shade900
                      : isRejected
                          ? Colors.red.shade900
                          : isBorrowed
                              ? Colors.blue.shade900
                              : Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  onPressed: () => _showBorrowedDetails(data),
                  tooltip: 'View Details',
                  color: Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (isPending) ...[  
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.check_circle, size: 18),
                    onPressed: () => _confirmApprove(docId, data),
                    tooltip: 'Approve Request',
                    color: Colors.green,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.cancel, size: 18),
                    onPressed: () => _confirmReject(docId, data),
                    tooltip: 'Reject Request',
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else if (isBorrowed) ...[  
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.assignment_return, size: 18),
                    onPressed: () => _confirmReturn(docId, data),
                    tooltip: 'Mark as Returned',
                    color: Colors.green,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBorrowedDetails(Map<String, dynamic> data) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final borrowedAt = data['borrowedAt'] as Timestamp?;
    final returnDate = data['returnDate'] as Timestamp?;
    final returnedAt = data['returnedAt'] as Timestamp?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['supplyName'] ?? 'Borrowed Item Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Supply Name', data['supplyName'] ?? '-'),
              _buildDetailRow('Borrower', data['borrowerName'] ?? '-'),
              _buildDetailRow('Email', data['userEmail'] ?? '-'),
              _buildDetailRow('Quantity', data['quantity'].toString()),
              _buildDetailRow('Purpose', data['purpose'] ?? '-'),
              _buildDetailRow('Status', data['status'] ?? 'borrowed'),
              const Divider(),
              if (borrowedAt != null)
                _buildDetailRow('Borrowed Date', 
                    dateFormat.format(borrowedAt.toDate())),
              if (returnDate != null)
                _buildDetailRow('Expected Return', 
                    dateFormat.format(returnDate.toDate())),
              if (returnedAt != null)
                _buildDetailRow('Actual Return', 
                    dateFormat.format(returnedAt.toDate())),
              if (data['feedback'] != null && data['feedback'].toString().isNotEmpty) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Borrower Feedback:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    data['feedback'].toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (data['feedbackSubmittedAt'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Submitted: ${dateFormat.format((data['feedbackSubmittedAt'] as Timestamp).toDate())}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmApprove(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Borrow Request'),
        content: Text(
          'Approve "${data['supplyName']}" request by ${data['borrowerName']} (x${data['quantity']})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _suppliesService.approveBorrow(docId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Borrow request approved!'),
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
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmReject(String docId, Map<String, dynamic> data) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Borrow Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject "${data['supplyName']}" request by ${data['borrowerName']}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter rejection reason...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _suppliesService.rejectBorrow(
                  docId,
                  reason: reasonController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Borrow request rejected.'),
                    backgroundColor: Colors.orange,
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
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmReturn(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Returned'),
        content: Text(
          'Mark "${data['supplyName']}" as returned by ${data['borrowerName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _suppliesService.returnSupply(docId);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supply marked as returned!'),
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
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }
}
