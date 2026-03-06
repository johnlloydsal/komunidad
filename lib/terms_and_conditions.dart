import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E3A8A),
                      const Color(0xFF1E3A8A).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Terms and Conditions",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "KOMUNIDAD App",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction Card
                  _buildIntroCard(),
                  const SizedBox(height: 20),

                  // Sections
                  _buildSection(
                    number: '1',
                    icon: Icons.assignment_ind,
                    title: 'User Responsibilities',
                    content:
                        'Users must provide accurate information when creating an account and submitting reports or service requests. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                    color: Colors.blue,
                  ),

                  _buildSection(
                    number: '2',
                    icon: Icons.verified_user,
                    title: 'Account Registration and Verification',
                    content:
                        'To access the full features of KOMUNIDAD, users must register with a valid email address or Google account. Users may be required to submit valid identification for verification purposes. All user accounts are subject to admin approval before gaining full access to the application.',
                    color: Colors.green,
                  ),

                  _buildSection(
                    number: '3',
                    icon: Icons.settings,
                    title: 'Services Offered',
                    content:
                        'KOMUNIDAD provides the following services:\n\n'
                        '• Report issues within the barangay\n'
                        '• Request barangay services and assistance\n'
                        '• Borrow barangay supplies\n'
                        '• Report and search for lost and found items\n'
                        '• View barangay announcements and news\n'
                        '• Access barangay information and hotlines',
                    color: Colors.purple,
                  ),

                  _buildSection(
                    number: '4',
                    icon: Icons.rule,
                    title: 'Proper Use of the Application',
                    content:
                        'Users agree to use KOMUNIDAD only for lawful purposes. The following activities are strictly prohibited:\n\n'
                        '• Submitting false or misleading reports\n'
                        '• Harassment or abuse of barangay officials or other users\n'
                        '• Unauthorized access to other user accounts\n'
                        '• Uploading malicious content or spam\n'
                        '• Using the app for commercial purposes without authorization',
                    color: Colors.red,
                  ),

                  _buildSection(
                    number: '5',
                    icon: Icons.privacy_tip,
                    title: 'Data Privacy and Security',
                    content:
                        'We are committed to protecting your personal information. All data collected through KOMUNIDAD is used solely for barangay management purposes. Your information will not be shared with third parties without your consent, except as required by law.',
                    color: Colors.orange,
                  ),

                  _buildSection(
                    number: '6',
                    icon: Icons.support_agent,
                    title: 'Report and Request Handling',
                    content:
                        'All reports and service requests submitted through KOMUNIDAD will be reviewed by barangay administrators. While we strive to address all submissions promptly, the barangay does not guarantee specific response times or outcomes. Users will be notified of the status of their submissions through the app.',
                    color: Colors.teal,
                  ),

                  _buildSection(
                    number: '7',
                    icon: Icons.cloud_upload,
                    title: 'User-Generated Content',
                    content:
                        'By submitting content (reports, photos, comments, etc.) through KOMUNIDAD, you grant the barangay administration a non-exclusive right to use, display, and store this content for the purpose of addressing community issues and managing barangay operations.',
                    color: Colors.indigo,
                  ),

                  _buildSection(
                    number: '8',
                    icon: Icons.update,
                    title: 'Modifications to Terms',
                    content:
                        'The barangay reserves the right to modify these terms and conditions at any time. Users will be notified of significant changes through the application. Continued use of KOMUNIDAD after changes constitutes acceptance of the updated terms.',
                    color: Colors.cyan,
                  ),

                  _buildSection(
                    number: '9',
                    icon: Icons.block,
                    title: 'Account Termination',
                    content:
                        'The barangay administration reserves the right to suspend or terminate user accounts that violate these terms and conditions or engage in activities that harm the community or the integrity of the application.',
                    color: Colors.deepOrange,
                  ),

                  _buildSection(
                    number: '10',
                    icon: Icons.gavel,
                    title: 'Limitation of Liability',
                    content:
                        'KOMUNIDAD is provided "as is" without warranties of any kind. The barangay administration is not liable for any damages arising from the use or inability to use the application, including but not limited to lost data, service interruptions, or errors in the application.',
                    color: Colors.brown,
                  ),

                  _buildSection(
                    number: '11',
                    icon: Icons.contact_support,
                    title: 'Contact Information',
                    content:
                        'For questions or concerns about these terms and conditions, please contact the barangay administration through the app or visit the barangay office during business hours.',
                    color: Colors.blueGrey,
                  ),

                  // Acceptance Card
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E3A8A),
                          const Color(0xFF1E3A8A).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.handshake,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Acceptance of Terms',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'By creating an account and using KOMUNIDAD, you acknowledge that you have read, understood, and agree to be bound by these terms and conditions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Last Updated
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Last Updated: February 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Welcome to KOMUNIDAD',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'KOMUNIDAD is a barangay management application designed to enhance communication between residents and the barangay administration. By using this application, you agree to comply with and be bound by the following terms and conditions.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$number. $title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}
