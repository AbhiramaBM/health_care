import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/server_config_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _tabIndex = 0; // 0 = Doctor Email/Password, 1 = Phone OTP / PIN
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _usePin = true;
  bool _otpSent = false;
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  void _showForgotPasswordDialog() {
    final emailForgotController = TextEditingController(text: _emailController.text.trim());
    final otpForgotController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool codeSent = false;
    bool isResetting = false;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final auth = context.read<AuthProvider>();

          return AlertDialog(
            title: Text(codeSent ? 'Enter Reset Code' : 'Reset Doctor Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    codeSent
                        ? 'Enter the 6-digit verification code sent to ${emailForgotController.text.trim()} along with your new password.'
                        : 'Enter your registered doctor email address. We will send a 6-digit verification code.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  if (localError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.criticalRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        localError!,
                        style: const TextStyle(color: AppTheme.criticalRed, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!codeSent) ...[
                    TextField(
                      controller: emailForgotController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Email',
                        hintText: 'e.g. doctor@activehealth.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: otpForgotController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '6-Digit Code',
                        hintText: '123456',
                        prefixIcon: Icon(Icons.lock_clock_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter strong password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isResetting
                    ? null
                    : () async {
                        final email = emailForgotController.text.trim();
                        if (email.isEmpty) {
                          setDialogState(() => localError = 'Please enter your email');
                          return;
                        }

                        if (!codeSent) {
                          setDialogState(() {
                            isResetting = true;
                            localError = null;
                          });
                          final sent = await auth.forgotPassword(email);
                          setDialogState(() => isResetting = false);
                          if (sent) {
                            setDialogState(() => codeSent = true);
                          } else {
                            setDialogState(() => localError = auth.errorMessage ?? 'Failed to send reset code');
                          }
                        } else {
                          final otp = otpForgotController.text.trim();
                          final newPass = newPasswordController.text;
                          if (otp.length != 6) {
                            setDialogState(() => localError = 'Please enter the 6-digit code');
                            return;
                          }
                          if (newPass.length < 6) {
                            setDialogState(() => localError = 'Password must be at least 6 characters');
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          setDialogState(() {
                            isResetting = true;
                            localError = null;
                          });
                          final reset = await auth.resetPassword(
                            email: email,
                            otp: otp,
                            newPassword: newPass,
                          );
                          setDialogState(() => isResetting = false);
                          if (reset) {
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Password reset successfully! Please log in.'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          } else {
                            setDialogState(() => localError = auth.errorMessage ?? 'Password reset failed');
                          }
                        }
                      },
                child: isResetting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(codeSent ? 'Set New Password' : 'Send Code'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Health Centre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server Settings',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ServerConfigDialog(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'AHC Doctor Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Clinical Management & Patient Monitoring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Banner
                  if (authProvider.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.criticalRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.criticalRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.criticalRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.criticalRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => authProvider.clearError(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Login Mode Switcher
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Doctor Email'),
                        icon: Icon(Icons.email_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('OTP / PIN'),
                        icon: Icon(Icons.phone_android_outlined, size: 16),
                      ),
                    ],
                    selected: {_tabIndex},
                    onSelectionChanged: (val) {
                      setState(() {
                        _tabIndex = val.first;
                        authProvider.clearError();
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  if (_tabIndex == 0) ...[
                    // Doctor Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Email',
                        hintText: 'doctor@activehealth.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        if (email.isNotEmpty && password.isNotEmpty) {
                          authProvider.login(email: email, password: password).then((ok) {
                            if (ok) _onSuccess();
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Login Button
                    ElevatedButton(
                      onPressed: authProvider.status == AuthStatus.loading
                          ? null
                          : () async {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;
                              if (email.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter both email and password.'),
                                  ),
                                );
                                return;
                              }
                              final success = await authProvider.login(
                                email: email,
                                password: password,
                              );
                              if (success) _onSuccess();
                            },
                      child: authProvider.status == AuthStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Log In with Email'),
                    ),
                  ] else ...[
                    // Phone Number Field
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Registered Phone Number',
                        hintText: '10-digit mobile number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // PIN vs OTP toggle
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('4-Digit PIN'),
                          selected: _usePin,
                          onSelected: (val) {
                            if (val) setState(() => _usePin = true);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('SMS OTP'),
                          selected: !_usePin,
                          onSelected: (val) {
                            if (val) setState(() => _usePin = false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_usePin) ...[
                      // PIN Field
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Security PIN',
                          hintText: 'Enter 4 or 6 digit PIN',
                          prefixIcon: Icon(Icons.pin_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: authProvider.status == AuthStatus.loading
                            ? null
                            : () async {
                                final phone = _phoneController.text.trim();
                                final pin = _pinController.text.trim();
                                if (phone.isEmpty || pin.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter phone number and PIN.'),
                                    ),
                                  );
                                  return;
                                }
                                final ok = await authProvider.loginWithPin(
                                  phone: phone,
                                  pin: pin,
                                );
                                if (ok) _onSuccess();
                              },
                        child: authProvider.status == AuthStatus.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Log In with PIN'),
                      ),
                    ] else ...[
                      // OTP Flow
                      if (!_otpSent) ...[
                        ElevatedButton(
                          onPressed: _isSendingOtp
                              ? null
                              : () async {
                                  final phone = _phoneController.text.trim();
                                  if (phone.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter phone number.'),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => _isSendingOtp = true);
                                  final ok = await authProvider.sendOtp(phone);
                                  setState(() => _isSendingOtp = false);
                                  if (ok) {
                                    setState(() => _otpSent = true);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Verification OTP sent successfully!'),
                                          backgroundColor: AppTheme.successGreen,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: _isSendingOtp
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Send Verification OTP'),
                        ),
                      ] else ...[
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Verification OTP',
                            hintText: 'Enter 6-digit OTP',
                            prefixIcon: const Icon(Icons.lock_clock_outlined),
                            counterText: '',
                            suffixIcon: TextButton(
                              onPressed: () => setState(() => _otpSent = false),
                              child: const Text('Resend', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: authProvider.status == AuthStatus.loading
                              ? null
                              : () async {
                                  final phone = _phoneController.text.trim();
                                  final otp = _otpController.text.trim();
                                  if (phone.isEmpty || otp.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter phone and OTP.'),
                                      ),
                                    );
                                    return;
                                  }
                                  final ok = await authProvider.verifyOtp(
                                    phone: phone,
                                    otp: otp,
                                  );
                                  if (ok) _onSuccess();
                                },
                          child: authProvider.status == AuthStatus.loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Verify & Log In'),
                        ),
                      ],
                    ],
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Active Health Centre • Clinical Staff Only',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
