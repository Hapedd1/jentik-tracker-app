import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // 🔥 Untuk membaca file Logo
import 'package:intl/intl.dart'; // 🔥 Untuk format tanggal cetak

// SENJATA UNTUK GENERATE & PRINT PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../providers/data_laporan_provider.dart';
import 'package:jentik_nyamuk/features/laporan/presentation/pages/detail_laporan_screen.dart';

class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  final Color primaryGreen = const Color(0xFF1D8B41);
  final TextEditingController _searchController = TextEditingController();

  String _activeFilter = 'Semua';
  String _searchQuery = '';

  // Variabel untuk menampung data user pencetak
  String _role = 'murid';
  String _namaUser = 'Anonim';
  String _kodeOrg = '-';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  // 🔥 FUNGSI MEMERIKSA DATA PENGCETAK 🔥
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'murid';
      _namaUser = prefs.getString('nama_lengkap') ?? 'Tanpa Nama';
      _kodeOrg = prefs.getString('kodeOrganisasi') ?? '-';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔥 FUNGSI UTAMA GENERATOR CETAK PDF KOP SURAT RESMI 🔥
  Future<void> _cetakLaporanPDF(List<dynamic> dataLaporan) async {
    final ByteData bytes = await rootBundle.load('assets/logo.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final waktuCetak = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // HEADER KOP SURAT
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logoImage, width: 60, height: 60),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'LAPORAN PEMANTAUAN JENTIK NYAMUK',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Aplikasi Jentik Tracker - Cegah Demam Berdarah Dengue',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 3, color: PdfColors.black),
          pw.SizedBox(height: 15),

          // INFO PENGCETAK
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Dicetak Oleh     : $_namaUser',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Organisasi       : $_kodeOrg',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Waktu Cetak    : $waktuCetak',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
          pw.SizedBox(height: 25),

          // TABEL DATA
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Lokasi Pengecekan',
              'Alamat',
              'Kondisi Air',
              'Jentik',
              'Status',
            ],
            data: List<List<String>>.generate(dataLaporan.length, (index) {
              final item = dataLaporan[index];
              return [
                '${index + 1}',
                item['nama_lokasi'] ?? '-',
                item['alamat'] ?? '-',
                item['kondisi_air'] ?? '-',
                '${item['jumlah_jentik'] ?? 0}',
                item['status'] ?? 'Belum Ditangani',
              ];
            }),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(2),
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final laporanListAsync = ref.watch(dataLaporanProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Data Laporan',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      floatingActionButton: _role == 'guru'
          ? laporanListAsync.maybeWhen(
              data: (laporanList) => FloatingActionButton.extended(
                backgroundColor: primaryGreen,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: Text(
                  'Cetak PDF',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  final filteredList = laporanList.where((laporan) {
                    final lokasi = (laporan['nama_lokasi'] ?? '').toLowerCase();
                    final jentik = laporan['jumlah_jentik'] ?? 0;
                    final statusRaw = laporan['status'] ?? 'Belum Ditangani';

                    final matchSearch = lokasi.contains(_searchQuery);
                    bool matchFilter = true;

                    if (_activeFilter == 'Rawan') {
                      matchFilter =
                          jentik > 0 && statusRaw != 'Sudah Ditangani';
                    } else if (_activeFilter == 'Ditangani') {
                      matchFilter = statusRaw == 'Sudah Ditangani';
                    } else if (_activeFilter == 'Belum Ditangani') {
                      matchFilter = statusRaw != 'Sudah Ditangani';
                    }
                    return matchSearch && matchFilter;
                  }).toList();

                  _cetakLaporanPDF(filteredList);
                },
              ),
              orElse: () => null,
            )
          : null,

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Cari lokasi atau laporan...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.black38,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black45,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: primaryGreen, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: primaryGreen),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.filter_alt_outlined, color: primaryGreen),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              children: [
                _buildFilterChip('Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Rawan'),
                const SizedBox(width: 8),
                _buildFilterChip('Ditangani'),
                const SizedBox(width: 8),
                _buildFilterChip('Belum Ditangani'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔥 BAGIAN YANG DIPERBARUI: REFRESH INDICATOR 🔥
          Expanded(
            child: RefreshIndicator(
              color: primaryGreen,
              onRefresh: () async {
                // Tarik ulang data dari server menggunakan Riverpod
                ref.invalidate(dataLaporanProvider);
                // Jeda agar animasi loading berputar sebentar
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: laporanListAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1D8B41)),
                ),
                error: (error, stack) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(child: Text('Gagal memuat data: $error')),
                  ],
                ),
                data: (laporanList) {
                  final filteredList = laporanList.where((laporan) {
                    final lokasi = (laporan['nama_lokasi'] ?? '').toLowerCase();
                    final jentik = laporan['jumlah_jentik'] ?? 0;
                    final statusRaw = laporan['status'] ?? 'Belum Ditangani';

                    final matchSearch = lokasi.contains(_searchQuery);
                    bool matchFilter = true;

                    if (_activeFilter == 'Rawan') {
                      matchFilter =
                          jentik > 0 && statusRaw != 'Sudah Ditangani';
                    } else if (_activeFilter == 'Ditangani') {
                      matchFilter = statusRaw == 'Sudah Ditangani';
                    } else if (_activeFilter == 'Belum Ditangani') {
                      matchFilter = statusRaw != 'Sudah Ditangani';
                    }

                    return matchSearch && matchFilter;
                  }).toList();

                  if (filteredList.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    // 🔥 WAJIB ADA AGAR BISA DITARIK MESKIPUN DATANYA SEDIKIT 🔥
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final laporan = filteredList[index];

                      final String? rawFotoUrl = laporan['foto_bukti'];
                      final String urlFotoLengkap =
                          (rawFotoUrl != null && rawFotoUrl.isNotEmpty)
                          ? 'https://womb-catnip-unweave.ngrok-free.dev$rawFotoUrl'
                          : '';

                      final int jmlJentik = laporan['jumlah_jentik'] ?? 0;
                      final String statusAsli =
                          laporan['status'] ?? 'Belum Ditangani';
                      final bool isRawan =
                          jmlJentik > 0 && statusAsli != 'Sudah Ditangani';

                      String badgeText = statusAsli;
                      Color badgeColor = Colors.orange;

                      if (isRawan) {
                        badgeText = 'Rawan';
                        badgeColor = Colors.red;
                      } else if (statusAsli == 'Sudah Ditangani') {
                        badgeText = 'Ditangani';
                        badgeColor = primaryGreen;
                      }

                      return _buildLaporanCard(
                        context: context,
                        dataLengkap: laporan,
                        lokasi: laporan['nama_lokasi'] ?? 'Tanpa Nama',
                        alamat: laporan['alamat'] ?? 'Alamat tidak terekam',
                        tanggal: laporan['created_at'] != null
                            ? _formatTanggal(laporan['created_at'])
                            : '-',
                        waktu: 'Terbaru',
                        fotoUrl: urlFotoLengkap,
                        badgeText: badgeText,
                        badgeColor: badgeColor,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLaporanCard({
    required BuildContext context,
    required dynamic dataLengkap,
    required String lokasi,
    required String alamat,
    required String tanggal,
    required String waktu,
    required String fotoUrl,
    required String badgeText,
    required Color badgeColor,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLaporanScreen(laporan: dataLengkap),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: fotoUrl.isNotEmpty
                  ? Image.network(
                      fotoUrl,
                      width: 75,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackIcon(),
                    )
                  : _buildFallbackIcon(),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lokasi,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alamat,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$tanggal • $waktu',
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 75,
      height: 75,
      color: Colors.grey.shade100,
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 30,
      ),
    );
  }

  // 🔥 BAGIAN YANG DIPERBARUI: DIBUNGKUS LISTVIEW AGAR BISA DITARIK SAAT KOSONG 🔥
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Tidak ada data yang sesuai',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatTanggal(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      final List<String> bulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return "${date.day} ${bulan[date.month - 1]} ${date.year}";
    } catch (e) {
      return rawDate;
    }
  }
}
