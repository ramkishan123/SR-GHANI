import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/sync_service.dart';
import 'package:sr_ghani/services/storage_service.dart';

class SyncLoadingScreen extends ConsumerStatefulWidget {
  const SyncLoadingScreen({super.key});

  @override
  ConsumerState<SyncLoadingScreen> createState() => _SyncLoadingScreenState();
}

class _SyncLoadingScreenState extends ConsumerState<SyncLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _statusText = 'Initializing Secure Sync...';
  bool _hasError = false;
  bool _showSkipButton = false;
  static const int _syncTimeoutSeconds = 30;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      // Start a timeout timer
      Future.delayed(const Duration(seconds: _syncTimeoutSeconds)).then((_) {
        if (mounted && _statusText != 'Sync Complete! Finalizing...') {
          setState(() => _showSkipButton = true);
        }
      });

      await ref.read(syncServiceProvider).performInitialSync();
      
      if (!mounted) return;
      setState(() => _statusText = 'Sync Complete! Finalizing...');
      await Future.delayed(const Duration(seconds: 1));
      
      // No manual navigation needed, InitialAuthWrapper watches syncStatusProvider
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Sync failed. Please check your connection.';
          _hasError = true;
          _controller.stop();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _animation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4),
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 1.0, end: 0.0).animate(_animation),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 4),
                      ),
                    ),
                  ),
                  const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 48),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                _statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (_hasError) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _statusText = 'Retrying Sync...';
                      _controller.repeat();
                    });
                    _startSync();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Retry Connection'),
                ),
              ],
              if (_showSkipButton && !_hasError) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    ref.read(storageServiceProvider).setSyncComplete(ref, true);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Slow Connection? Skip to Offline Mode'),
                ),
              ],
              const SizedBox(height: 80),
              const Text(
                'SR GHANI • SECURE DATA SYNC',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
