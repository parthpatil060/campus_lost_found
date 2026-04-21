import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/broadcast_model.dart';

class BroadcastCacheService {
  BroadcastCacheService._();

  static final BroadcastCacheService _instance = BroadcastCacheService._();

  factory BroadcastCacheService() => _instance;

  static const String _prefsKey = 'cached_broadcasts_v1';

  final StreamController<List<BroadcastModel>> _controller =
      StreamController<List<BroadcastModel>>.broadcast();

  List<BroadcastModel> _cached = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cached = decoded
          .map((item) => _fromCacheMap(item as Map<String, dynamic>))
          .toList();
    }
    _loaded = true;
  }

  Stream<List<BroadcastModel>> watchActive() async* {
    await _ensureLoaded();
    yield _activeItems();
    yield* _controller.stream.map((_) => _activeItems());
  }

  Future<void> syncFromRemote(List<BroadcastModel> items) async {
    await _ensureLoaded();
    final byId = {for (final item in _cached) item.broadcastId: item};
    for (final item in items) {
      byId[item.broadcastId] = item;
    }
    _cached = byId.values.toList();
    await _persist();
    _controller.add(_activeItems());
  }

  Future<void> upsert(BroadcastModel item) async {
    await _ensureLoaded();
    final index =
        _cached.indexWhere((entry) => entry.broadcastId == item.broadcastId);
    if (index == -1) {
      _cached.add(item);
    } else {
      _cached[index] = item;
    }
    await _persist();
    _controller.add(_activeItems());
  }

  Future<void> markRead(String broadcastId, String userId) async {
    await _ensureLoaded();
    final index =
        _cached.indexWhere((entry) => entry.broadcastId == broadcastId);
    if (index == -1) return;
    final updatedReadBy = [..._cached[index].readBy];
    if (!updatedReadBy.contains(userId)) {
      updatedReadBy.add(userId);
    }
    _cached[index] = _cached[index].copyWith(readBy: updatedReadBy);
    await _persist();
    _controller.add(_activeItems());
  }

  Future<void> deactivate(String broadcastId) async {
    await _ensureLoaded();
    final index =
        _cached.indexWhere((entry) => entry.broadcastId == broadcastId);
    if (index == -1) return;
    _cached[index] = _cached[index].copyWith(isActive: false);
    await _persist();
    _controller.add(_activeItems());
  }

  List<BroadcastModel> _activeItems() {
    final now = DateTime.now();
    final items = _cached
        .where((item) => item.isActive && item.expiresAt.isAfter(now))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_cached.map(_toCacheMap).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Map<String, dynamic> _toCacheMap(BroadcastModel item) {
    return {
      'broadcastId': item.broadcastId,
      'broadcastType': item.broadcastType,
      'sourceItemId': item.sourceItemId,
      'itemName': item.itemName,
      'itemDescription': item.itemDescription,
      'itemPhotoURL': item.itemPhotoURL,
      'locationInfo': item.locationInfo,
      'verifierMessage': item.verifierMessage,
      'createdByVerifierId': item.createdByVerifierId,
      'createdByName': item.createdByName,
      'createdAt': item.createdAt.toIso8601String(),
      'expiresAt': item.expiresAt.toIso8601String(),
      'isActive': item.isActive,
      'readBy': item.readBy,
    };
  }

  BroadcastModel _fromCacheMap(Map<String, dynamic> data) {
    return BroadcastModel(
      broadcastId: data['broadcastId'] as String? ?? '',
      broadcastType: data['broadcastType'] as String? ?? '',
      sourceItemId: data['sourceItemId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      itemDescription: data['itemDescription'] as String? ?? '',
      itemPhotoURL: data['itemPhotoURL'] as String? ?? '',
      locationInfo: data['locationInfo'] as String? ?? '',
      verifierMessage: data['verifierMessage'] as String? ?? '',
      createdByVerifierId: data['createdByVerifierId'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      isActive: data['isActive'] as bool? ?? true,
      readBy: List<String>.from(data['readBy'] as List? ?? const []),
    );
  }
}
