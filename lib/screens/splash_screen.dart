import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/database_service.dart';
import '../widgets/privacy_welcome_dialog.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

/// Splash Screen Animada e Inteligente
/// Design: Dark Fintech Theme com gradiente diagonal
/// Funcionalidade: Verificação de privacidade e roteamento inteligente
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Inicialização assíncrona do aplicativo
  /// 1. Aguarda animações (3s)
  /// 2. Verifica aceitação de privacidade
  /// 3. Redireciona para tela apropriada
  Future<void> _initializeApp() async {
    // Aguardar animações da splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Verificar aceitação de privacidade
    final db = DatabaseService();
    final hasAcceptedPrivacy = db.hasAcceptedPrivacy();

    if (!hasAcceptedPrivacy) {
      // Primeira execução - mostrar Privacy Welcome Dialog
      final accepted = await PrivacyWelcomeDialog.showIfNeeded(context);
      
      if (!accepted && mounted) {
        // Usuário recusou - fechar app
        Navigator.of(context).pop();
        return;
      }
    }

    if (!mounted) return;

    // Verificar se usa App Lock (biometria)
    final useAppLock = db.getAppLockEnabled();

    // Navegar para tela apropriada
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => useAppLock ? const AuthScreen() : const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ✨ Background: Gradiente diagonal Dark Fintech Theme
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027), // Deep Blue
              Color(0xFF203A43), // Medium Blue-Gray
              Color(0xFF2C5364), // Teal-Blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // 🎨 Logo Composto: Wallet + Mic
                ZoomIn(
                  duration: const Duration(milliseconds: 1200),
                  child: _buildComposedLogo(),
                ),
                
                const SizedBox(height: 40),
                
                // 📝 Título Principal
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'FinAgeVoz',
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 💬 Slogan
                FadeInUp(
                  delay: const Duration(milliseconds: 1000),
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'Sua vida organizada pela voz',
                    style: GoogleFonts.sourceSans3(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 🔹 Linha decorativa
                FadeInUp(
                  delay: const Duration(milliseconds: 1200),
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00E5FF),
                          Color(0xFF00BCD4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // ⏳ Loading Indicator
                FadeInUp(
                  delay: const Duration(milliseconds: 1600),
                  duration: const Duration(milliseconds: 600),
                  child: const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 📱 Versão e Copyright
                FadeInUp(
                  delay: const Duration(milliseconds: 1800),
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      Text(
                        'v1.0.0',
                        style: GoogleFonts.sourceSans3(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© 2025 Multiverso Digital',
                        style: GoogleFonts.sourceSans3(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o logo composto (Wallet + Mic)
  /// Stack: Wallet (fundo) + Mic (frente)
  Widget _buildComposedLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00E5FF).withOpacity(0.2),
            const Color(0xFF00BCD4).withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 💰 Wallet (Fundo) - Maior e mais transparente
          Positioned(
            child: FaIcon(
              FontAwesomeIcons.wallet,
              size: 70,
              color: const Color(0xFF00E5FF).withOpacity(0.6),
            ),
          ),
          
          // 🎤 Mic (Frente) - Menor e mais opaco
          Positioned(
            bottom: 35,
            right: 35,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2027),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00E5FF),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                size: 28,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
