// lib/src/screens/home_screen.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';
import 'package:flutter/foundation.dart';

class ImgShapeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onProfileTap;

  const ImgShapeAppBar({
    super.key,
    this.onRefresh,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Image.asset('assets/logo.jpg', width: 36, height: 36, fit: BoxFit.cover),
          const SizedBox(width: 12),
          const Text('imgshape', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      actions: [
        IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: onProfileTap,
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white10,
              child: Icon(Icons.person, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  final ValueNotifier<Map<String, dynamic>?> _lastUpload = ValueNotifier(null);
  final ValueNotifier<String?> _thumbnailUrl = ValueNotifier(null);
  final ValueNotifier<bool> _loading = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _fetchLastUpload();
  }

  Future<Map<String, dynamic>?> _fetchFromSupabase(String userId) async {
    final res = await supabase
        .from('user_images')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res;
  }

  Future<void> _fetchLastUpload() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _loading.value = true;
    try {
      final res = await compute(_fetchFromSupabase, user.id);
      if (res != null && res is Map<String, dynamic>) {
        final bucket = res['bucket'] ?? 'user-uploads';
        final path = res['path'] ?? '';
        if (path.isNotEmpty) {
          try {
            final signed = await supabase.storage.from(bucket).createSignedUrl(path, 3600);
            _lastUpload.value = res;
            _thumbnailUrl.value = signed;
          } catch (e) {
            log('Signed URL error: $e');
          }
        }
      }
    } catch (e) {
      log('Fetch last upload error: $e');
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _openUploadAndMaybeRefresh() async {
    final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadScreen()));
    if (res == true) _fetchLastUpload();
  }

  void _openProfile() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));

  Widget _heroSection() => GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Image Analysis & Insights',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Unlock deep insights into your image data with entropy analysis, shape detection, and intelligent preprocessing recommendations.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.go('/analyze'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Analyzing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _benefitsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text('What imgshape brings to you',
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      _benefitsTile('Entropy Analysis', 'Understand image complexity.', Icons.info_outline, AppTheme.accentCyan),
      const SizedBox(height: 10),
      _benefitsTile('Smart Preprocessing', 'Get recommendations for resizing.', Icons.auto_fix_high, AppTheme.accentViolet),
      const SizedBox(height: 10),
      _benefitsTile('Dataset Compatibility', 'Validate dataset easily.', Icons.check_circle_outline, Colors.greenAccent),
      const SizedBox(height: 10),
      _benefitsTile('Detailed Reports', 'Generate reports quickly.', Icons.description, Colors.amber),
    ],
  );

  Widget _benefitsTile(String title, String description, IconData icon, Color color) => GlassCard(
    child: ListTile(
      leading: Container(
          width: 46, height: 46, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color)),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
    ),
  );

  Widget _lastUploadCard() => ValueListenableBuilder(
    valueListenable: _loading,
    builder: (context, loading, _) {
      if (loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return ValueListenableBuilder(
        valueListenable: _lastUpload,
        builder: (context, upload, _) {
          if (upload == null) {
            return _noUploadCard();
          }
          return _uploadPreviewCard(upload);
        },
      );
    },
  );

  Widget _noUploadCard() => GlassCard(
    child: SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.white30),
            SizedBox(height: 8),
            Text('No uploads yet', style: TextStyle(color: Colors.white70))
          ],
        ),
      ),
    ),
  );

  Widget _uploadPreviewCard(Map upload) => GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        ValueListenableBuilder(
          valueListenable: _thumbnailUrl,
          builder: (context, thumb, _) {
            if (thumb == null) {
              return const Icon(Icons.image, size: 80, color: Colors.white30);
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: '$thumb?width=300',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                memCacheWidth: 256,
                placeholder: (context, _) => const CircularProgressIndicator(strokeWidth: 1.5),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 44),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(upload['filename'] ?? 'Image',
            style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () => context.go('/analyze'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero),
          child: const Text('Analyze Now', style: TextStyle(fontSize: 12)),
        ),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.heroBackground(),
      child: Scaffold(
        appBar: ImgShapeAppBar(onRefresh: _fetchLastUpload, onProfileTap: _openProfile),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            children: [
              _heroSection(),
              const SizedBox(height: 16),
              _benefitsSection(),
              const SizedBox(height: 16),
              _lastUploadCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openUploadAndMaybeRefresh,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Image'),
          backgroundColor: AppTheme.accentCyan,
        ),
      ),
    );
  }
}