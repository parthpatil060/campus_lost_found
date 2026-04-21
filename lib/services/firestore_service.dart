
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import '../models/lost_item_model.dart';
// import '../models/found_item_model.dart';
// import '../models/match_model.dart';
// import '../models/notification_model.dart';
// import '../models/user_model.dart';
// import '../utils/constants.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final Uuid _uuid = const Uuid();

//   // ─── LOST ITEMS ──────────────────────────────────────────────────────────────

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

//     await _db
//         .collection(AppConstants.lostItemsCollection)
//         .doc(id)
//         .set(item.toFirestore());

//     return item;
//   }

//   Stream<List<LostItemModel>> getLostItemsByUser(String userId) {
//     return _db
//         .collection(AppConstants.lostItemsCollection)
//         .where('userId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
//   }

//   Stream<List<LostItemModel>> getAllLostItems() {
//     return _db
//         .collection(AppConstants.lostItemsCollection)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
//   }

//   Stream<List<LostItemModel>> getPendingLostItems() {
//     return _db
//         .collection(AppConstants.lostItemsCollection)
//         .where('status', isEqualTo: AppConstants.statusPending)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => LostItemModel.fromFirestore(d)).toList());
//   }

//   Future<void> updateLostItemStatus(String id, String status) async {
//     await _db
//         .collection(AppConstants.lostItemsCollection)
//         .doc(id)
//         .update({'status': status});
//   }

//   // ─── FOUND ITEMS ─────────────────────────────────────────────────────────────

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

//     await _db
//         .collection(AppConstants.foundItemsCollection)
//         .doc(id)
//         .set(item.toFirestore());

//     // Notify all verifiers about new found item
//     await _notifyVerifiers(
//       title: 'New Found Item Reported',
//       body: '${finderName ?? 'Someone'} found an item: $description',
//       type: 'new_found_item',
//       data: {'foundItemId': id},
//     );

//     return item;
//   }

//   Stream<List<FoundItemModel>> getFoundItemsByUser(String userId) {
//     return _db
//         .collection(AppConstants.foundItemsCollection)
//         .where('finderId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
//   }

//   Stream<List<FoundItemModel>> getAllFoundItems() {
//     return _db
//         .collection(AppConstants.foundItemsCollection)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
//   }

//   Stream<List<FoundItemModel>> getPendingFoundItems() {
//     return _db
//         .collection(AppConstants.foundItemsCollection)
//         .where('status', isEqualTo: AppConstants.statusPending)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => FoundItemModel.fromFirestore(d)).toList());
//   }

//   Future<void> updateFoundItemStatus(String id, String status) async {
//     await _db
//         .collection(AppConstants.foundItemsCollection)
//         .doc(id)
//         .update({'status': status});
//   }

//   // ─── MATCHES ─────────────────────────────────────────────────────────────────

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

//     final batch = _db.batch();

//     // Create match record
//     batch.set(_db.collection(AppConstants.matchesCollection).doc(id),
//         match.toFirestore());

//     // Update lost item status
//     batch.update(
//         _db.collection(AppConstants.lostItemsCollection).doc(lostItemId),
//         {'status': AppConstants.statusMatched});

//     // Update found item status
//     batch.update(
//         _db.collection(AppConstants.foundItemsCollection).doc(foundItemId),
//         {'status': AppConstants.statusMatched});

//     await batch.commit();

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

//     return match;
//   }

//   Stream<List<MatchModel>> getAllMatches() {
//     return _db
//         .collection(AppConstants.matchesCollection)
//         .orderBy('approvedAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => MatchModel.fromFirestore(d)).toList());
//   }

//   // ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

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

//   Future<void> _notifyVerifiers({
//     required String title,
//     required String body,
//     required String type,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       // Get all verifiers and admin
//       final snapshot = await _db
//           .collection(AppConstants.usersCollection)
//           .where('role', whereIn: ['verifier', 'admin']).get();

//       final batch = _db.batch();
//       for (final doc in snapshot.docs) {
//         final id = const Uuid().v4();
//         batch.set(
//           _db.collection(AppConstants.notificationsCollection).doc(id),
//           {
//             'userId': doc.id,
//             'title': title,
//             'body': body,
//             'type': type,
//             'isRead': false,
//             'createdAt': Timestamp.now(),
//             'data': data,
//           },
//         );
//       }
//       await batch.commit();
//     } catch (_) {
//       // Notification failure should not block the main submission
//     }
//   }

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

