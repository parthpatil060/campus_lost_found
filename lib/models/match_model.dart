import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String matchId;
  final String lostItemId;
  final String foundItemId;
  final String approvedByVerifierId;
  final DateTime approvedAt;
  final String status; // pending / approved / rejected
  final String? notes;

  const MatchModel({
    required this.matchId,
    required this.lostItemId,
    required this.foundItemId,
    required this.approvedByVerifierId,
    required this.approvedAt,
    required this.status,
    this.notes,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      matchId: doc.id,
      lostItemId: data['lostItemId'] ?? '',
      foundItemId: data['foundItemId'] ?? '',
      approvedByVerifierId: data['approvedByVerifierId'] ?? '',
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'approved',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'lostItemId': lostItemId,
      'foundItemId': foundItemId,
      'approvedByVerifierId': approvedByVerifierId,
      'approvedAt': Timestamp.fromDate(approvedAt),
      'status': status,
      'notes': notes,
    };
  }
}
