import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'features/storage/data/hive_board_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local-first storage
  await Hive.initFlutter();

  // Pre-open boxes so repository access is instant and never blocks
  await Hive.openBox<Map>(HiveBoardRepository.metadataBoxName);
  await Hive.openBox<Map>(HiveBoardRepository.canvasBoxName);

  runApp(
    const ProviderScope(
      child: LocalBoardApp(),
    ),
  );
}
