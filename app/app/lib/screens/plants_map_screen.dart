import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api_service.dart';
import '../location_helper.dart';
import '../app_theme.dart';
import '../user_provider.dart';

/// خريطة تفاعلية (OpenStreetMap عبر flutter_map) لعرض نباتات المستخدم.
class PlantsMapScreen extends StatefulWidget {
  const PlantsMapScreen({super.key});

  @override
  State<PlantsMapScreen> createState() => PlantsMapScreenState();
}

class PlantsMapScreenState extends State<PlantsMapScreen> {
  final MapController _mapController = MapController();

  List<LatLng> _plantLatLngs = [];
  LatLng _initialTarget = const LatLng(24.7136, 46.6753);
  List<Marker> _plantMarkers = [];
  LatLng? _mePoint;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refreshData() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = UserProvider.userId;
      final plants = await ApiService.getPlants(uid);
      final markers = <Marker>[];
      final positions = <LatLng>[];

      for (final p in plants) {
        final la = p['latitude'];
        final lo = p['longitude'];
        if (la is num && lo is num) {
          final pt = LatLng(la.toDouble(), lo.toDouble());
          positions.add(pt);
          final name = p['name'] as String? ?? 'نبتة';
          markers.add(
            Marker(
              point: pt,
              width: 48,
              height: 48,
              alignment: Alignment.bottomCenter,
              child: Tooltip(
                message: name,
                child: GestureDetector(
                  onTap: () => _openMapExternally(pt),
                  child: Icon(
                    Icons.location_on,
                    color: AppTheme.primary,
                    size: 44,
                  ),
                ),
              ),
            ),
          );
        }
      }

      if (positions.isNotEmpty) {
        double sumLat = 0, sumLng = 0;
        for (final q in positions) {
          sumLat += q.latitude;
          sumLng += q.longitude;
        }
        _initialTarget = LatLng(
          sumLat / positions.length,
          sumLng / positions.length,
        );
      }

      setState(() {
        _plantMarkers = markers;
        _plantLatLngs = positions;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _plantLatLngs.isNotEmpty) {
          _applyBounds(_plantLatLngs);
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل النباتات. تحقق من السيرفر.';
      });
    }
  }

  void _applyBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    try {
      if (points.length == 1) {
        _mapController.move(points.first, 14);
        return;
      }
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
        ),
      );
    } catch (_) {}
  }

  Future<void> _openMapExternally(LatLng pos) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}#map=17/${pos.latitude}/${pos.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح المتصفح')),
        );
      }
    }
  }

  Future<void> _goToMyLocation() async {
    final pos = await LocationHelper.getCurrentPosition(context);
    if (pos == null) return;
    final target = LatLng(pos.latitude, pos.longitude);
    setState(() => _mePoint = target);
    _mapController.move(target, 15);
  }

  List<Marker> get _allMarkers {
    final list = List<Marker>.from(_plantMarkers);
    if (_mePoint != null) {
      list.add(
        Marker(
          point: _mePoint!,
          width: 44,
          height: 44,
          alignment: Alignment.bottomCenter,
          child: Icon(
            Icons.person_pin_circle,
            color: Colors.blue.shade700,
            size: 42,
          ),
        ),
      );
    }
    return list;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('خريطة النباتات'),
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
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل الخريطة...',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialTarget,
                initialZoom: _plantLatLngs.isEmpty ? 10 : 12,
                minZoom: 3,
                maxZoom: 19,
                onMapReady: () {
                  if (_plantLatLngs.isNotEmpty) {
                    _applyBounds(_plantLatLngs);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: _allMarkers),
              ],
            ),
          if (!_loading && _error == null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://openstreetmap.org/copyright'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          if (!_loading && _error == null)
            Positioned(
              left: 16,
              bottom: 24,
              child: FloatingActionButton.small(
                heroTag: 'loc',
                backgroundColor: AppTheme.primary,
                onPressed: _goToMyLocation,
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          if (!_loading && _error == null && _plantLatLngs.isEmpty)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                color: scheme.surfaceContainerHighest.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'لا توجد نباتات بإحداثيات بعد. عند إضافة نبتة اختر «استخدام موقعي الحالي» ليظهر هنا.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
