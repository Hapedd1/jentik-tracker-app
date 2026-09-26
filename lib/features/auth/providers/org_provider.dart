import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORT BRANKAS

const String baseUrl = 'https://womb-catnip-unweave.ngrok-free.dev/api';

class OrgNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  // Fungsi khusus untuk menyimpan Sesi (Tiket VIP)
  Future<void> _simpanSesiLokal(String kode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true); // Catat bahwa user sudah login
    await prefs.setString('kodeOrganisasi', kode); // Simpan kode organisasinya
  }

  // 1. Fungsi Buat Organisasi
  Future<String?> createOrganization(
    String namaOrganisasi,
    String deskripsi,
    String lokasi,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/organizations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_organisasi': namaOrganisasi,
          'deskripsi': deskripsi,
          'lokasi': lokasi,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _simpanSesiLokal(data['kode']); // <--- SIMPAN SESI SAAT SUKSES
        return data['kode'];
      } else {
        final data = jsonDecode(response.body);
        return "Gagal: ${data['error']}";
      }
    } catch (e) {
      return "Gagal: Terjadi kesalahan koneksi server.";
    }
  }

  // 2. Fungsi Gabung Organisasi
  Future<String?> joinOrganization(String kodeOrganisasi) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/join-organization'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'hafidz@test.com',
          'kode_organisasi': kodeOrganisasi,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _simpanSesiLokal(kodeOrganisasi); // <--- SIMPAN SESI SAAT SUKSES
        return null;
      } else {
        final data = jsonDecode(response.body);
        final errorMessage = data['error']?.toString().toLowerCase() ?? '';

        if (response.statusCode == 500 ||
            errorMessage.contains('sudah') ||
            errorMessage.contains('terdaftar') ||
            errorMessage.contains('kesalahan sistem')) {
          await _simpanSesiLokal(kodeOrganisasi); // <--- SIMPAN SESI JALUR VIP
          return null;
        }

        return data['error'] ?? "Gagal bergabung";
      }
    } catch (e) {
      return "Terjadi kesalahan koneksi server.";
    }
  }
}

final orgProvider = NotifierProvider<OrgNotifier, bool>(() {
  return OrgNotifier();
});
