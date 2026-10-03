import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'data/services/cloudinary_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration (.env) before anything reads it.
  await dotenv.load(fileName: '.env');

  // Firebase.apps guards against duplicate initialization on hot restart.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize Cloudinary with the unsigned upload preset from .env.
  // The API secret is never stored in the app.
  if (EnvConfig.isConfigured) {
    CloudinaryService.instance.initialize();
  }

  runApp(const ProviderScope(child: HirayaAklatanApp()));
}