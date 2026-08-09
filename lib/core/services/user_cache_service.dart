import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚀 In-memory caching service to prevent repeated Firestore reads for user data and names.
class UserCacheService {
  UserCacheService._();

  static final Map<String, String> _nameCache = {};
  static final Map<String, Map<String, dynamic>> _userDocCache = {};

  /// Retrieves user name with in-memory caching.
  static Future<String> getUserName(String userId) async {
    if (userId.isEmpty) return "User";
    if (_nameCache.containsKey(userId)) {
      return _nameCache[userId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();
      final data = doc.data();
      final name = data?["name"] ?? "User";
      _nameCache[userId] = name;
      if (data != null) {
        _userDocCache[userId] = data;
      }
      return name;
    } catch (_) {
      return "User";
    }
  }

  /// Retrieves full user document data with in-memory caching.
  static Future<Map<String, dynamic>?> getUserDoc(String userId) async {
    if (userId.isEmpty) return null;
    if (_userDocCache.containsKey(userId)) {
      return _userDocCache[userId];
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();
      final data = doc.data();
      if (data != null) {
        _userDocCache[userId] = data;
        if (data.containsKey("name")) {
          _nameCache[userId] = data["name"] ?? "User";
        }
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Clears cache when needed.
  static void clear() {
    _nameCache.clear();
    _userDocCache.clear();
  }
}
