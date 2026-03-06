import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Stream announcements from Firestore
  Stream<List<Announcement>> streamAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Announcement.fromFirestore(doc);
      }).toList();
    });
  }

  // Get announcements by category (case-insensitive)
  Stream<List<Announcement>> streamAnnouncementsByCategory(String category) {
    final categoryLower = category.toLowerCase();
    return _firestore
        .collection('announcements')
        .snapshots()
        .map((snapshot) {
      final filtered = snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .where((announcement) => 
              announcement.category.toLowerCase() == categoryLower)
          .toList();
      
      // Sort by createdAt descending (newest first)
      filtered.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      return filtered;
    });
  }

  // Add new announcement (admin only)
  Future<void> createAnnouncement({
    required String title,
    required String description,
    required String category,
    String? imageUrl,
    String? source,
  }) async {
    await _firestore.collection('announcements').add({
      'title': title,
      'content': description,
      'category': category,
      'imageUrl': imageUrl,
      'source': source ?? 'Barangay Hall',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Notify all approved users about new announcement
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('accountStatus', whereIn: ['approved', 'active'])
          .get();
      
      for (var userDoc in usersSnapshot.docs) {
        await _notificationService.sendNotificationToUser(
          userId: userDoc.id,
          title: '📢 New $category Announcement',
          body: title,
          type: 'news',
        );
      }
    } catch (e) {
      print('⚠️ Error sending announcement notifications: $e');
    }
  }

  // Update announcement
  Future<void> updateAnnouncement({
    required String announcementId,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
  }) async {
    Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['content'] = description;
    if (category != null) updates['category'] = category;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;

    await _firestore
        .collection('announcements')
        .doc(announcementId)
        .update(updates);
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).delete();
  }
}

class Announcement {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.source,
    this.createdAt,
    this.updatedAt,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['content'] ?? data['description'] ?? '',
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'],
      source: data['source'] ?? 'Barangay Hall',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': description,
      'category': category,
      'imageUrl': imageUrl,
      'source': source,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
