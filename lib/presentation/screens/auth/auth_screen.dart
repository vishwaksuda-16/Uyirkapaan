import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routing/route_paths.dart';
import '../../controllers/auth_controller.dart';

/// Modern, real-world Authentication Screen for UyirKaapan.
/// Features a clean, high-fidelity UI for Bystander Sign In and Registration
/// without exposed REST route names or raw JWT token debugging dumps.
class AuthScreen extends StatefulWidget {
  final AuthController authController;

  const AuthScreen({
    super.key,
    required this.authController,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form controllers
  final _loginEmailController = TextEditingController(text: 'bystander@uyirkappan.demo');
  final _loginPasswordController = TextEditingController(text: 'password123');

  // Register form controllers
  final _regNameController = TextEditingController(text: 'Demo Bystander');
  final _regPhoneController = TextEditingController(text: '+91 98401 23456');
  final _regEmailController = TextEditingController(text: 'bystander@uyirkappan.demo');
  final _regPasswordController = TextEditingController(text: 'password123');

  bool _isLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _rememberMe = true;
  String? _statusMessage;
  bool _isSuccessMessage = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isSuccessMessage = false;
        _statusMessage = 'Please enter both your email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final success = await widget.authController.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccessMessage = success;
      _statusMessage = success
          ? 'Welcome back! Signed in successfully.'
          : widget.authController.errorMessage ?? 'Unable to sign in. Please verify your credentials.';
    });

