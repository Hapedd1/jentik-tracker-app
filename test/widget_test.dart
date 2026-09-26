import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🔥 Wajib ditambah untuk Riverpod

import 'package:jentik_nyamuk/main.dart';
// ⚠️ GANTI JALUR INI JIKA BERBEDA DI FOLDERMU
import 'package:jentik_nyamuk/features/auth/presentation/pages/pilih_peran_screen.dart';

void main() {
  testWidgets('Aplikasi Jentik Tracker Berhasil Dirender', (
    WidgetTester tester,
  ) async {
    // 1. Bangun aplikasi kita dengan menyertakan ProviderScope dan tiket halamanTujuan
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(
          // Memberikan halaman dummy agar MyApp tidak error
          halamanTujuan: PilihPeranScreen(),
        ),
      ),
    );

    // 2. Tes sederhana: Pastikan aplikasi (MaterialApp) berhasil dimuat tanpa error
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
