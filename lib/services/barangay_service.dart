import 'package:cloud_firestore/cloud_firestore.dart';

class BarangayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get barangay information
  Stream<DocumentSnapshot> streamBarangayInfo() {
    return _firestore.collection('barangay_info').doc('main').snapshots();
  }

  // Update barangay information (admin only)
  Future<void> updateBarangayInfo({
    required String description,
    required Map<String, dynamic> facilities,
    required Map<String, dynamic> officials,
    required Map<String, dynamic> contactInfo,
  }) async {
    try {
      await _firestore.collection('barangay_info').doc('main').set({
        'description': description,
        'facilities': facilities,
        'officials': officials,
        'contactInfo': contactInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Barangay info updated successfully!');
    } catch (e) {
      print('❌ Error updating barangay info: $e');
      rethrow;
    }
  }

  // Initialize default barangay data if not exists
  Future<void> initializeBarangayInfo() async {
    try {
      final doc = await _firestore
          .collection('barangay_info')
          .doc('main')
          .get();

      if (!doc.exists) {
        await _firestore.collection('barangay_info').doc('main').set({
          'description':
              'Welcome to our Barangay! We are committed to serving our community.',
          'facilities': {
            'barangayHall': {
              'name': 'Barangay Hall',
              'address': 'Main Street, Barangay Center',
              'hours': 'Monday-Friday, 8:00 AM - 5:00 PM',
              'contact': '123-4567',
            },
            'gym': {
              'name': 'Barangay Gymnasium',
              'address': 'Sports Complex, Zone 3',
              'hours': 'Monday-Sunday, 6:00 AM - 8:00 PM',
              'contact': '123-4568',
            },
            'daycare': {
              'name': 'Barangay Daycare Center',
              'address': 'Education Center, Zone 2',
              'hours': 'Monday-Friday, 7:00 AM - 5:00 PM',
              'contact': '123-4569',
            },
            'healthCenter': {
              'name': 'Barangay Health Center',
              'address': 'Health Complex, Zone 1',
              'hours': 'Monday-Saturday, 8:00 AM - 4:00 PM',
              'contact': '123-4570',
            },
          },
          'officials': {
            'captain': 'Captain Name',
            'kagawads': [
              'Kagawad 1',
              'Kagawad 2',
              'Kagawad 3',
              'Kagawad 4',
              'Kagawad 5',
              'Kagawad 6',
              'Kagawad 7',
            ],
            'skChairman': 'SK Chairman Name',
            'secretary': 'Secretary Name',
            'treasurer': 'Treasurer Name',
          },
          'contactInfo': {
            'phone': '(123) 456-7890',
            'email': 'barangay@example.com',
            'address': 'Barangay Main Office, City',
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Default barangay info initialized');
      }
    } catch (e) {
      print('❌ Error initializing barangay info: $e');
    }
  }
}
