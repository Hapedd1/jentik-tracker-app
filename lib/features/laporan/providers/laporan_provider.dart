import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Sesuaikan URL jika dites di HP asli (gunakan IP Laptop, misal: 192.168.x.x)
const String baseUrl = 'https://womb-catnip-unweave.ngrok-free.dev/api';

class LaporanNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Status awal tidak loading
  }

  Future<String?> kirimLaporan({
    required String namaLokasi,
    required String kondisiAir,
    required int jumlahJentik,
    required String catatan,
  }) async {
    try {
      state = true; // Set loading memutar

      // 1. Ambil Kode Organisasi dari Brankas
      final prefs = await SharedPreferences.getInstance();
      final kodeOrg = prefs.getString('kodeOrganisasi');

      if (kodeOrg == null || kodeOrg.isEmpty) {
        state = false;
        return "Gagal: Anda tidak tergabung dalam organisasi mana pun.";
      }

      // 2. Kirim ke Backend Node.js
      final response = await http.post(
        Uri.parse('$baseUrl/laporan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kode_organisasi': kodeOrg,
          'nama_lokasi': namaLokasi,
          'kondisi_air': kondisiAir,
          'jumlah_jentik': jumlahJentik,
          'catatan': catatan,
          'latitude': -6.9828, // Dummy kordinat Semarang sementara
          'longitude': 110.4307,
        }),
      );

      state = false; // Matikan loading

      if (response.statusCode == 201) {
        return null; // Sukses! (Kembalikan null agar UI tahu ini berhasil)
      } else {
        final data = jsonDecode(response.body);
        return data['error'] ?? "Gagal menyimpan laporan.";
      }
    } catch (e) {
      state = false;
      return "Terjadi kesalahan koneksi server.";
    }
  }
}

final laporanProvider = NotifierProvider<LaporanNotifier, bool>(() {
  return LaporanNotifier();
});

// ... kode laporan_provider kamu yang sebelumnya ada di atas ...

// TAMBAHKAN INI DI PALING BAWAH FILE:
final daftarLaporanProvider = FutureProvider<List<dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final kodeOrg = prefs.getString('kodeOrganisasi') ?? '';

  if (kodeOrg.isEmpty) return [];

  // Panggil endpoint GET dari server Node.js
  final response = await http.get(
    Uri.parse('$baseUrl/laporan?kode_organisasi=$kodeOrg'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['laporan'] ?? []; // Kembalikan daftar laporan dari Neon
  } else {
    throw Exception('Gagal mengambil data laporan');
  }
});
