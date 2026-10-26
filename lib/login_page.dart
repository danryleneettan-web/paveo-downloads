import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool creatingAccount = false;
  bool obscurePassword = true;
  bool loading = false;
  String message = '';
  bool messageIsError = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    setState(() {
      loading = true;
      message = '';
    });
    try {
      final auth = FirebaseAuth.instance;
      UserCredential credential;
      if (creatingAccount) {
        final displayName = name.text.trim().isEmpty
            ? 'Citizen'
            : name.text.trim();
        credential = await auth.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
        await credential.user!.updateDisplayName(displayName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({'name': displayName, 'role': 'citizen'});
      } else {
        credential = await auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
        // Both citizens and administrators use this same sign-in form. Their
        // trusted profile role controls what the app exposes after sign-in.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();
      }
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          message =
              e.message ??
              'Could not sign in. Check your details and try again.';
          messageIsError = true;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          message =
              e.message ?? 'We could not load your account. Please try again.';
          messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> sendPasswordReset() async {
    final address = email.text.trim();
    if (address.isEmpty) {
      setState(() {
        message = 'Enter your email address first.';
        messageIsError = true;
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: address);
      if (mounted) {
        setState(() {
          message = 'Password reset instructions were sent to $address.';
          messageIsError = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          message = e.message ?? 'Could not send a reset email.';
          messageIsError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      backgroundColor: landingCanvas,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _LoginWaves())),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  top: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Back to Paveo',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 44 : 22,
                      72,
                      wide ? 44 : 22,
                      32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1020),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _welcomePanel()),
                                const SizedBox(width: 40),
                                SizedBox(width: 470, child: _formCard()),
                              ],
                            )
                          : Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 470,
                                ),
                                child: _mobileLoginContent(),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomePanel() => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PaveoBrandLockup(iconSize: 58, wordmarkSize: 31),
        const SizedBox(height: 42),
        Text(
          'Safer roads start with a report.',
          style: GoogleFonts.poppins(
            color: charcoal,
            fontSize: 42,
            height: 1.12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sign in to share a road concern, follow its progress, and help your community get repairs moving.',
          style: TextStyle(color: gray, fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _WelcomeChip(icon: Icons.add_a_photo_outlined, label: 'Report'),
            _WelcomeChip(icon: Icons.handyman_outlined, label: 'Respond'),
            _WelcomeChip(icon: Icons.route_outlined, label: 'Restore'),
          ],
        ),
      ],
    ),
  );

  Widget _formCard() => Card(
    elevation: 3,
    shadowColor: charcoal.withValues(alpha: .10),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PaveoBrandLockup(iconSize: 52, wordmarkSize: 28),
          const SizedBox(height: 26),
          Text(
            creatingAccount ? 'Join your community' : 'Welcome back',
            style: GoogleFonts.poppins(
              color: charcoal,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            creatingAccount
                ? 'Create a citizen account to report road issues.'
                : 'Sign in to continue to Paveo.',
            style: const TextStyle(color: gray, fontSize: 14),
          ),
          const SizedBox(height: 22),
          if (message.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: messageIsError
                    ? peach.withValues(alpha: .32)
                    : const Color(0xFFE4ECE3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: messageIsError ? peach : sage),
              ),
              child: Text(
                message,
                style: const TextStyle(color: charcoal, height: 1.35),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (creatingAccount) ...[
            _labeledField(
              controller: name,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
          ],
          _labeledField(
            controller: email,
            label: 'Email address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _labeledField(
            controller: password,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => loading ? null : authenticate(),
            suffix: IconButton(
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          if (!creatingAccount)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: sendPasswordReset,
                child: const Text('Forgot password?'),
              ),
            )
          else
            const SizedBox(height: 14),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: loading ? null : authenticate,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ivory,
                      ),
                    )
                  : Icon(
                      creatingAccount
                          ? Icons.person_add_alt_1_rounded
                          : Icons.login_rounded,
                    ),
              label: Text(creatingAccount ? 'Create account' : 'Sign in'),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                creatingAccount ? 'Already have an account?' : 'New to Paveo?',
                style: const TextStyle(color: gray, fontSize: 13),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () => setState(() {
                        creatingAccount = !creatingAccount;
                        message = '';
                      }),
                child: Text(creatingAccount ? 'Sign in' : 'Create account'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Administrator access is enabled only for accounts assigned the admin role.',
            textAlign: TextAlign.center,
            style: TextStyle(color: gray, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    ),
  );

  Widget _mobileLoginContent() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Image.asset(
            'assets/brand/paveo-app-mark.png',
            width: 76,
            height: 76,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          creatingAccount ? 'Join your community' : 'Welcome back!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: charcoal,
            fontSize: 29,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          creatingAccount
              ? 'Create an account to continue to Paveo.'
              : 'Log in to continue to Paveo.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: gray, fontSize: 16),
        ),
        const SizedBox(height: 30),
        if (message.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: messageIsError
                  ? peach.withValues(alpha: .32)
                  : const Color(0xFFE4ECE3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: messageIsError ? peach : sage),
            ),
            child: Text(message, style: const TextStyle(color: charcoal)),
          ),
          const SizedBox(height: 16),
        ],
        if (creatingAccount) ...[
          _mobileInput(
            controller: name,
            label: 'Full name',
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
        ],
        _mobileInput(
          controller: email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 18),
        _mobileInput(
          controller: password,
          label: 'Password',
          obscure: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => loading ? null : authenticate(),
          suffix: IconButton(
            tooltip: obscurePassword ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => obscurePassword = !obscurePassword),
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: gray,
            ),
          ),
        ),
        if (!creatingAccount)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: sendPasswordReset,
              child: const Text('Forgot password?'),
            ),
          )
        else
          const SizedBox(height: 14),
        const SizedBox(height: 10),
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: loading ? null : authenticate,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ivory,
                    ),
                  )
                : Text(creatingAccount ? 'Create account' : 'Log In'),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: loading
                ? null
                : () => setState(() {
                    creatingAccount = !creatingAccount;
                    message = '';
                  }),
            child: Text(
              creatingAccount
                  ? 'Already have an account? Log in'
                  : 'Create an account',
              style: const TextStyle(
                color: charcoal,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _mobileInput({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: gray,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 54,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: label,
            suffixIcon: suffix,
            filled: true,
            fillColor: ivory,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: sage, width: 1.4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: sage, width: 1.4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: green, width: 1.8),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _labeledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
    ),
  );
}

class _WelcomeChip extends StatelessWidget {
  const _WelcomeChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
    decoration: BoxDecoration(
      color: ivory.withValues(alpha: .86),
      border: Border.all(color: sage.withValues(alpha: .55)),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: green),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: charcoal, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _LoginWaves extends CustomPainter {
  const _LoginWaves();

  @override
  void paint(Canvas canvas, Size size) {
    final top = Path()
      ..moveTo(size.width * .62, 0)
      ..cubicTo(
        size.width * .73,
        size.height * .14,
        size.width * .88,
        size.height * .15,
        size.width,
        size.height * .24,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(top, Paint()..color = const Color(0xFFDCE4D8));
    final bottom = Path()
      ..moveTo(0, size.height * .72)
      ..cubicTo(
        size.width * .24,
        size.height * .76,
        size.width * .28,
        size.height * .91,
        size.width * .52,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bottom, Paint()..color = const Color(0xFFCAD6C7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