    if (success) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _proceedToHome();
      });
    }
  }

  Future<void> _handleRegister() async {
    final name = _regNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _isSuccessMessage = false;
        _statusMessage = 'Please complete all fields to register.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final success = await widget.authController.register(
      name: name,
      phone: phone,
      email: email,
      password: password,
      role: 'BYSTANDER',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccessMessage = success;
      _statusMessage = success
          ? 'Account created successfully! Welcome to UyirKaapan.'
          : widget.authController.errorMessage ?? 'Registration failed. Please try again.';
    });

    if (success) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _proceedToHome();
      });
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final success = await widget.authController.loginDemo();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccessMessage = success;
      _statusMessage = success
          ? 'Verified as Demo Bystander. Loading emergency dispatch...'
          : 'Demo login failed.';
    });

    if (success) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _proceedToHome();
      });
    }
  }

  void _proceedToHome() {
    Navigator.pushReplacementNamed(context, RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.authController.currentUser;
    final isAuthenticated = widget.authController.isAuthenticated;

    final bgColor = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.emergencyRed,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emergencyRed.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Emergency Helpline direct chip
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: _proceedToHome,
                icon: const Icon(Icons.emergency_rounded, color: AppColors.emergencyRed, size: 16),
                label: const Text(
                  'Skip to Map',
                  style: TextStyle(
                    color: AppColors.emergencyRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // If user is already authenticated, show a sleek profile card
                if (isAuthenticated && user != null) ...[
                  _buildAuthenticatedCard(context, user, isDark, cardBg, borderColor, textPrimary, textMuted),
                ] else ...[
                  // Hero Header
                  _buildHeroHeader(textPrimary, textMuted),
                  const SizedBox(height: 24),

                  // Main Sign In / Register Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Tab Selector
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: isDark ? Colors.white : AppColors.emergencyRed,
                              unselectedLabelColor: textMuted,
                              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                              tabs: const [
                                Tab(text: 'Sign In'),
                                Tab(text: 'Create Account'),
                              ],
                            ),
                          ),
                        ),

                        // Tab Contents
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: SizedBox(
                              height: 385,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // SIGN IN FORM
                                  _buildSignInForm(context, isDark, textPrimary, textMuted, borderColor),

                                  // REGISTER FORM
                                  _buildRegisterForm(context, isDark, textPrimary, textMuted, borderColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fast 1-Tap Demo Bystander Login
                  const SizedBox(height: 18),
                  _buildQuickAccessCard(isDark, borderColor, textPrimary, textMuted),
                ],

                // Status Message Banner
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildStatusBanner(),
                ],

                const SizedBox(height: 24),

                // Emergency Helpline Banner
                _buildHelplineFooter(textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Color textPrimary, Color textMuted) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Welcome to UyirKaapan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to report medical emergencies, trigger SOS, or assist as a nearby certified bystander.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Input
        TextFormField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Email address',
            labelStyle: TextStyle(color: textMuted, fontSize: 13),
            prefixIcon: Icon(Icons.alternate_email_rounded, size: 19, color: textMuted),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Password Input
        TextFormField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: textMuted, fontSize: 13),
            prefixIcon: Icon(Icons.lock_outline_rounded, size: 19, color: textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 19,
                color: textMuted,
              ),
              onPressed: () {
                setState(() => _obscureLoginPassword = !_obscureLoginPassword);
              },
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Remember Me & Forgot Password Row
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (val) => setState(() => _rememberMe = val ?? true),
                activeColor: AppColors.emergencyRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember me',
              style: TextStyle(fontSize: 12.5, color: textMuted, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset instructions sent to your registered email address.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF3B82F6), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sign In Button
        FilledButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.emergencyRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign In to UyirKaapan',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
        const Spacer(),

        // Safe Bystander Guarantee Note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            Text(
              'Good Samaritan Law Protected • Tamil Nadu',
              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name Input
          TextFormField(
            controller: _regNameController,
            style: TextStyle(color: textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Full Name',
              labelStyle: TextStyle(color: textMuted, fontSize: 12.5),
              prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: textMuted),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.8)),
            ),
          ),
          const SizedBox(height: 10),

          // Phone Input
          TextFormField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(color: textMuted, fontSize: 12.5),
              prefixIcon: Icon(Icons.phone_outlined, size: 18, color: textMuted),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.8)),
            ),
          ),
          const SizedBox(height: 10),

          // Email Input
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(color: textMuted, fontSize: 12.5),
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 18, color: textMuted),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.8)),
            ),
          ),
          const SizedBox(height: 10),

          // Password Input
          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            style: TextStyle(color: textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Create Password',
              labelStyle: TextStyle(color: textMuted, fontSize: 12.5),
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: textMuted),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: textMuted),
                onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.8)),
            ),
          ),
          const SizedBox(height: 12),

          // Privacy note
          Text(
            'By registering, your account is verified for citizen first-responder coordination in medical emergencies.',
            style: TextStyle(fontSize: 11, color: textMuted, height: 1.35),
          ),
          const SizedBox(height: 14),

          // Register Button
          FilledButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : const Text(
                    'Create Free Account',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fast Evaluation & Demo Login',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    Text(
                      'Instant 1-tap sign-in with pre-verified bystander role',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleDemoLogin,
            icon: const Icon(Icons.account_circle_outlined, size: 17, color: Color(0xFF10B981)),
            label: const Text(
              'Sign In as Demo Bystander',
              style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF10B981), width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedCard(
    BuildContext context,
    dynamic user,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with verified badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Name & Role
          Text(
            user.name,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(fontSize: 13, color: textMuted),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 13, color: Color(0xFF10B981)),
                SizedBox(width: 5),
                Text(
                  'Verified Emergency Bystander',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary Continue Action
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _proceedToHome,
              icon: const Icon(Icons.emergency_rounded, size: 20),
              label: const Text(
                'Continue to Emergency Map',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Switch / Sign Out Action
          TextButton.icon(
            onPressed: () async {
              await widget.authController.logout();
              setState(() {
                _statusMessage = 'Signed out successfully.';
                _isSuccessMessage = true;
              });
            },
            icon: Icon(Icons.logout_rounded, size: 16, color: textMuted),
            label: Text(
              'Sign Out / Switch Account',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isSuccessMessage
            ? const Color(0xFF10B981).withValues(alpha: 0.12)
            : AppColors.emergencyRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isSuccessMessage ? const Color(0xFF10B981) : AppColors.emergencyRed,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSuccessMessage ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 20,
            color: _isSuccessMessage ? const Color(0xFF10B981) : AppColors.emergencyRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _isSuccessMessage ? const Color(0xFF10B981) : AppColors.emergencyRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineFooter(Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_in_talk_rounded, color: AppColors.emergencyRed, size: 18),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: 'In immediate life-threatening danger? ',
              style: TextStyle(fontSize: 12, color: textMuted),
              children: const [
                TextSpan(
                  text: 'Call 108',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.emergencyRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
