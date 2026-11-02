import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/core_ui/views/main_dashboard_screen.dart';
import 'features/auth/views/login_page.dart';
import 'features/auth/providers/auth_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Firebase සම්බන්ධ කිරීම
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Auraaxon Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        primaryColor: const Color(0xFF6C63FF),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainDashboardScreen();
          }
          return const LoginPage();
        },
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF1E1E2C),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        ),
        error: (e, s) => Scaffold(
          backgroundColor: const Color(0xFF1E1E2C),
          body: Center(
            child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}
