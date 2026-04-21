import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../api_service.dart';
import '../app_settings.dart';
import '../app_theme.dart';
import '../notification_service.dart';
import '../session_store.dart';
import '../user_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  String? _city;
  String? _homeType;
  List<String> _cities = [];
  List<String> _homeTypes = [];
  bool _loadingLists = true;
  bool _saving = false;
  bool _loadingProfile = true;
  bool _publicScanConsent = false;
  bool _savingConsent = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _nameController.text = UserProvider.userName ?? '';
    _city = UserProvider.city;
    _homeType = UserProvider.homeType;
    _publicScanConsent = UserProvider.plantPublicScanConsent;
    try {
      final cities = await ApiService.getCities();
      final ht = await ApiService.getHomeTypes();
      if (mounted) {
        setState(() {
          _cities = cities;
          _homeTypes = ht;
          _loadingLists = false;
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingLists = false;
          _loadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(AppSettings settings) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (x == null) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final dest = File('${dir.path}/avatar.jpg');
      await File(x.path).copy(dest.path);
      await settings.setAvatarPath(dest.path);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الصورة')),
        );
      }
    }
  }

  Future<void> _clearAvatar(AppSettings settings) async {
    final path = settings.avatarPath;
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await settings.setAvatarPath(null);
    if (mounted) setState(() {});
  }

  Future<void> _setPublicScanConsent(bool value) async {
    final uid = UserProvider.userId;
    if (uid == null) return;
    setState(() {
      _savingConsent = true;
      _publicScanConsent = value;
    });
    try {
      await ApiService.updateUser(uid, {'plant_public_scan_consent': value});
      UserProvider.mergeUser({'plant_public_scan_consent': value ? 1 : 0});
      await SessionStore.save(UserProvider.currentUser!);
    } catch (_) {
      if (mounted) {
        setState(() => _publicScanConsent = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ إعداد الخصوصية')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingConsent = false);
    }
  }

  Future<void> _saveProfile() async {
    final uid = UserProvider.userId;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await ApiService.updateUser(uid, {
        'name': _nameController.text.trim(),
        if (_city != null) 'city': _city,
        if (_homeType != null) 'home_type': _homeType,
      });
      UserProvider.mergeUser({
        'name': _nameController.text.trim(),
        'city': _city,
        'home_type': _homeType,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ البيانات'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحفظ — تحقق من السيرفر')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد المغادرة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('خروج')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await NotificationService.cancelAllCare();
    await SessionStore.clear();
    UserProvider.clearUser();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppTheme.fadeRoute(const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<AppSettings>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الإعدادات'),
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
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'الملف الشخصي',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: AppTheme.cardBg,
                            backgroundImage: settings.avatarPath != null &&
                                    File(settings.avatarPath!).existsSync()
                                ? FileImage(File(settings.avatarPath!))
                                : null,
                            child: settings.avatarPath == null ||
                                    !File(settings.avatarPath!).existsSync()
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 56,
                                    color: AppTheme.primary.withOpacity(0.7),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Material(
                              color: AppTheme.primary,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: () => _pickAvatar(settings),
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: settings.avatarPath != null
                            ? () => _clearAvatar(settings)
                            : null,
                        child: const Text('إزالة الصورة'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الظاهر',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                if (_loadingLists)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
                else ...[
                  DropdownButtonFormField<String>(
                    value: _city != null && _cities.contains(_city) ? _city : null,
                    decoration: const InputDecoration(
                      labelText: 'المدينة',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: _cities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _city = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _homeType != null && _homeTypes.contains(_homeType)
                        ? _homeType
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'نوع السكن',
                      prefixIcon: Icon(Icons.home_work_outlined),
                    ),
                    items: _homeTypes
                        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                        .toList(),
                    onChanged: (v) => setState(() => _homeType = v),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('حفظ بيانات الحساب'),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'الخصوصية والباركود',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'إظهار معلومات النبتة عند مسح الباركود',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'عند التفعيل يمكن لمن يمسح الرمز الاطلاع على بيانات النبتة دون تسجيل دخول (مثل وضع ملصق على النبتة).',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.7)
                          : scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  value: _publicScanConsent,
                  onChanged: _savingConsent ? null : _setPublicScanConsent,
                ),
                const SizedBox(height: 24),
                Text(
                  'المظهر والتنبيهات',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الوضع الداكن'),
                  subtitle: Text(
                    'تجربة قراءة مريحة ليلاً',
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6)),
                  ),
                  value: settings.darkMode,
                  onChanged: (v) => settings.setDarkMode(v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تذكيرات العناية بالنباتات'),
                  subtitle: Text(
                    'إشعارات الري والتسميد حسب الجدول',
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6)),
                  ),
                  value: settings.careNotificationsEnabled,
                  onChanged: (v) async {
                    await settings.setCareNotifications(v);
                    if (v) {
                      await NotificationService.syncCareReminders(UserProvider.userId);
                    } else {
                      await NotificationService.cancelAllCare();
                    }
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'حول التطبيق',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.map_outlined, color: scheme.onSurface.withOpacity(0.7)),
                  title: const Text('الخريطة'),
                  subtitle: Text(
                    'خرائط OpenStreetMap داخل التطبيق دون مفاتيح تجارية.',
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.65)),
                  ),
                ),
              ],
            ),
    );
  }
}
