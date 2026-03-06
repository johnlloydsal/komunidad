import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/report_service.dart';
import 'services/service_request_service.dart';
import 'services/supplies_service.dart';
import 'theme/app_theme.dart';

class ViewMyReportsPage extends StatefulWidget {
  const ViewMyReportsPage({super.key});

  @override
  State<ViewMyReportsPage> createState() => _ViewMyReportsPageState();
}

class _ViewMyReportsPageState extends State<ViewMyReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  final ServiceRequestService _serviceRequestService = ServiceRequestService();
  final SuppliesService _suppliesService = SuppliesService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    final date = timestamp.toDate();
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "My Reports & Borrowed Items",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: "Reports"),
            Tab(text: "Services"),
            Tab(text: "Borrowed Items"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Reports Tab
          _buildReportsList(),
          // Service Requests Tab
          _buildServiceRequestsList(),
          // Borrowed Items Tab
          _buildBorrowedItemsList(),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view reports'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.report_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No reports yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Sort in memory to avoid Firestore composite index requirement
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending order
        });

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

  Widget _buildServiceRequestsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to view service requests'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_requests')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.request_page_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No service requests yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Sort in memory to avoid Firestore composite index requirement
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending order
        });

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

  Widget _buildReportCard(Map<String, dynamic> data, String docId) {
    final status = data['status'] ?? 'pending';
    final category = data['category'] ?? 'General';
    final description = data['description'] ?? 'No description';
    final location = data['location'] ?? 'Unknown';
    final timestamp = data['createdAt'] as Timestamp?;
    final dateStr = _formatDate(timestamp);
    final rating = data['rating'] as int?;
    final feedbackComment = data['feedbackComment'] as String?;
    final assignedToName = data['assignedToName'] as String?;
    
    // DEBUG: Print all fields to see what's actually in Firestore
    print('🔍 DEBUG My Reports Data: ${data.keys.toList()}');
    print('🔍 Status: $status');
    print('🔍 solutionDescription: ${data['solutionDescription']}');
    print('🔍 resolution: ${data['resolution']}');
    print('🔍 actionNotes: ${data['actionNotes']}');
    
    // Support multiple field name variations from admin dashboard
    final solutionDescription = data['solutionDescription'] as String? ?? 
                                 data['resolution'] as String? ?? 
                                 data['solution'] as String?;
    final actionNotes = data['actionNotes'] as String? ?? 
                        data['actionNote'] as String? ?? 
                        data['action_notes'] as String?;
    final isResolved = status.toLowerCase() == 'resolved' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'solved';
    final isActioned = status.toLowerCase() == 'actioned' || status.toLowerCase() == 'in-progress' || status.toLowerCase() == 'in_progress' || status.toLowerCase().replaceAll(' ', '_') == 'in_progress';
    final hasRating = rating != null;
    
    print('🔍 Final solutionDescription: $solutionDescription');
    print('🔍 Final actionNotes: $actionNotes');
    print('🔍 isResolved: $isResolved, isActioned: $isActioned');
    print('---');

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
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            if (assignedToName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: $assignedToName',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            if (actionNotes != null && actionNotes.isNotEmpty && (isActioned || isResolved)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Admin Action Notes:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      actionNotes,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            if (solutionDescription != null && solutionDescription.isNotEmpty && isResolved) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
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
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Admin Resolution:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      solutionDescription,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            // Show rating if exists
            if (hasRating) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Your Rating: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($rating/5)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (feedbackComment != null && feedbackComment.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          feedbackComment,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (isResolved && !hasRating) ...[  
                  OutlinedButton.icon(
                    onPressed: () => _showRatingDialog(docId, data),
                    icon: const Icon(Icons.star_rate, size: 16),
                    label: const Text('Rate', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade700,
                      side: BorderSide(color: Colors.amber.shade700),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton(
                  onPressed: () => _showReportDetails(data),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  onPressed: () => _confirmDeleteReport(docId),
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
    final serviceType =
        data['category'] ??
        'General'; // Use category since that's what service_request uses
    final purpose = data['description'] ?? 'No description specified';
    final timestamp = data['createdAt'] as Timestamp?;
    final dateStr = _formatDate(timestamp);
    final assignedToName = data['assignedToName'] as String?;
    // Support multiple field name variations from admin dashboard
    final solutionDescription = data['solutionDescription'] as String? ?? 
                                 data['resolution'] as String? ?? 
                                 data['solution'] as String?;
    final actionNotes = data['actionNotes'] as String? ?? 
                        data['actionNote'] as String? ?? 
                        data['action_notes'] as String?;
    final rating = data['rating'] as int?;
    final feedbackComment = data['feedbackComment'] as String?;
    final isResolved = status.toLowerCase() == 'resolved' || status.toLowerCase() == 'completed' || status.toLowerCase() == 'fulfilled';
    final isActioned = status.toLowerCase() == 'actioned' || status.toLowerCase() == 'in-progress' || status.toLowerCase() == 'in_progress' || status.toLowerCase().replaceAll(' ', '_') == 'in_progress';
    final hasRating = rating != null;

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
                    serviceType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            if (assignedToName != null) ...[
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: $assignedToName',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Show indicator if service has linked borrowed items
            if (data['hasBorrowedItems'] == true && data['borrowedItemIds'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2, size: 14, color: Colors.purple.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${(data['borrowedItemIds'] as List).length} Borrowed Item(s)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              purpose,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            if (actionNotes != null && actionNotes.isNotEmpty && (isActioned || isResolved)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Admin Action Notes:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      actionNotes,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            if (solutionDescription != null && solutionDescription.isNotEmpty && isResolved) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
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
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Admin Response:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      solutionDescription,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            // Show rating if exists
            if (hasRating) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Your Rating: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($rating/5)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (feedbackComment != null && feedbackComment.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          feedbackComment,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (isResolved && !hasRating) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showServiceRatingDialog(docId, data),
                    icon: const Icon(Icons.star_rate, size: 16),
                    label: const Text('Rate', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade700,
                      side: BorderSide(color: Colors.amber.shade700),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton(
                  onPressed: () => _showServiceRequestDetails(data),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  onPressed: () => _confirmDeleteServiceRequest(docId),
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

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    final statusLower = status.toLowerCase().replaceAll(' ', '-');
    
    switch (statusLower) {
      case 'pending':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        displayText = 'Pending';
        break;
      case 'actioned':
      case 'in-progress':
      case 'in_progress':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        displayText = 'Actioned';
        break;
      case 'resolved':
      case 'completed':
      case 'solved':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        displayText = 'Resolved';
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> data) {
    final rating = data['rating'] as int?;
    final feedbackComment = data['feedbackComment'] as String?;
    final assignedToName = data['assignedToName'] as String?;
    // Support multiple field name variations from admin dashboard
    final solutionDescription = data['solutionDescription'] as String? ?? 
                                 data['resolution'] as String? ?? 
                                 data['solution'] as String?;
    final actionNotes = data['actionNotes'] as String? ?? 
                        data['actionNote'] as String? ?? 
                        data['action_notes'] as String?;
    final mediaUrls = data['mediaUrls'] as List<dynamic>?;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['category'] ?? 'Report Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', data['category']),
              _buildDetailRow('Location', data['location']),
              _buildDetailRow('Status', data['status']),
              _buildDetailRow('Description', data['description']),
              if (data['userName'] != null)
                _buildDetailRow('Submitted by', data['userName']),
              if (assignedToName != null)
                _buildDetailRow('Assigned to', assignedToName),
              if (mediaUrls != null && mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Attached Photos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: mediaUrls.map((url) {
                    return GestureDetector(
                      onTap: () => _showFullImage(url.toString()),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url.toString(),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (actionNotes != null && actionNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Admin Action Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    actionNotes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              if (solutionDescription != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Admin Resolution:',
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
                    solutionDescription,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              if (rating != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Your Feedback:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Rating: ', style: TextStyle(fontSize: 14)),
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        size: 18,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('($rating/5)', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                if (feedbackComment != null && feedbackComment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Comment: $feedbackComment',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
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

  void _showServiceRequestDetails(Map<String, dynamic> data) {
    final assignedToName = data['assignedToName'] as String?;
    // Support multiple field name variations from admin dashboard
    final solutionDescription = data['solutionDescription'] as String? ?? 
                                 data['resolution'] as String? ?? 
                                 data['solution'] as String?;
    final actionNotes = data['actionNotes'] as String? ?? 
                        data['actionNote'] as String? ?? 
                        data['action_notes'] as String?;
    final rating = data['rating'] as int?;
    final feedbackComment = data['feedbackComment'] as String?;
    final status = data['status'] ?? 'pending';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['category'] ?? 'Service Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', data['category']),
              _buildDetailRow('Location', data['location']),
              _buildDetailRow('Status', status),
              _buildDetailRow('Description', data['description']),
              if (data['userName'] != null)
                _buildDetailRow('Requested by', data['userName']),
              if (assignedToName != null)
                _buildDetailRow('Assigned to', assignedToName),
              if (actionNotes != null && actionNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Admin Action Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    actionNotes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              if (solutionDescription != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Admin Response:',
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
                    solutionDescription,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              if (rating != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Your Feedback:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Rating: ', style: TextStyle(fontSize: 14)),
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        size: 18,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('($rating/5)', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                if (feedbackComment != null && feedbackComment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Comment: $feedbackComment',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
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

  void _showRatingDialog(String reportId, Map<String, dynamic> reportData) {
    int selectedRating = 0;
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          title: const Text(
            'Rate Resolution',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How satisfied are you with the resolution?',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRating = starIndex;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            selectedRating >= starIndex
                                ? Icons.star
                                : Icons.star_border,
                            color: selectedRating >= starIndex
                                ? Colors.amber
                                : Colors.grey,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedRating > 0
                        ? _getRatingText(selectedRating)
                        : 'Tap a star to rate',
                    style: TextStyle(
                      fontSize: 11,
                      color: selectedRating > 0
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      fontWeight: selectedRating > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Feedback Comment
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Feedback (Optional)',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintText: 'Your thoughts...',
                      hintStyle: const TextStyle(fontSize: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(10),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      try {
                        await _reportService.submitFeedbackRating(
                          reportId: reportId,
                          rating: selectedRating,
                          feedbackComment: feedbackController.text.trim().isEmpty
                              ? null
                              : feedbackController.text.trim(),
                        );

                        if (!mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Thank you for your feedback!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error submitting rating: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  void _showServiceRatingDialog(String requestId, Map<String, dynamic> requestData) {
    int selectedRating = 0;
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          title: const Text(
            'Rate Service Resolution',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How satisfied are you with the service?',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRating = starIndex;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            selectedRating >= starIndex
                                ? Icons.star
                                : Icons.star_border,
                            color: selectedRating >= starIndex
                                ? Colors.amber
                                : Colors.grey,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedRating > 0
                        ? _getRatingText(selectedRating)
                        : 'Tap a star to rate',
                    style: TextStyle(
                      fontSize: 11,
                      color: selectedRating > 0
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      fontWeight: selectedRating > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Feedback Comment
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Feedback (Optional)',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintText: 'Your thoughts...',
                      hintStyle: const TextStyle(fontSize: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(10),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      try {
                        await _serviceRequestService.submitFeedbackRating(
                          requestId: requestId,
                          rating: selectedRating,
                          feedbackComment: feedbackController.text.trim().isEmpty
                              ? null
                              : feedbackController.text.trim(),
                        );

                        if (!mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Thank you for your feedback!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error submitting rating: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
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
          Text(value ?? 'N/A', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // Delete confirmation for reports
  void _confirmDeleteReport(String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteReport(reportId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      await _reportService.deleteReport(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete confirmation for service requests
  void _confirmDeleteServiceRequest(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service Request'),
        content: const Text('Are you sure you want to delete this service request? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteServiceRequest(requestId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteServiceRequest(String requestId) async {
    try {
      await _serviceRequestService.deleteServiceRequest(requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service request deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting service request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Borrowed Items List
  Widget _buildBorrowedItemsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _suppliesService.streamUserBorrowedSupplies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No borrowed items',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Borrow supplies via Service Request',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final borrowedItems = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: borrowedItems.length,
          itemBuilder: (context, index) {
            final item = borrowedItems[index];
            return _buildBorrowedItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildBorrowedItemCard(Map<String, dynamic> item) {
    final supplyName = item['supplyName'] ?? 'Unknown Item';
    final quantity = item['quantity'] ?? 0;
    final status = item['status'] ?? 'pending';
    final purpose = item['purpose'] ?? '';
    final borrowedAt = (item['requestedAt'] ?? item['borrowedAt']) as Timestamp?;
    final returnedAt = item['returnedAt'] as Timestamp?;
    // Support multiple field name variations from admin dashboard
    final actionNotes = item['actionNotes'] as String? ?? 
                        item['actionNote'] as String? ?? 
                        item['action_notes'] as String?;
    final isReturned = status == 'returned';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';
    final isBorrowed = status == 'borrowed' || status.toLowerCase() == 'actioned';
    final isActioned = status.toLowerCase() == 'actioned';
    final rejectionReason = item['rejectionReason'] as String?;

    // Status badge colors
    Color badgeColor;
    Color badgeTextColor;
    String badgeText;
    if (isPending) {
      badgeColor = Colors.orange.shade100;
      badgeTextColor = Colors.orange.shade900;
      badgeText = 'PENDING';
    } else if (isRejected) {
      badgeColor = Colors.red.shade100;
      badgeTextColor = Colors.red.shade900;
      badgeText = 'REJECTED';
    } else if (isReturned) {
      badgeColor = Colors.green.shade100;
      badgeTextColor = Colors.green.shade900;
      badgeText = 'RETURNED';
    } else if (isActioned) {
      badgeColor = Colors.blue.shade100;
      badgeTextColor = Colors.blue.shade900;
      badgeText = 'ACTIONED';
    } else {
      badgeColor = Colors.blue.shade100;
      badgeTextColor = Colors.blue.shade900;
      badgeText = 'BORROWED';
    }

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
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          supplyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
            // Show indicator if borrowed item is linked to service request
            if (item['serviceRequestId'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 12, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Linked to Funeral Assistance Service',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Waiting for admin approval',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isRejected && rejectionReason != null && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: $rejectionReason',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if ((isBorrowed || isActioned) && actionNotes != null && actionNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Admin Action Notes:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      actionNotes,
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.numbers, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text(
                        'Quantity: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (purpose.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        const Text(
                          'Purpose: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            purpose,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        isPending ? 'Requested: ' : 'Borrowed: ',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        _formatDate(borrowedAt),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (isReturned && returnedAt != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        const Text(
                          'Returned: ',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          _formatDate(returnedAt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Delete button for rejected or returned items
            if (isRejected || isReturned) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteBorrowedItem(item['id'], supplyName),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete Record'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBorrowedItem(String borrowedId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
          'Are you sure you want to delete the record for "$itemName"?\\n\\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBorrowedItem(borrowedId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBorrowedItem(String borrowedId) async {
    try {
      await _suppliesService.deleteBorrowedItem(borrowedId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Borrowed item record deleted successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
}
