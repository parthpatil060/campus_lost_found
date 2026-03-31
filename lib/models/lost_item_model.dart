import 'package:cloud_firestore/cloud_firestore.dart';

class LostItemModel {
  final String lostItemId;
  final String userId;
  final String itemName;
  final String? photoURL;
  final String secretIdentificationDetail;
  final List<String> possibleLocations;
  final String status; // pending / matched / claimed
  final DateTime createdAt;
  final String? description;
  final String? category;

  const LostItemModel({
    required this.lostItemId,
    required this.userId,
    required this.itemName,
    this.photoURL,
    required this.secretIdentificationDetail,
    required this.possibleLocations,
    required this.status,
    required this.createdAt,
    this.description,
    this.category,
  });

  factory LostItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LostItemModel(
      lostItemId: doc.id,
      userId: data['userId'] ?? '',
      itemName: data['itemName'] ?? '',
      photoURL: data['photoURL'],
      secretIdentificationDetail: data['secretIdentificationDetail'] ?? '',
      possibleLocations: List<String>.from(data['possibleLocations'] ?? []),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      category: data['category'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lostItemId': lostItemId,
      'userId': userId,
      'itemName': itemName,
      'photoURL': photoURL,
      'secretIdentificationDetail': secretIdentificationDetail,
      'possibleLocations': possibleLocations,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'category': category,
    };
  }

  LostItemModel copyWith({String? status, String? photoURL}) {
    return LostItemModel(
      lostItemId: lostItemId,
      userId: userId,
      itemName: itemName,
      photoURL: photoURL ?? this.photoURL,
      secretIdentificationDetail: secretIdentificationDetail,
      possibleLocations: possibleLocations,
      status: status ?? this.status,
      createdAt: createdAt,
      description: description,
      category: category,
    );
  }
}
