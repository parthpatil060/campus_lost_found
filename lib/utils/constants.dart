class AppConstants {
  // College email domain
  static const String allowedEmailDomain = '@gst.sies.edu.in';

  // Cloudinary config (replace with your actual values)
  static const String cloudinaryCloudName = 'dxcljts1y';
  static const String cloudinaryUploadPreset = 'campus_lost_found';
  static const String cloudinaryBaseUrl =
      'https://api.cloudinary.com/v1_1/dxcljts1y/image/upload';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String lostItemsCollection = 'lost_items';
  static const String foundItemsCollection = 'found_items';
  static const String matchesCollection = 'matches';
  static const String notificationsCollection = 'notifications';

 // ── BROADCAST FEATURE START ──
  static const String broadcastsCollection = 'broadcasts';
  // ── BROADCAST FEATURE END ──
  
  // User roles
  static const String roleUser = 'user';
  static const String roleVerifier = 'verifier';
  static const String roleAdmin = 'admin';

  // Item statuses
  static const String statusPending = 'pending';
  static const String statusMatched = 'matched';
  static const String statusClaimed = 'claimed';
  static const String statusRejected = 'rejected';

  // Admin email (hardcoded single admin)
  static const String adminEmail = 'admin@gst.sies.edu.in';
}
