// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import '../models/lost_item_model.dart';
// import '../models/found_item_model.dart';
// import '../models/match_model.dart';
// import '../models/notification_model.dart';
// import '../models/user_model.dart';
// import '../utils/constants.dart';
//
// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final Uuid _uuid = const Uuid();
//
//   // ─── LOST ITEMS ──────────────────────────────────────────────────────────────
//
//   Future<LostItemModel> reportLostItem({
//     required String userId,
//     required String itemName,
//     required String secretIdentificationDetail,
//     required List<String> possibleLocations,
//     String? photoURL,
//     String? description,
//     String? category,
//   }) async {
//     final id = _uuid.v4();
//     final item = LostItemModel(
//       lostItemId: id,
//       userId: userId,
//       itemName: itemName,
//       photoURL: photoURL,
//       secretIdentificationDetail: secretIdentificationDetail,
//       possibleLocations: possibleLocations,
//       status: AppConstants.statusPending,
//       createdAt: DateTime.now(),
//       description: description,
//       category: category,
//     );
//
//     await _db
//         .collection(AppConstants.lostItemsCollection)
//         .doc(id)
//         .set(item.toFirestore());
//
//     return item;
//   }
//
//   Stream<List<LostItemModel>> getLostItemsByUser(String userId) {
//     return _db
//         .collection(AppConstants.lostItemsCollection)
//         .where('userId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
//   }
//
//   Stream<List<LostItemModel>> getAllLostItems() {
//     return _db
//         .collection(AppConstants.lostItemsCollection)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
//   }
//
//   Stream<List<LostItemModel>> getPendingLostItems() {
//     return _db
//         .collection(AppConstants.lostItemsCollection)
//         .where('status', isEqualTo: AppConstants.statusPending)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
//   }
//
//   Future<void> updateLostItemStatus(String id, String status) async {
//     await _db
//         .collection(AppConstants.lostItemsCollection)
//         .doc(id)
//         .update({'status': status});
//   }
//
//   // ─── FOUND ITEMS ─────────────────────────────────────────────────────────────
//
//   Future<FoundItemModel> reportFoundItem({
//     required String finderId,
//     required String photoURL,
//     required String description,
//     required String locationFound,
//     required String storageOption,
//     String? category,
//     String? finderName,
//   }) async {
//     final id = _uuid.v4();
//     final item = FoundItemModel(
//       foundItemId: id,
//       finderId: finderId,
//       photoURL: photoURL,
//       description: description,
//       locationFound: locationFound,
//       storageOption: storageOption,
//       status: AppConstants.statusPending,
//       createdAt: DateTime.now(),
//       category: category,
//       finderName: finderName,
//     );
//
//     await _db
//         .collection(AppConstants.foundItemsCollection)
//         .doc(id)
//         .set(item.toFirestore());
//
//     // Notify all verifiers about new found item
//     await _notifyVerifiers(
//       title: 'New Found Item Reported',
//       body: '${finderName ?? 'Someone'} found an item: $description',
//       type: 'new_found_item',
//       data: {'foundItemId': id},
//     );
//
//     return item;
//   }
//
//   Stream<List<FoundItemModel>> getFoundItemsByUser(String userId) {
//     return _db
//         .collection(AppConstants.foundItemsCollection)
//         .where('finderId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
//   }
//
//   Stream<List<FoundItemModel>> getAllFoundItems() {
//     return _db
//         .collection(AppConstants.foundItemsCollection)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
//   }
//
//   Stream<List<FoundItemModel>> getPendingFoundItems() {
//     return _db
//         .collection(AppConstants.foundItemsCollection)
//         .where('status', isEqualTo: AppConstants.statusPending)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
//   }
//
//   Future<void> updateFoundItemStatus(String id, String status) async {
//     await _db
//         .collection(AppConstants.foundItemsCollection)
//         .doc(id)
//         .update({'status': status});
//   }
//
//   // ─── MATCHES ─────────────────────────────────────────────────────────────────
//
//   Future<MatchModel> approveMatch({
//     required String lostItemId,
//     required String foundItemId,
//     required String verifierId,
//     String? notes,
//   }) async {
//     final id = _uuid.v4();
//     final match = MatchModel(
//       matchId: id,
//       lostItemId: lostItemId,
//       foundItemId: foundItemId,
//       approvedByVerifierId: verifierId,
//       approvedAt: DateTime.now(),
//       status: 'approved',
//       notes: notes,
//     );
//
//     final batch = _db.batch();
//
//     // Create match record
//     batch.set(_db.collection(AppConstants.matchesCollection).doc(id),
//         match.toFirestore());
//
//     // Update lost item status
//     batch.update(
//         _db.collection(AppConstants.lostItemsCollection).doc(lostItemId),
//         {'status': AppConstants.statusMatched});
//
//     // Update found item status
//     batch.update(
//         _db.collection(AppConstants.foundItemsCollection).doc(foundItemId),
//         {'status': AppConstants.statusMatched});
//
//     await batch.commit();
//
//     // Notify the owner of the lost item
//     final lostDoc = await _db
//         .collection(AppConstants.lostItemsCollection)
//         .doc(lostItemId)
//         .get();
//     if (lostDoc.exists) {
//       final lostItem = LostItemModel.fromFirestore(lostDoc);
//       await _createNotification(
//         userId: lostItem.userId,
//         title: 'Your item has been matched!',
//         body:
//         'Great news! Your lost item "${lostItem.itemName}" has been matched. Please visit the campus security office to claim it.',
//         type: 'match_approved',
//         data: {'matchId': id, 'lostItemId': lostItemId},
//       );
//     }
//
//     return match;
//   }
//
//   Stream<List<MatchModel>> getAllMatches() {
//     return _db
//         .collection(AppConstants.matchesCollection)
//         .orderBy('approvedAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => MatchModel.fromFirestore(d)).toList());
//   }
//
//   // ─── NOTIFICATIONS ───────────────────────────────────────────────────────────
//
//   Future<void> _createNotification({
//     required String userId,
//     required String title,
//     required String body,
//     required String type,
//     Map<String, dynamic>? data,
//   }) async {
//     final id = _uuid.v4();
//     final notif = NotificationModel(
//       id: id,
//       userId: userId,
//       title: title,
//       body: body,
//       type: type,
//       isRead: false,
//       createdAt: DateTime.now(),
//       data: data,
//     );
//     await _db
//         .collection(AppConstants.notificationsCollection)
//         .doc(id)
//         .set(notif.toFirestore());
//   }
//
//   Future<void> _notifyVerifiers({
//     required String title,
//     required String body,
//     required String type,
//     Map<String, dynamic>? data,
//   }) async {
//     // Get all verifiers and admin
//     final snapshot = await _db
//         .collection(AppConstants.usersCollection)
//         .where('role', whereIn: ['verifier', 'admin']).get();
//
//     final batch = _db.batch();
//     for (final doc in snapshot.docs) {
//       final id = const Uuid().v4();
//       batch.set(
//         _db.collection(AppConstants.notificationsCollection).doc(id),
//         {
//           'userId': doc.id,
//           'title': title,
//           'body': body,
//           'type': type,
//           'isRead': false,
//           'createdAt': Timestamp.now(),
//           'data': data,
//         },
//       );
//     }
//     await batch.commit();
//   }
//
//   Stream<List<NotificationModel>> getNotificationsForUser(String userId) {
//     return _db
//         .collection(AppConstants.notificationsCollection)
//         .where('userId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .limit(50)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
//   }
//
//   Future<void> markNotificationRead(String id) async {
//     await _db
//         .collection(AppConstants.notificationsCollection)
//         .doc(id)
//         .update({'isRead': true});
//   }
//
//   Future<void> markAllNotificationsRead(String userId) async {
//     final snap = await _db
//         .collection(AppConstants.notificationsCollection)
//         .where('userId', isEqualTo: userId)
//         .where('isRead', isEqualTo: false)
//         .get();
//
//     final batch = _db.batch();
//     for (final doc in snap.docs) {
//       batch.update(doc.reference, {'isRead': true});
//     }
//     await batch.commit();
//   }
//
//   // ─── ANALYTICS ───────────────────────────────────────────────────────────────
//
//   Future<Map<String, int>> getAnalytics() async {
//     final results = await Future.wait([
//       _db.collection(AppConstants.lostItemsCollection).count().get(),
//       _db.collection(AppConstants.foundItemsCollection).count().get(),
//       _db.collection(AppConstants.matchesCollection).count().get(),
//       _db
//           .collection(AppConstants.lostItemsCollection)
//           .where('status', isEqualTo: AppConstants.statusPending)
//           .count()
//           .get(),
//       _db
//           .collection(AppConstants.foundItemsCollection)
//           .where('status', isEqualTo: AppConstants.statusPending)
//           .count()
//           .get(),
//       _db
//           .collection(AppConstants.usersCollection)
//           .where('role', isEqualTo: AppConstants.roleUser)
//           .count()
//           .get(),
//     ]);
//
//     return {
//       'totalLost': results[0].count ?? 0,
//       'totalFound': results[1].count ?? 0,
//       'totalMatched': results[2].count ?? 0,
//       'pendingLost': results[3].count ?? 0,
//       'pendingFound': results[4].count ?? 0,
//       'totalUsers': results[5].count ?? 0,
//     };
//   }
//
//   // Get all users
//   Stream<List<UserModel>> getAllUsers() {
//     return _db
//         .collection(AppConstants.usersCollection)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
//   }
//
//   // ─── VERIFIERS ───────────────────────────────────────────────────────────────
//
//   Stream<List<UserModel>> getVerifiers() {
//     return _db
//         .collection(AppConstants.usersCollection)
//         .where('role', isEqualTo: AppConstants.roleVerifier)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
//   }
//
//   Future<void> deleteVerifier(String uid) async {
//     await _db
//         .collection(AppConstants.usersCollection)
//         .doc(uid)
//         .delete();
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/lost_item_model.dart';
import '../models/found_item_model.dart';
import '../models/match_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // ─── LOST ITEMS ──────────────────────────────────────────────────────────────

  Future<LostItemModel> reportLostItem({
    required String userId,
    required String itemName,
    required String secretIdentificationDetail,
    required List<String> possibleLocations,
    String? photoURL,
    String? description,
    String? category,
  }) async {
    final id = _uuid.v4();
    final item = LostItemModel(
      lostItemId: id,
      userId: userId,
      itemName: itemName,
      photoURL: photoURL,
      secretIdentificationDetail: secretIdentificationDetail,
      possibleLocations: possibleLocations,
      status: AppConstants.statusPending,
      createdAt: DateTime.now(),
      description: description,
      category: category,
    );

    await _db
        .collection(AppConstants.lostItemsCollection)
        .doc(id)
        .set(item.toFirestore());

    return item;
  }

  Stream<List<LostItemModel>> getLostItemsByUser(String userId) {
    return _db
        .collection(AppConstants.lostItemsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
  }

  Stream<List<LostItemModel>> getAllLostItems() {
    return _db
        .collection(AppConstants.lostItemsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
  }

  Stream<List<LostItemModel>> getPendingLostItems() {
    return _db
        .collection(AppConstants.lostItemsCollection)
        .where('status', isEqualTo: AppConstants.statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
  }

  Future<void> updateLostItemStatus(String id, String status) async {
    await _db
        .collection(AppConstants.lostItemsCollection)
        .doc(id)
        .update({'status': status});
  }

  // ─── FOUND ITEMS ─────────────────────────────────────────────────────────────

  Future<FoundItemModel> reportFoundItem({
    required String finderId,
    required String photoURL,
    required String description,
    required String locationFound,
    required String storageOption,
    String? category,
    String? finderName,
  }) async {
    final id = _uuid.v4();
    final item = FoundItemModel(
      foundItemId: id,
      finderId: finderId,
      photoURL: photoURL,
      description: description,
      locationFound: locationFound,
      storageOption: storageOption,
      status: AppConstants.statusPending,
      createdAt: DateTime.now(),
      category: category,
      finderName: finderName,
    );

    await _db
        .collection(AppConstants.foundItemsCollection)
        .doc(id)
        .set(item.toFirestore());

    // Notify all verifiers about new found item
    await _notifyVerifiers(
      title: 'New Found Item Reported',
      body: '${finderName ?? 'Someone'} found an item: $description',
      type: 'new_found_item',
      data: {'foundItemId': id},
    );

    return item;
  }

  Stream<List<FoundItemModel>> getFoundItemsByUser(String userId) {
    return _db
        .collection(AppConstants.foundItemsCollection)
        .where('finderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
  }

  Stream<List<FoundItemModel>> getAllFoundItems() {
    return _db
        .collection(AppConstants.foundItemsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
  }

  Stream<List<FoundItemModel>> getPendingFoundItems() {
    return _db
        .collection(AppConstants.foundItemsCollection)
        .where('status', isEqualTo: AppConstants.statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
  }

  Future<void> updateFoundItemStatus(String id, String status) async {
    await _db
        .collection(AppConstants.foundItemsCollection)
        .doc(id)
        .update({'status': status});
  }

  // ─── MATCHES ─────────────────────────────────────────────────────────────────

  Future<MatchModel> approveMatch({
    required String lostItemId,
    required String foundItemId,
    required String verifierId,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final match = MatchModel(
      matchId: id,
      lostItemId: lostItemId,
      foundItemId: foundItemId,
      approvedByVerifierId: verifierId,
      approvedAt: DateTime.now(),
      status: 'approved',
      notes: notes,
    );

    final batch = _db.batch();

    // Create match record
    batch.set(_db.collection(AppConstants.matchesCollection).doc(id),
        match.toFirestore());

    // Update lost item status
    batch.update(
        _db.collection(AppConstants.lostItemsCollection).doc(lostItemId),
        {'status': AppConstants.statusMatched});

    // Update found item status
    batch.update(
        _db.collection(AppConstants.foundItemsCollection).doc(foundItemId),
        {'status': AppConstants.statusMatched});

    await batch.commit();

    // Notify the owner of the lost item
    final lostDoc = await _db
        .collection(AppConstants.lostItemsCollection)
        .doc(lostItemId)
        .get();
    if (lostDoc.exists) {
      final lostItem = LostItemModel.fromFirestore(lostDoc);
      await _createNotification(
        userId: lostItem.userId,
        title: 'Your item has been matched!',
        body:
        'Great news! Your lost item "${lostItem.itemName}" has been matched. Please visit the campus security office to claim it.',
        type: 'match_approved',
        data: {'matchId': id, 'lostItemId': lostItemId},
      );
    }

    return match;
  }

  Stream<List<MatchModel>> getAllMatches() {
    return _db
        .collection(AppConstants.matchesCollection)
        .orderBy('approvedAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => MatchModel.fromFirestore(d)).toList());
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final id = _uuid.v4();
    final notif = NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      data: data,
    );
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(id)
        .set(notif.toFirestore());
  }

  Future<void> _notifyVerifiers({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all verifiers and admin
      final snapshot = await _db
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['verifier', 'admin']).get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        final id = const Uuid().v4();
        batch.set(
          _db.collection(AppConstants.notificationsCollection).doc(id),
          {
            'userId': doc.id,
            'title': title,
            'body': body,
            'type': type,
            'isRead': false,
            'createdAt': Timestamp.now(),
            'data': data,
          },
        );
      }
      await batch.commit();
    } catch (_) {
      // Notification failure should not block the main submission
    }
  }

  Stream<List<NotificationModel>> getNotificationsForUser(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  Future<void> markNotificationRead(String id) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(id)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── ANALYTICS ───────────────────────────────────────────────────────────────

  Future<Map<String, int>> getAnalytics() async {
    final results = await Future.wait([
      _db.collection(AppConstants.lostItemsCollection).count().get(),
      _db.collection(AppConstants.foundItemsCollection).count().get(),
      _db.collection(AppConstants.matchesCollection).count().get(),
      _db
          .collection(AppConstants.lostItemsCollection)
          .where('status', isEqualTo: AppConstants.statusPending)
          .count()
          .get(),
      _db
          .collection(AppConstants.foundItemsCollection)
          .where('status', isEqualTo: AppConstants.statusPending)
          .count()
          .get(),
      _db
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleUser)
          .count()
          .get(),
    ]);

    return {
      'totalLost': results[0].count ?? 0,
      'totalFound': results[1].count ?? 0,
      'totalMatched': results[2].count ?? 0,
      'pendingLost': results[3].count ?? 0,
      'pendingFound': results[4].count ?? 0,
      'totalUsers': results[5].count ?? 0,
    };
  }

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // ─── VERIFIERS ───────────────────────────────────────────────────────────────

  Stream<List<UserModel>> getVerifiers() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleVerifier)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  Future<void> deleteVerifier(String uid) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
  }
}