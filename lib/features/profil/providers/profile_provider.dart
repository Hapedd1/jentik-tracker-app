import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kita pakai FutureProvider karena membaca memori butuh waktu sepersekian detik
final profileProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  // Ambil data dari brankas, kasih nilai default kosong kalau tidak ketemu
  final kodeOrg = prefs.getString('kodeOrganisasi') ?? 'Belum ada organisasi';
  final role = prefs.getString('role') ?? 'murid'; // Default murid jika nyasar

  return {'kodeOrganisasi': kodeOrg, 'role': role};
});
