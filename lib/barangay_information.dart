import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/barangay_service.dart';
import 'services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BarangayInformationPage extends StatefulWidget {
  const BarangayInformationPage({super.key});

  @override
  State<BarangayInformationPage> createState() =>
      _BarangayInformationPageState();
}

class _BarangayInformationPageState extends State<BarangayInformationPage> {
  final BarangayService _barangayService = BarangayService();
  final UserService _userService = UserService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _barangayService.initializeBarangayInfo();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
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
          "Barangay Information",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          if (_isAdmin && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
              onPressed: () => _showEditDialog(),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _barangayService.streamBarangayInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "No barangay information available",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                _buildSection(
                  title: "About Us",
                  icon: Icons.info_outline,
                  child: Text(
                    data['description'] ?? 'No description available',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),

                const SizedBox(height: 20),

                // Facilities
                _buildSection(
                  title: "Facilities",
                  icon: Icons.business,
                  child: Column(
                    children: _buildFacilitiesList(
                      data['facilities'] as Map<String, dynamic>? ?? {},
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Officials
                _buildSection(
                  title: "Barangay Officials",
                  icon: Icons.people,
                  child: _buildOfficialsList(
                    data['officials'] as Map<String, dynamic>? ?? {},
                  ),
                ),

                const SizedBox(height: 20),

                // Contact Info
                _buildSection(
                  title: "Contact Information",
                  icon: Icons.contact_phone,
                  child: _buildContactInfo(
                    data['contactInfo'] as Map<String, dynamic>? ?? {},
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
              Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
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

  List<Widget> _buildFacilitiesList(Map<String, dynamic> facilities) {
    return facilities.entries.map((entry) {
      final facility = entry.value as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              facility['name'] ?? 'Facility',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 4),
            if (facility['address'] != null)
              _buildInfoRow(Icons.location_on, facility['address']),
            if (facility['hours'] != null)
              _buildInfoRow(Icons.access_time, facility['hours']),
            if (facility['contact'] != null)
              _buildInfoRow(Icons.phone, facility['contact']),
            if (entry.key != facilities.keys.last) const Divider(height: 20),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildOfficialsList(Map<String, dynamic> officials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (officials['captain'] != null)
          _buildOfficialItem('Barangay Captain', officials['captain']),
        if (officials['kagawads'] != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Kagawads:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...((officials['kagawads'] as List).map(
            (name) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text('• $name'),
            ),
          )),
        ],
        if (officials['skChairman'] != null) ...[
          const SizedBox(height: 8),
          _buildOfficialItem('SK Chairman', officials['skChairman']),
        ],
        if (officials['secretary'] != null)
          _buildOfficialItem('Secretary', officials['secretary']),
        if (officials['treasurer'] != null)
          _buildOfficialItem('Treasurer', officials['treasurer']),
      ],
    );
  }

  Widget _buildOfficialItem(String position, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$position: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(name),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Map<String, dynamic> contact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contact['phone'] != null)
          _buildInfoRow(Icons.phone, contact['phone']),
        if (contact['email'] != null)
          _buildInfoRow(Icons.email, contact['email']),
        if (contact['address'] != null)
          _buildInfoRow(Icons.location_city, contact['address']),
      ],
    );
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

  void _showEditDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Admin edit feature coming soon! For now, update via Firebase Console.',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
