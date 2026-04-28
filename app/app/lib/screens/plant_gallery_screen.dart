import 'package:flutter/material.dart';
import '../api_service.dart';
import '../user_provider.dart';
import '../app_theme.dart';
import 'add_plant_screen.dart';

class PlantGalleryScreen extends StatefulWidget {
  const PlantGalleryScreen({super.key});

  @override
  State<PlantGalleryScreen> createState() => _PlantGalleryScreenState();
}

class _PlantGalleryScreenState extends State<PlantGalleryScreen> {
  List<dynamic> _plants = [];
  List<String> _cities = [];
  List<String> _homeTypes = [];
  String? _selectedCity;
  String? _selectedHomeType;
  bool _loading = true;

  /// يحافظ على الترتيب ويمنع تكرار القيم — تكرار المدن يكسر DropdownButton.
  static List<String> _distinctOrdered(List<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final s in raw) {
      if (seen.add(s)) out.add(s);
    }
    return out;
  }

  /// قيمة آمنة للقائمة: يجب أن تطابق عنصراً واحداً فقط، أو null أثناء التحميل.
  static String? _safeDropdownValue(String? selected, List<String> items) {
    if (selected == null) return null;
    final n = items.where((x) => x == selected).length;
    if (n == 1) return selected;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedCity = UserProvider.city;
    _selectedHomeType = UserProvider.homeType;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getCities(),
        ApiService.getHomeTypes(),
        ApiService.getRecommendations(
          city: _selectedCity,
          homeType: _selectedHomeType,
        ),
      ]);
      if (mounted) {
        setState(() {
          _cities = _distinctOrdered(List<String>.from(results[0]));
          _homeTypes = _distinctOrdered(List<String>.from(results[1]));
          _plants = List<dynamic>.from(results[2]);
          if (_selectedCity != null && !_cities.contains(_selectedCity)) {
            _selectedCity = null;
          }
          if (_selectedHomeType != null && !_homeTypes.contains(_selectedHomeType)) {
            _selectedHomeType = null;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyFilters() async {
    if (_selectedCity != null || _selectedHomeType != null) {
      final userId = UserProvider.userId;
      if (userId != null) {
        try {
          final data = <String, dynamic>{};
          if (_selectedCity != null) data['city'] = _selectedCity;
          if (_selectedHomeType != null) data['home_type'] = _selectedHomeType;
          await ApiService.updateUser(userId, data);
          final current = UserProvider.currentUser ?? {};
          UserProvider.setUser({...current, ...data});
        } catch (_) {}
      }
    }
    _loadData();
  }

  void _addPlant(dynamic plant) {
    final indoorOutdoor = plant['indoor_outdoor'] as String? ?? 
        (plant['type'] == 'داخلي' ? 'داخلي' : 'خارجي');
    Navigator.push(
      context,
      AppTheme.slideRoute(AddPlantScreen(
        suggestedName: plant['name'] as String?,
        suggestedType: plant['type'] as String?,
        wateringDays: plant['watering_days'] as int? ?? plant['watering_interval_days'] as int? ?? 7,
        fertilizingDays: plant['fertilizing_days'] as int? ?? plant['fertilizing_interval_days'] as int? ?? 30,
        suggestedIndoorOutdoor: indoorOutdoor,
      )),
    ).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('معرض النباتات'),
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
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
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
                        const SizedBox(height: 16),
                        Text(
                          'جاري تحميل التوصيات...',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.85)
                                : scheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : _plants.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد نباتات مناسبة',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.8)
                                : scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _plants.length,
                          itemBuilder: (context, i) {
                            final p = _plants[i];
                            return _buildPlantCard(p);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor =
        isDark ? Colors.white.withValues(alpha: 0.9) : scheme.onSurface.withValues(alpha: 0.75);
    return Container(
      padding: const EdgeInsets.all(16),
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختر مدينتك ونوع منزلك للحصول على توصيات مناسبة',
            style: TextStyle(
              fontSize: 14,
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _safeDropdownValue(_selectedCity, _cities),
                  dropdownColor: isDark ? scheme.surface : null,
                  style: TextStyle(
                    color: isDark ? Colors.white : scheme.onSurface,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    prefixIcon: Icon(Icons.location_city, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('الكل', style: TextStyle(color: isDark ? Colors.white : null)),
                    ),
                    ..._cities.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c,
                        child: Text(c, style: TextStyle(color: isDark ? Colors.white : null)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedCity = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _safeDropdownValue(_selectedHomeType, _homeTypes),
                  dropdownColor: isDark ? scheme.surface : null,
                  style: TextStyle(
                    color: isDark ? Colors.white : scheme.onSurface,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'نوع المنزل',
                    prefixIcon: Icon(Icons.home_outlined, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('الكل', style: TextStyle(color: isDark ? Colors.white : null)),
                    ),
                    ..._homeTypes.map(
                      (h) => DropdownMenuItem<String?>(
                        value: h,
                        child: Text(h, style: TextStyle(color: isDark ? Colors.white : null)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedHomeType = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.filter_list, size: 20, color: Colors.white),
            label: const Text('تطبيق التوصيات'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(dynamic p) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.primaryDark;
    final name = p['name'] as String? ?? '';
    final type = p['type'] as String? ?? '';
    final indoorOutdoor = p['indoor_outdoor'] as String? ?? (type == 'داخلي' ? 'داخلي' : 'خارجي');
    final watering = p['watering_days'] ?? p['watering_interval_days'] ?? 7;
    final fertilizing = p['fertilizing_days'] ?? p['fertilizing_interval_days'] ?? 30;
    final light = p['light_requirement'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: () => _addPlant(p),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    indoorOutdoor == 'داخلي' ? Icons.eco_rounded : Icons.grass_rounded,
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
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$type • $indoorOutdoor',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.78)
                              : scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (light.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'إضاءة: $light',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'ري كل $watering أيام • تسميد كل $fertilizing يوم',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.72)
                              : scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: isDark ? AppTheme.primaryLight : AppTheme.primary,
                  onPressed: () => _addPlant(p),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
