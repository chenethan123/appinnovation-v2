import 'dart:async';
import 'auth_service.dart';
import 'sync_service.dart';

/// Background sync service that automatically syncs data at regular intervals
/// Runs only when user is logged in
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  // Sync interval (default: 5 minutes)
  Duration syncInterval = const Duration(minutes: 5);
  
  /// Start background sync timer
  void startBackgroundSync() {
    if (_syncTimer != null && _syncTimer!.isActive) {
      print('⚠️ Background sync already running');
      return;
    }
    
    print('🚀 Starting background sync (every ${syncInterval.inMinutes} minutes)');
    
    // Initial sync
    _performSync();
    
    // Periodic sync
    _syncTimer = Timer.periodic(syncInterval, (_) {
      _performSync();
    });
  }
  
  /// Stop background sync timer
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('🛑 Background sync stopped');
  }
  
  /// Perform sync operation
  Future<void> _performSync() async {
    // Skip if already syncing
    if (_isSyncing) {
      print('⏭️ Skipping sync - already in progress');
      return;
    }
    
    // Skip if not logged in
    if (!_authService.isLoggedIn) {
      print('⏭️ Skipping sync - user not logged in');
      return;
    }
    
    _isSyncing = true;
    
    try {
      print('🔄 Background sync starting...');
      final result = await _syncService.fullSync();
      _lastSyncTime = DateTime.now();
      
      if (result.success) {
        print('✅ Background sync complete: ${result.message}');
      } else {
        print('⚠️ Background sync partial: ${result.message}');
      }
    } catch (e) {
      print('❌ Background sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Force immediate sync
  Future<void> syncNow() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot sync - user not logged in');
      return;
    }
    
    await _performSync();
  }
  
  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Check if currently syncing
  bool get isSyncing => _isSyncing;
  
  /// Get time since last sync
  Duration? getTimeSinceLastSync() {
    if (_lastSyncTime == null) return null;
    return DateTime.now().difference(_lastSyncTime!);
  }
  
  /// Get status message
  String getStatusMessage() {
    if (!_authService.isLoggedIn) {
      return 'Offline - Not logged in';
    }
    
    if (_isSyncing) {
      return 'Syncing...';
    }
    
    if (_lastSyncTime == null) {
      return 'Never synced';
    }
    
    final timeSince = getTimeSinceLastSync();
    if (timeSince == null) return 'Unknown';
    
    if (timeSince.inMinutes < 1) {
      return 'Synced just now';
    } else if (timeSince.inMinutes < 60) {
      return 'Synced ${timeSince.inMinutes}m ago';
    } else if (timeSince.inHours < 24) {
      return 'Synced ${timeSince.inHours}h ago';
    } else {
      return 'Synced ${timeSince.inDays}d ago';
    }
  }
}