//   Future<void> markNotificationRead(String id) async {
//     await _db
//         .collection(AppConstants.notificationsCollection)
//         .doc(id)
//         .update({'isRead': true});
//   }

//   Future<void> markAllNotificationsRead(String userId) async {
//     final snap = await _db
//         .collection(AppConstants.notificationsCollection)
//         .where('userId', isEqualTo: userId)
//         .where('isRead', isEqualTo: false)
//         .get();

//     final batch = _db.batch();
//     for (final doc in snap.docs) {
//       batch.update(doc.reference, {'isRead': true});
//     }
//     await batch.commit();
//   }

//   // ─── ANALYTICS ───────────────────────────────────────────────────────────────

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

//     return {
//       'totalLost': results[0].count ?? 0,
//       'totalFound': results[1].count ?? 0,
//       'totalMatched': results[2].count ?? 0,
//       'pendingLost': results[3].count ?? 0,
//       'pendingFound': results[4].count ?? 0,
//       'totalUsers': results[5].count ?? 0,
//     };
//   }

//   // Get all users
//   Stream<List<UserModel>> getAllUsers() {
//     return _db
//         .collection(AppConstants.usersCollection)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
//   }

//   // ─── VERIFIERS ───────────────────────────────────────────────────────────────

//   Stream<List<UserModel>> getVerifiers() {
//     return _db
//         .collection(AppConstants.usersCollection)
//         .where('role', isEqualTo: AppConstants.roleVerifier)
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) =>
//         snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
//   }

