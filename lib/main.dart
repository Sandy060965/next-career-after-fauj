import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/services/profile_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/jd_match/jd_match_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';

void main() {
  runApp(const NextCareerAfterFaujApp());
}

class NextCareerAfterFaujApp extends StatelessWidget {
  const NextCareerAfterFaujApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileRepository(),
      child: MaterialApp(
        title: 'Next Career After Fauj',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.onboarding,
        routes: {
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.jdMatch: (_) => const JdMatchScreen(),
        },
      ),
    );
  }
}
