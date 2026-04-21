// ── BROADCAST FEATURE START ──
import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastModel {
  final String broadcastId;
  final String broadcastType; // "lost_broadcast" | "found_broadcast"
  final String sourceItemId;
  final String itemName;
  final String itemDescription;
  final String itemPhotoURL;
  final String locationInfo;
  final String verifierMessage;
  final String createdByVerifierId;
  final String createdByName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final List<String> readBy;

  const BroadcastModel({
    required this.broadcastId,
    required this.broadcastType,
    required this.sourceItemId,
    required this.itemName,
    required this.itemDescription,
    required this.itemPhotoURL,
    required this.locationInfo,
    required this.verifierMessage,
    required this.createdByVerifierId,
    required this.createdByName,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.readBy,
  });

  factory BroadcastModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BroadcastModel(
      broadcastId: doc.id,
      broadcastType: data['broadcastType'] as String? ?? '',
      sourceItemId: data['sourceItemId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      itemDescription: data['itemDescription'] as String? ?? '',
      itemPhotoURL: data['itemPhotoURL'] as String? ?? '',
      locationInfo: data['locationInfo'] as String? ?? '',
      verifierMessage: data['verifierMessage'] as String? ?? '',
      createdByVerifierId: data['createdByVerifierId'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      isActive: data['isActive'] as bool? ?? true,
      readBy: List<String>.from(data['readBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'broadcastId': broadcastId,
      'broadcastType': broadcastType,
      'sourceItemId': sourceItemId,
      'itemName': itemName,
      'itemDescription': itemDescription,
      'itemPhotoURL': itemPhotoURL,
      'locationInfo': locationInfo,
      'verifierMessage': verifierMessage,
      'createdByVerifierId': createdByVerifierId,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'readBy': readBy,
    };
  }

  BroadcastModel copyWith({
    String? broadcastId,
    String? broadcastType,
    String? sourceItemId,
    String? itemName,
    String? itemDescription,
    String? itemPhotoURL,
    String? locationInfo,
    String? verifierMessage,
    String? createdByVerifierId,
    String? createdByName,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    List<String>? readBy,
  }) {
    return BroadcastModel(
      broadcastId: broadcastId ?? this.broadcastId,
      broadcastType: broadcastType ?? this.broadcastType,
      sourceItemId: sourceItemId ?? this.sourceItemId,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      itemPhotoURL: itemPhotoURL ?? this.itemPhotoURL,
      locationInfo: locationInfo ?? this.locationInfo,
      verifierMessage: verifierMessage ?? this.verifierMessage,
      createdByVerifierId: createdByVerifierId ?? this.createdByVerifierId,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      readBy: readBy ?? this.readBy,
    );
  }
}
// ── BROADCAST FEATURE END ──