//   Future<void> deleteVerifier(String uid) async {
//     await _db
//         .collection(AppConstants.usersCollection)
//         .doc(uid)
//         .delete();
//   }
// }


  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:uuid/uuid.dart';
  import '../models/lost_item_model.dart';
  import '../models/found_item_model.dart';
  import '../models/match_model.dart';
  import '../models/notification_model.dart';
  import '../models/user_model.dart';
  import '../utils/constants.dart';
  // ── BROADCAST FEATURE START ──
  import '../models/broadcast_model.dart';
  import 'broadcast_cache_service.dart';
  // ── BROADCAST FEATURE END ──

  class FirestoreService {
    final FirebaseFirestore _db = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final Uuid _uuid = const Uuid();
    final BroadcastCacheService _broadcastCache = BroadcastCacheService();
    bool _broadcastSyncStarted = false;

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

    // ── BROADCAST FEATURE START ──

    // ─── BROADCASTS ──────────────────────────────────────────────────────────────

    /// Create a new broadcast (called by verifier).
    /// Automatically sets expiresAt = now + 7 days, isActive = true, readBy = [].
    /// Also sends notifications to all regular users about the new broadcast.
    Future<BroadcastModel> createBroadcast({
      required String broadcastType,
      required String sourceItemId,
      required String itemName,
      required String itemDescription,
      required String itemPhotoURL,
      required String locationInfo,
      required String verifierMessage,
      required String createdByVerifierId,
      required String createdByName,
    }) async {
      if (createdByVerifierId.isEmpty || _auth.currentUser == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'You must be signed in as a verifier to create broadcasts.',
        );
      }

      final verifierDoc = await _db
          .collection(AppConstants.usersCollection)
          .doc(createdByVerifierId)
          .get();
      final verifierRole = verifierDoc.data()?['role'] as String? ?? '';
      if (verifierRole != AppConstants.roleVerifier &&
          verifierRole != AppConstants.roleAdmin) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message:
              'Verifier access is missing for this account. Check users/$createdByVerifierId and make sure role is verifier or admin.',
        );
      }

      final id = _uuid.v4();
      final now = DateTime.now();
      final broadcast = BroadcastModel(
        broadcastId: id,
        broadcastType: broadcastType,
        sourceItemId: sourceItemId,
        itemName: itemName,
        itemDescription: itemDescription,
        itemPhotoURL: itemPhotoURL,
        locationInfo: locationInfo,
        verifierMessage: verifierMessage,
        createdByVerifierId: createdByVerifierId,
        createdByName: createdByName,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isActive: true,
        readBy: [],
      );

      try {
        await _db
            .collection(AppConstants.broadcastsCollection)
            .doc(id)
            .set(broadcast.toMap());
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw FirebaseException(
            plugin: e.plugin,
            code: e.code,
            message:
                'Firestore blocked broadcast creation. Deploy the updated firestore.rules and verify this account still has role "verifier" or "admin".',
          );
        }
        rethrow;
      }

      // Notify all regular users about the new broadcast
      try {
        final usersSnap = await _db
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: AppConstants.roleUser)
            .get();
        final batch = _db.batch();
        final preview = verifierMessage.length > 60
            ? '${verifierMessage.substring(0, 60)}...'
            : verifierMessage;
        for (final doc in usersSnap.docs) {
          final notifId = _uuid.v4();
          batch.set(
            _db.collection(AppConstants.notificationsCollection).doc(notifId),
            {
              'userId': doc.id,
              'title': 'New Campus Notice',
              'body': 'Check the notice board — $preview',
              'type': 'broadcast',
              'isRead': false,
              'createdAt': Timestamp.now(),
              'data': {'broadcastId': id},
            },
          );
        }
        await batch.commit();
      } catch (_) {
        // Notification failure should not block the main submission
      }

      await _broadcastCache.upsert(broadcast);
      return broadcast;
    }

    /// Stream of active, non-expired broadcasts (for user dashboard).
    /// Filters: isActive == true. Client-side additional filter: expiresAt > now.
    Stream<List<BroadcastModel>> getActiveBroadcasts() {
      _startBroadcastSync();
      return _broadcastCache.watchActive();
    }

    void _startBroadcastSync() {
      if (_broadcastSyncStarted) return;
      _broadcastSyncStarted = true;
      _db
          .collection(AppConstants.broadcastsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snap) {
        final now = DateTime.now();
        final items = snap.docs
            .map((doc) => BroadcastModel.fromFirestore(doc))
            .where((item) => item.isActive && item.expiresAt.isAfter(now))
            .toList();
        _broadcastCache.syncFromRemote(items);
      }, onError: (_) {
        // Keep serving the shared frontend cache when Firestore reads are blocked.
      });
    }

    /// Stream of ALL broadcasts (for admin logs), sorted newest first.
    Stream<List<BroadcastModel>> getAllBroadcasts() {
      return _db
          .collection(AppConstants.broadcastsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) {
        final items = snap.docs.map((d) => BroadcastModel.fromFirestore(d)).toList();
        _broadcastCache.syncFromRemote(items);
        return items;
      });
    }

    /// Mark a broadcast as read by a user (array union — no duplicates).
    Future<void> markBroadcastRead(String broadcastId, String userId) async {
      await _db
          .collection(AppConstants.broadcastsCollection)
          .doc(broadcastId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
      await _broadcastCache.markRead(broadcastId, userId);
    }

    /// Deactivate a broadcast (verifier or admin).
    Future<void> deactivateBroadcast(String broadcastId) async {
      await _db
          .collection(AppConstants.broadcastsCollection)
          .doc(broadcastId)
          .update({'isActive': false});
      await _broadcastCache.deactivate(broadcastId);
    }

    /// Check if a broadcast already exists for a given sourceItemId.
    Future<bool> broadcastExistsForItem(String sourceItemId) async {
      final snap = await _db
          .collection(AppConstants.broadcastsCollection)
          .where('sourceItemId', isEqualTo: sourceItemId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    }

    /// Notify all verifiers that a user responded to a broadcast.
    Future<void> notifyVerifiersBroadcastResponse({
      required String broadcastId,
      required String respondedByUserId,
      required String respondedByName,
      required String itemName,
    }) async {
      await _notifyVerifiers(
        title: 'Broadcast Response',
        body: '$respondedByName responded to: $itemName. Check your dashboard.',
        type: 'broadcast_response',
        data: {
          'broadcastId': broadcastId,
          'respondedByUserId': respondedByUserId,
        },
      );
    }

    // ── BROADCAST FEATURE END ──
  }
