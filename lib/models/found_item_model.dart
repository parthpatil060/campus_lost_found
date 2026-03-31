import 'package:cloud_firestore/cloud_firestore.dart';

class FoundItemModel {
  final String foundItemId;
  final String finderId;
  final String photoURL;
  final String description;
  final String locationFound;
  final String storageOption;
  final String status; // pending / matched / claimed
  final DateTime createdAt;
  final String? category;
  final String? finderName;

  const FoundItemModel({
    required this.foundItemId,
    required this.finderId,
    required this.photoURL,
    required this.description,
    required this.locationFound,
    required this.storageOption,
    required this.status,
    required this.createdAt,
    this.category,
    this.finderName,
  });

  factory FoundItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoundItemModel(
      foundItemId: doc.id,
      finderId: data['finderId'] ?? '',
      photoURL: data['photoURL'] ?? '',
      description: data['description'] ?? '',
      locationFound: data['locationFound'] ?? '',
      storageOption: data['storageOption'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'],
      finderName: data['finderName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'foundItemId': foundItemId,
      'finderId': finderId,
      'photoURL': photoURL,
      'description': description,
      'locationFound': locationFound,
      'storageOption': storageOption,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      'finderName': finderName,
    };
  }

  FoundItemModel copyWith({String? status}) {
    return FoundItemModel(
      foundItemId: foundItemId,
      finderId: finderId,
      photoURL: photoURL,
      description: description,
      locationFound: locationFound,
      storageOption: storageOption,
      status: status ?? this.status,
      createdAt: createdAt,
      category: category,
      finderName: finderName,
    );
  }
}
