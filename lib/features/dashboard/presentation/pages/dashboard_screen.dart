import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ⚠️ PASTIKAN IMPORT INI JALURNYA BENAR SESUAI FOLDERMU
import 'package:jentik_nyamuk/features/laporan/providers/laporan_provider.dart';
import 'package:jentik_nyamuk/features/laporan/presentation/pages/detail_laporan_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _role = 'Memuat...';
  String _kodeOrg = '...';
  String _namaUser = 'Memuat...';

  bool _isLoadingAnggota = true;
  List _anggotaList = [];
  bool _isAnggotaExpanded = false;

  final Color primaryGreen = const Color(0xFF1D8B41);

  @override
  void initState() {
    super.initState();
    _inisialisasiDashboard();
  }

  Future<void> _inisialisasiDashboard() async {
    await _loadDataSesi();
    await _fetchAnggotaLangsung();
  }

  Future<void> _loadDataSesi() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'murid';
      _kodeOrg = prefs.getString('kodeOrganisasi') ?? '-';
      _namaUser = prefs.getString('nama_lengkap') ?? 'Relawan';
    });
  }

  Future<void> _fetchAnggotaLangsung() async {
    setState(() => _isLoadingAnggota = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://womb-catnip-unweave.ngrok-free.dev/api/organizations/$_kodeOrg/members',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _anggotaList = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error jaringan anggota: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAnggota = false);
    }
  }

  Future<void> _toggleRoleRahasia() async {
    final prefs = await SharedPreferences.getInstance();
    final peranSaatIni = prefs.getString('role') ?? 'murid';
    final peranBaru = peranSaatIni == 'guru' ? 'murid' : 'guru';

    await prefs.setString('role', peranBaru);
    setState(() {
      _role = peranBaru;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jalur Rahasia: Kamu login sebagai ${peranBaru.toUpperCase()}!',
          ),
          backgroundColor: peranBaru == 'guru' ? Colors.blue : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _tindakLaporan(dynamic idLaporan) async {
    const String baseUrl = 'https://womb-catnip-unweave.ngrok-free.dev/api';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/laporan/$idLaporan/tindak'),
      );
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        ref.invalidate(daftarLaporanProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Laporan berhasil ditangani.'),
              backgroundColor: primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuru = _role == 'guru';
    final laporanAsync = ref.watch(daftarLaporanProvider);

    final dynamic dataInstan = laporanAsync.value;
    List listMentah = [];
    if (dataInstan is Map) {
      listMentah = dataInstan['laporan'] as List? ?? [];
    } else if (dataInstan is List) {
      listMentah = dataInstan;
    } else if (dataInstan != null) {
      try {
        listMentah = dataInstan['laporan'] as List? ?? [];
      } catch (_) {
        try {
          listMentah = dataInstan.laporan as List? ?? [];
        } catch (_) {}
      }
    }

    final totalLaporan = listMentah.length;
    final areaRawan = listMentah
        .where(
          (l) =>
              (l['jumlah_jentik'] ?? 0) > 0 && l['status'] != 'Sudah Ditangani',
        )
        .length;
    final totalJentik = listMentah.fold<int>(
      0,
      (prev, l) => prev + (l['jumlah_jentik'] as int? ?? 0),
    );
    final ditangani = listMentah
        .where((l) => l['status'] == 'Sudah Ditangani')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(daftarLaporanProvider);
          await _fetchAnggotaLangsung();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 1. HEADER HIJAU MELENGKUNG 🔥
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 24,
                  right: 24,
                  bottom: 40,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $_namaUser 👋',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Org: $_kodeOrg',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleRoleRahasia,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGuru ? Icons.school : Icons.person_search,
                                  color: primaryGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isGuru ? 'GURU' : 'MURID',
                                  style: GoogleFonts.poppins(
                                    color: primaryGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🔥 2. KOTAK RINGKASAN MINI 🔥
              Transform.translate(
                offset: const Offset(0, -25),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStatCard(
                              'Laporan',
                              '$totalLaporan',
                              Icons.assignment,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniStatCard(
                              'Rawan',
                              '$areaRawan',
                              Icons.warning_amber_rounded,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStatCard(
                              'Jentik',
                              '$totalJentik',
                              Icons.bug_report,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniStatCard(
                              'Ditangani',
                              '$ditangani',
                              Icons.check_circle,
                              primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 🔥 3. DAFTAR ANGGOTA (DENGAN FOTO PROFIL ASLI) 🔥
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => setState(
                        () => _isAnggotaExpanded = !_isAnggotaExpanded,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    color: primaryGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Anggota Tim',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_anggotaList.length} Orang',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isAnggotaExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Container(
                        height: _isAnggotaExpanded ? null : 0,
                        padding: const EdgeInsets.only(top: 10),
                        child: _isLoadingAnggota
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _anggotaList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'Belum ada data anggota.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _anggotaList.length,
                                itemBuilder: (context, index) {
                                  final user = _anggotaList[index];
                                  final bool isUserGuru =
                                      user['role'] == 'guru';

                                  // Ambil URL Foto Profil
                                  final String? rawFoto = user['foto_profil'];
                                  final String fotoUrl =
                                      (rawFoto != null && rawFoto.isNotEmpty)
                                      ? 'https://womb-catnip-unweave.ngrok-free.dev$rawFoto'
                                      : '';

                                  return _buildAnggotaTile(
                                    nama: user['nama_lengkap'] ?? 'Tanpa Nama',
                                    email: user['email'] ?? '',
                                    isGuru: isUserGuru,
                                    fotoUrl: fotoUrl, // 🔥 Kirim ke widget
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              const Divider(thickness: 4, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 15),

              // 🔥 4. LAPORAN TERBARU (DENGAN ALAMAT & FOTO ASLI) 🔥
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Terbaru',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    laporanAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          'Gagal memuat: $err',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ),
                      data: (_) {
                        if (listMentah.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                'Belum ada laporan di organisasimu.',
                                style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: listMentah.map<Widget>((laporan) {
                            return _buildReportCard(
                              lokasi: laporan['nama_lokasi'] ?? 'Tanpa Nama',
                              alamat:
                                  laporan['alamat'] ??
                                  'Alamat belum direkam', // 🔥 Ambil alamat
                              waktu: 'Baru saja',
                              jentik: laporan['jumlah_jentik'] ?? 0,
                              status: laporan['status'] ?? 'Belum Ditangani',
                              isCardGuru: isGuru,
                              dataLengkap: laporan,
                              rawFoto:
                                  laporan['foto_bukti'], // 🔥 Ambil path foto
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 WIDGET ANGGOTA TILE DENGAN FOTO PROFIL 🔥
  Widget _buildAnggotaTile({
    required String nama,
    required String email,
    required bool isGuru,
    required String fotoUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isGuru
                ? primaryGreen.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            radius: 20,
            backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
            child: fotoUrl.isEmpty
                ? Icon(
                    isGuru ? Icons.school : Icons.person,
                    color: isGuru ? primaryGreen : Colors.blue,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGuru ? primaryGreen : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isGuru ? 'GURU' : 'MURID',
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isGuru ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 WIDGET KARTU LAPORAN DENGAN FOTO ASLI & ALAMAT 🔥
  Widget _buildReportCard({
    required String lokasi,
    required String alamat,
    required String waktu,
    required int jentik,
    required String status,
    required bool isCardGuru,
    required dynamic dataLengkap,
    required String? rawFoto,
  }) {
    final isBahaya = jentik > 0 && status != 'Sudah Ditangani';
    final String imageUrl = (rawFoto != null && rawFoto.isNotEmpty)
        ? 'https://womb-catnip-unweave.ngrok-free.dev$rawFoto'
        : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLaporanScreen(laporan: dataLengkap),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isBahaya ? Colors.red.shade100 : Colors.green.shade100,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Menampilkan Foto Jika Ada
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _buildFallbackIcon(isBahaya),
                    )
                  : _buildFallbackIcon(isBahaya),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lokasi,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Teks Alamat Baru
                  const SizedBox(height: 2),
                  Text(
                    alamat,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$jentik Jentik ditemukan',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCardGuru && isBahaya)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  minimumSize: const Size(60, 30),
                ),
                onPressed: () {
                  final idLaporan = dataLengkap['id'];
                  if (idLaporan != null) _tindakLaporan(idLaporan);
                },
                child: Text(
                  'Tindak!',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBahaya
                      ? Colors.orange.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isBahaya
                        ? Colors.orange.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(bool isBahaya) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: isBahaya ? Colors.red.shade50 : Colors.green.shade50,
      ),
      child: Icon(
        isBahaya ? Icons.bug_report : Icons.check_circle_outline,
        color: isBahaya ? Colors.red : Colors.green,
        size: 24,
      ),
    );
  }
}
