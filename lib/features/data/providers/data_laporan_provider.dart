import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://womb-catnip-unweave.ngrok-free.dev/api';

class DataLaporanNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() async {
    return _fetchLaporan();
  }

  // Fungsi untuk mengambil data dari backend
  Future<List<dynamic>> _fetchLaporan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kodeOrg = prefs.getString('kodeOrganisasi') ?? '';

      // Panggil endpoint backend-mu (Pastikan endpoint ini sesuai dengan route di Node.js)
      final response = await http.get(
        Uri.parse('$baseUrl/laporan?kode_organisasi=$kodeOrg'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['laporan'] ??
            []; // Asumsi backend mengembalikan objek { "laporan": [...] }
      } else {
        // Jika backend belum siap/error, kita kembalikan list kosong sementara
        return [];
      }
    } catch (e) {
      throw Exception("Gagal memuat data laporan.");
    }
  }

  // Fungsi untuk menyegarkan data (dipanggil setelah user membuat laporan baru)
  Future<void> refreshData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLaporan());
  }
}

final dataLaporanProvider =
    AsyncNotifierProvider<DataLaporanNotifier, List<dynamic>>(() {
      return DataLaporanNotifier();
    });
