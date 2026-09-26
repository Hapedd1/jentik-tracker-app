import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl =
    'https://womb-catnip-unweave.ngrok-free.dev/api'; // Sesuaikan IP jika perlu

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // FUNGSI REGISTER
  Future<String?> register({
    required String namaLengkap,
    required String email,
    required String noHp,
    required String password,
    required String role, // 🔥 PARAMETER BARU
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_lengkap': namaLengkap,
          'email': email,
          'no_hp': noHp,
          'password': password,
          'role': role, // 🔥 KIRIM ROLE KE SERVER
        }),
      );
      if (response.statusCode == 201) return null;
      return jsonDecode(response.body)['error'] ?? 'Gagal membuat akun';
    } catch (e) {
      return 'Gagal terhubung ke server.';
    }
  }

  // FUNGSI LOGIN
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userData = data['user'] ?? {};

        // 🔥 SIMPAN SEMUA DATA PENTING KE BRANKAS HP 🔥
        await prefs.setString('token', data['token']);
        // Menangkap role murni dari database (bukan dari UI)
        await prefs.setString('role', data['role'] ?? 'murid');

        // 🔥 INI PENYELAMATNYA: Menangkap kode organisasi dari server
        await prefs.setString('kodeOrganisasi', data['kodeOrganisasi'] ?? '');

        await prefs.setString('email', userData['email'] ?? email);
        await prefs.setString(
          'nama_lengkap',
          userData['nama_lengkap'] ?? 'Tanpa Nama',
        );
        await prefs.setString('no_hp', userData['no_hp'] ?? '-');
        await prefs.setString('foto_profil', userData['foto_profil'] ?? '');

        return null; // Sukses, tidak ada pesan error
      } else {
        return data['error'] ?? 'Gagal login';
      }
    } catch (e) {
      return 'Gagal terhubung ke server.';
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(() => AuthNotifier());
