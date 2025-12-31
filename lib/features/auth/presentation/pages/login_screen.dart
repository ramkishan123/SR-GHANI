import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/auth_service.dart';
import 'package:sr_ghani/features/auth/presentation/pages/register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildInputFields(),
                  const SizedBox(height: 32),
                  _buildLoginButton(),
                  const SizedBox(height: 12),
                  _buildForgotPasswordLink(),
                  const SizedBox(height: 12),
                  _buildRegisterLink(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.oil_barrel_rounded, size: 64, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome to\nSR Ghani',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Premium oil extraction management',
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(24),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const Divider(height: 1, indent: 60),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).primaryColor),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(24),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return _isLoading
        ? CircularProgressIndicator(color: Theme.of(context).primaryColor)
        : ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 68),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
            ),
            child: const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          );
  }

  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: () => _forgotPassword(context),
      child: Text(
        'Forgot Password?',
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('New user?', style: TextStyle(color: Colors.grey[600])),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            'Create Account',
            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _forgotPassword(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_emailController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }
    try {
      await ref.read(authServiceProvider).resetPassword(_emailController.text.trim());
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        debugPrint('Attempting login for: ${_emailController.text.trim()}');
        await ref.read(authServiceProvider).signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        debugPrint('Login call completed successfully');
      } catch (e) {
        debugPrint('Login failed with error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
