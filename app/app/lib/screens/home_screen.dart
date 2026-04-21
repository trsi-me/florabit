import 'package:flutter/material.dart';
import '../api_service.dart';
import '../notification_service.dart';
import '../user_provider.dart';
import '../app_theme.dart';
import 'add_plant_screen.dart';
import 'plant_details_screen.dart';
import 'identify_plant_screen.dart';
import 'plant_gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _plants = [];
  Map<String, dynamic>? _smartSummary;
  final Map<int, int> _healthByPlantId = {};
  bool _loading = true;
  late AnimationController _loadingAnimController;

  @override
  void initState() {
    super.initState();
    _loadingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadPlants();
  }

  /// استدعاء من الشريط السفلي عند العودة لتبويب الرئيسية.
  Future<void> refreshData() => _loadPlants();

  @override
  void dispose() {
    _loadingAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    setState(() => _loading = true);
    try {
      final uid = UserProvider.userId;
      final plants = await ApiService.getPlants(uid);
      Map<String, dynamic>? summary;
      final health = <int, int>{};
      if (uid != null) {
        try {
          summary = await ApiService.getSmartSummary(uid);
          final sp = summary['plants'] as List<dynamic>? ?? [];
          for (final x in sp) {
            final m = x as Map<String, dynamic>;
            final id = m['id'] as int?;
            final hs = m['health_score'];
            if (id != null && hs is num) {
              health[id] = hs.round();
            }
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _plants = plants;
          _smartSummary = summary;
          _healthByPlantId
            ..clear()
            ..addAll(health);
          _loading = false;
        });
        if (plants.isNotEmpty) _loadingAnimController.forward();
        NotificationService.syncCareReminders(UserProvider.userId);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToAddPlant() async {
    await Navigator.push(
      context,
      AppTheme.slideRoute(const AddPlantScreen()),
    );
    _loadPlants();
  }

  void _navigateToPlantDetails(dynamic plant) async {
    await Navigator.push(
      context,
      AppTheme.slideRoute(
        PlantDetailsScreen(plantId: plant['id'] as int),
      ),
    );
    _loadPlants();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'فلورابيت',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'لوحة العناية بالنباتات',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () => Navigator.push(
              context,
              AppTheme.slideRoute(const PlantGalleryScreen()),
            ).then((_) => _loadPlants()),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => Navigator.push(
              context,
              AppTheme.slideRoute(const IdentifyPlantScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'جاري التحميل...',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          : _plants.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPlants,
                  color: AppTheme.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: _buildWelcomeBanner(),
                        ),
                      ),
                      if (_smartSummary != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: _buildSmartSummaryCard(),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final p = _plants[i];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 400 + (i * 80)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildPlantCard(p),
                              );
                            },
                            childCount: _plants.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildWelcomeBanner() {
    final scheme = Theme.of(context).colorScheme;
    final name = UserProvider.userName ?? 'صديقنا';
    final count = _plants.length;
    final isEmpty = count == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.10),
            AppTheme.primaryLight.withValues(alpha: 0.06),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppTheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، $name',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEmpty
                      ? 'ابدأ مجموعتك الخضراء — سجّل نباتاتك ومواعيد الري والتسميد.'
                      : 'لديك $count ${count == 1 ? 'نبتة مسجّلة' : 'نباتات مسجّلة'}. تتبّع العناية من هذه اللوحة.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 28),
          TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.eco_rounded,
                  size: 72,
                  color: AppTheme.primary.withValues(alpha: 0.75),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد نباتات بعد',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'أضف نباتاتك أو استخدم الكاميرا للتعرّف، ثم نظّم العناية في مكان واحد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    AppTheme.slideRoute(const PlantGalleryScreen()),
                  ).then((_) => _loadPlants()),
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text('معرض النباتات'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    AppTheme.slideRoute(const IdentifyPlantScreen()),
                  ).then((_) => _loadPlants()),
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text('التعرف بالكاميرا'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _navigateToAddPlant,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('إضافة نبتة'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildSmartSummaryCard() {
    final s = _smartSummary;
    if (s == null) return const SizedBox.shrink();
    final score = (s['overall_health_score'] as num?)?.round() ?? 0;
    final ow = (s['overdue_watering_plants'] as num?)?.round() ?? 0;
    final of = (s['overdue_fertilizing_plants'] as num?)?.round() ?? 0;
    final streak = (s['care_streak_days'] as num?)?.round() ?? 0;
    final tip = s['tip_of_day'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.92),
            AppTheme.primaryDark.withOpacity(0.88),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: score / 100.0,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withOpacity(0.4),
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      Text(
                        '$score',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مؤشر العناية الذكي',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (ow > 0)
                          _chip(
                            'ري متأخر: $ow',
                            Colors.orange.shade100,
                            Colors.orange.shade900,
                          ),
                        if (of > 0)
                          _chip(
                            'تسميد متأخر: $of',
                            Colors.amber.shade100,
                            Colors.amber.shade900,
                          ),
                        if (ow == 0 && of == 0)
                          _chip(
                            'لا تأخيرات حالية',
                            Colors.green.shade100,
                            Colors.green.shade900,
                          ),
                        _chip(
                          'سلسلة أيام: $streak',
                          Colors.white.withOpacity(0.92),
                          AppTheme.primaryDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                        color: Colors.white.withOpacity(0.95),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPlantCard(dynamic p) {
    final scheme = Theme.of(context).colorScheme;
    final id = p['id'] as int?;
    final hs = id != null ? _healthByPlantId[id] : null;
    Color? ring;
    if (hs != null) {
      if (hs >= 82) {
        ring = Colors.green.shade400;
      } else if (hs >= 65) {
        ring = Colors.lightGreen.shade400;
      } else if (hs >= 45) {
        ring = Colors.orange.shade400;
      } else {
        ring = Colors.red.shade300;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: () => _navigateToPlantDetails(p),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: ring != null
                        ? Border.all(color: ring, width: 2.5)
                        : null,
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] as String? ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p['type']} • ري كل ${p['watering_interval_days']} أيام',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.58),
                        ),
                      ),
                      if (hs != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'صحة مسجّلة: $hs%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ring ?? scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    if (_plants.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'camera',
          onPressed: () => Navigator.push(
            context,
            AppTheme.slideRoute(const IdentifyPlantScreen()),
          ).then((_) => _loadPlants()),
          backgroundColor: AppTheme.primaryDark,
          child: const Icon(Icons.camera_alt_rounded),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          onPressed: _navigateToAddPlant,
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة نبتة'),
        ),
      ],
    );
  }
}
