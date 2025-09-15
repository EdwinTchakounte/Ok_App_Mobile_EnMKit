import 'package:enmkit/models/users_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/viewmodels/authViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int _currentPage = 0;

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        final route = next.user!.isAdmin
            ? const Placeholder() // TODO: DashboardScreen()
            : const Placeholder(); // TODO: HomeScreen()
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => route),
        );
      }
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo
            Center(
              child: Image.asset(
                'assets/logo.png', // ton logo
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildAuthCard(
                    title: 'CONNEXION',
                    authState: authState,
                    fields: [
                      _buildTextField(
                          controller: _phoneController,
                          label: 'Numéro de téléphone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          icon: Icons.lock,
                          obscure: true),
                    ],
                    buttonText: 'Se connecter',
                    
                    onPressed: () {
                      ref.read(authProvider.notifier).login(
                            _phoneController.text.trim(),
                            _passwordController.text.trim(),
                          );
                    },
                    switchText: "Pas de compte ? Inscrivez-vous",
                    switchAction: () => _goToPage(1),
                  ),
                  _buildAuthCard(
                    title: 'INCRIPTION',
                    authState: authState,
                    fields: [
                      _buildTextField(
                          controller: _phoneController,
                          label: 'Numéro de téléphone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          icon: Icons.lock,
                          obscure: true),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmer le mot de passe',
                          icon: Icons.lock_outline,
                          obscure: true),
                    ],
                    buttonText: 'S\'inscrire',
                    onPressed: () {
                      if (_passwordController.text.trim() !=
                          _confirmPasswordController.text.trim()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Les mots de passe ne correspondent pas")),
                        );
                        return;
                      }
                      ref.read(authProvider.notifier).registerUser(
                            UserModel(
                              phoneNumber: _phoneController.text.trim(),
                              password: _passwordController.text.trim(),
                            ),
                          );
                    },
                    switchText: "Déjà un compte ? Connectez-vous",
                    switchAction: () => _goToPage(0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildPageIndicator(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard({
    required String title,
    required AuthState authState,
    required List<Widget> fields,
    required String buttonText,
    required VoidCallback onPressed,
    required String switchText,
    required VoidCallback switchAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 25, 118, 210),),
            ),
            const SizedBox(height: 24),
            ...fields,
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(buttonText, style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white, // <-- texte toujours blanc
        ),),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: switchAction,
              child: Text(switchText,),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 24 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}
