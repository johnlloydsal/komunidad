import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/barangay_service.dart';
import 'theme/app_theme.dart';

class BarangayInformationPage extends StatefulWidget {
  const BarangayInformationPage({super.key});

  @override
  State<BarangayInformationPage> createState() =>
      _BarangayInformationPageState();
}

class _BarangayInformationPageState extends State<BarangayInformationPage> {
  final BarangayService _barangayService = BarangayService();

  @override
  void initState() {
    super.initState();
    _barangayService.initializeBarangayInfo();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            "Barangay Information",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Barangay Officials"),
              Tab(text: "Barangay Facilities"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOfficialsTab(),
            _buildFacilitiesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('barangay_officials').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No officials added yet",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Organize officials by position
        final officials = snapshot.data!.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();

        Map<String, dynamic>? captain;
        Map<String, dynamic>? skChairman;
        Map<String, dynamic>? secretary;
        Map<String, dynamic>? treasurer;
        List<Map<String, dynamic>> kagawads = [];
        List<Map<String, dynamic>> others = [];

        for (var official in officials) {
          final position = (official['position'] ?? '').toString().toLowerCase();
          if (position.contains('captain')) {
            captain = official;
          } else if (position.contains('sk') || position.contains('chairman')) {
            skChairman = official;
          } else if (position.contains('secretary')) {
            secretary = official;
          } else if (position.contains('treasurer')) {
            treasurer = official;
          } else if (position.contains('kagawad') || position.contains('tanod')) {
            kagawads.add(official);
          } else {
            others.add(official);
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Title
              const Text(
                'Organizational Structure',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 30),

              // Barangay Captain (Top Level)
              if (captain != null) ...[
                _buildOfficialNode(captain, isCapitain: true),
                const SizedBox(height: 20),
                _buildConnectorLine(),
                const SizedBox(height: 20),
              ],

              // Second Level (Kagawads)
              if (kagawads.isNotEmpty) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: kagawads.map((official) {
                    return _buildOfficialNode(official);
                  }).toList(),
                ),
                const SizedBox(height: 30),
              ],

              // Third Level (SK, Secretary, Treasurer)
              if (skChairman != null || secretary != null || treasurer != null) ...[
                const Divider(thickness: 1),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    if (skChairman != null) _buildOfficialNode(skChairman, width: 160),
                    if (secretary != null) _buildOfficialNode(secretary, width: 160),
                    if (treasurer != null) _buildOfficialNode(treasurer, width: 160),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Others
              if (others.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: others.map((official) {
                    return _buildOfficialNode(official, width: 160);
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectorLine() {
    return Column(
      children: [
        Container(
          width: 2,
          height: 30,
          color: Colors.grey[400],
        ),
        Icon(Icons.arrow_downward, color: Colors.grey[400], size: 20),
      ],
    );
  }

  Widget _buildOfficialNode(Map<String, dynamic> data, {bool isCapitain = false, double? width}) {
    final cardWidth = width ?? (isCapitain ? 200.0 : 160.0);
    
    return Container(
      width: cardWidth,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCapitain ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isCapitain ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(11),
              topRight: Radius.circular(11),
            ),
            child: Container(
              width: double.infinity,
              height: 140,
              color: Colors.grey[200],
              child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                  ? Image.network(
                      data['imageUrl'],
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
                        );
                      },
                    )
                  : Center(
                      child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
                    ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: isCapitain ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data['position'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCapitain ? AppTheme.primaryColor : Colors.blue[700],
                    fontWeight: isCapitain ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _barangayService.streamBarangayFacilities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No facilities available",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Facilities will appear here once added by admin",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final facilities = snapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: _barangayService.streamBarangayInfo(),
          builder: (context, infoSnapshot) {
            String? aboutUs;
            if (infoSnapshot.hasData && infoSnapshot.data!.exists) {
              final data = infoSnapshot.data!.data() as Map<String, dynamic>?;
              aboutUs = data?['description'] as String?;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Us section
                  if (aboutUs != null) ...[
                    _buildSection(
                      title: "About Us",
                      icon: Icons.info_outline,
                      child: Text(
                        aboutUs,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Facilities from barangay_facilities collection
                  _buildSection(
                    title: "Facilities",
                    icon: Icons.business,
                    child: Column(
                      children: _buildFacilitiesFromCollection(facilities),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  List<Widget> _buildFacilitiesFromCollection(List<Map<String, dynamic>> facilities) {
    return facilities.asMap().entries.map((entry) {
      final index = entry.key;
      final facility = entry.value;
      final imageUrl = facility['imageUrl'] ?? facility['image'];
      
      return Column(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              facility['name'] ?? 'Facility',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (facility['location'] != null && facility['location'].toString().isNotEmpty)
            _buildInfoRow(Icons.location_on, facility['location']),
          if (facility['hours'] != null && facility['hours'].toString().isNotEmpty)
            _buildInfoRow(Icons.access_time, facility['hours']),
          if (facility['contact'] != null && facility['contact'].toString().isNotEmpty)
            _buildInfoRow(Icons.phone, facility['contact']),
          if (facility['description'] != null && facility['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                facility['description'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (index < facilities.length - 1) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
        ],
      );
    }).toList();
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
