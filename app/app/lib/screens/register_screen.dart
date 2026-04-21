import 'package:flutter/material.dart';
import '../api_service.dart';
import '../user_provider.dart';
import '../app_theme.dart';
import '../main_shell.dart';
import '../session_store.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _selectedCity;
  String? _selectedHomeType;
  List<String> _cities = [];
  List<String> _homeTypes = [];
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _loadCitiesAndHomeTypes();
  }

  Future<void> _loadCitiesAndHomeTypes() async {
    try {
      final results = await Future.wait([
        ApiService.getCities(),
        ApiService.getHomeTypes(),
      ]);
      if (mounted) {
        setState(() {
          _cities = List<String>.from(results[0]);
          _homeTypes = List<String>.from(results[1]);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('إنشاء حساب'),
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل الاسم' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل البريد' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور (٤ أحرف على الأقل)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 4
                      ? 'كلمة المرور ٤ أحرف على الأقل'
                      : null,
                ),
                if (_cities.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'المدينة (اختياري - للتوصيات)',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-- اختر --')),
                      ..._cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => setState(() => _selectedCity = v),
                  ),
                ],
                if (_homeTypes.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _selectedHomeType,
                    decoration: const InputDecoration(
                      labelText: 'نوع المنزل (اختياري - للتوصيات)',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-- اختر --')),
                      ..._homeTypes.map((h) => DropdownMenuItem(value: h, child: Text(h))),
                    ],
                    onChanged: (v) => setState(() => _selectedHomeType = v),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _loading = true);
                            try {
                              final res = await ApiService.register(
                                nameController.text.trim(),
                                emailController.text.trim(),
                                passwordController.text,
                                city: _selectedCity,
                                homeType: _selectedHomeType,
                              );
                              if (!context.mounted) return;
                              if (res.containsKey('error')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['error'] as String),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                final merged = Map<String, dynamic>.from(res);
                                if (_selectedCity != null) {
                                  merged['city'] = _selectedCity;
                                }
                                if (_selectedHomeType != null) {
                                  merged['home_type'] = _selectedHomeType;
                                }
                                UserProvider.setUser(merged);
                                await SessionStore.save(merged);
                                if (!context.mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  AppTheme.slideRoute(const MainShell()),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تحقق من تشغيل السيرفر'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() => _loading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'إنشاء حساب',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
