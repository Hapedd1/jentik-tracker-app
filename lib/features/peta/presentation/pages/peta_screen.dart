import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

// ⚠️ PASTIKAN 2 IMPORT JALUR INI BENAR SESUAI STRUKTUR FOLDERMU
import 'package:jentik_nyamuk/features/laporan/providers/laporan_provider.dart';
import 'package:jentik_nyamuk/features/laporan/presentation/pages/detail_laporan_screen.dart';

class PetaScreen extends ConsumerStatefulWidget {
  const PetaScreen({super.key});

  @override
  ConsumerState<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends ConsumerState<PetaScreen> {
  final primaryGreen = const Color(0xFF1D8B41);
  final MapController _mapController = MapController();

  // 🔥 1. TAMBAHKAN CONTROLLER & VARIABEL STATE UNTUK PENCARIAN 🔥
  final _searchController = TextEditingController();
  String _kataKunci = '';

  LatLng _currentCenter = const LatLng(-7.0012, 110.4607);
  LatLng? _myLocationDot;
  dynamic _selectedLaporan;

  @override
  void initState() {
    super.initState();
    _dapatkanLokasiHP();
  }

  // 🔥 2. WAJIB DISPOSE UNTUK MENCEGAH LEAK MEMORI HP 🔥
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _dapatkanLokasiHP() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _myLocationDot = LatLng(position.latitude, position.longitude);
          _currentCenter = _myLocationDot!;
        });
        _mapController.move(_currentCenter, 15.0);
      }
    } catch (e) {
      debugPrint("Gagal mendeteksi lokasi saat ini: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final laporanAsync = ref.watch(daftarLaporanProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // --- KONDISI DATA FROM BACKEND ---
          laporanAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D8B41)),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Gagal memuat peta: $err',
                style: GoogleFonts.poppins(),
              ),
            ),
            data: (dataLaporan) {
              final dynamic dataInstan = dataLaporan;
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

              // 🔥 3. LOGIKA FILTER SAKTI: Saring data berdasarkan apa yang kamu ketik 🔥
              final listLaporanValid = listMentah.where((item) {
                if (item == null ||
                    item['latitude'] == null ||
                    item['longitude'] == null) {
                  return false;
                }

                // Ambil teks nama lokasi, ubah ke huruf kecil semua agar pencarian tidak sensitif caps lock
                final String namaTempat = (item['nama_lokasi'] ?? '')
                    .toString()
                    .toLowerCase();
                final String catatanTempat = (item['catatan'] ?? '')
                    .toString()
                    .toLowerCase();
                final String cari = _kataKunci.toLowerCase();

                // COCOKKAN: Muncul jika nama lokasi atau catatan mengandung kata kunci pencarian
                return namaTempat.contains(cari) ||
                    catatanTempat.contains(cari);
              }).toList();

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: 15.0,
                  onTap: (tapPosition, point) {
                    setState(() => _selectedLaporan = null);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.jentik_tracker.app',
                  ),

                  // LAYER MARKER HASIL SARINGAN SEARCH
                  MarkerLayer(
                    markers: listLaporanValid.map((laporan) {
                      final double lat = double.parse(
                        laporan['latitude'].toString(),
                      );
                      final double lng = double.parse(
                        laporan['longitude'].toString(),
                      );
                      final int jumlahJentik = laporan['jumlah_jentik'] ?? 0;
                      final String status =
                          laporan['status'] ?? 'Belum Ditangani';

                      final isSelected =
                          _selectedLaporan?['id'] == laporan['id'];

                      final Color markerColor =
                          (jumlahJentik > 0 && status != 'Sudah Ditangani')
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1D8B41);

                      return Marker(
                        point: LatLng(lat, lng),
                        width: isSelected ? 55 : 42,
                        height: isSelected ? 55 : 42,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedLaporan = laporan);
                          },
                          child: Icon(
                            Icons.location_on,
                            color: markerColor,
                            size: isSelected ? 55 : 42,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_myLocationDot != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _myLocationDot!,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),

          // --- HEADER PENCARIAN (OTAKNYA SUDAH AKTIF) ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController, // 🔥 PASANG CONTROLLER
                        onChanged: (value) {
                          // 🔥 UPDATE KATA KUNCI SECARA REAL-TIME SAAT DIKETIK 🔥
                          setState(() {
                            _kataKunci = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari lokasi temuan...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.black38,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.black38,
                          ),
                          // Tambahkan tombol silang (X) untuk menghapus ketikan dengan cepat
                          suffixIcon: _kataKunci.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.black45,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _kataKunci = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(Icons.filter_alt_outlined, color: primaryGreen),
                  ),
                ],
              ),
            ),
          ),

          // --- TOMBOL TERBANG LOKASI SAYA ---
          Positioned(
            right: 20,
            bottom: _selectedLaporan != null ? 240 : 100,
            child: FloatingActionButton(
              heroTag: 'btnGlobalMapLocation',
              mini: true,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black87),
              onPressed: () {
                if (_myLocationDot != null) {
                  _mapController.move(_myLocationDot!, 16.0);
                } else {
                  _dapatkanLokasiHP();
                }
              },
            ),
          ),

          // --- KARTU POP-UP DI BAWAH ---
          if (_selectedLaporan != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedLaporan['nama_lokasi'] ?? 'Tanpa Nama',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kondisi air: ${_selectedLaporan['kondisi_air'] ?? '-'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (_selectedLaporan['status'] == 'Sudah Ditangani'
                                        ? Colors.green
                                        : Colors.orange)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedLaporan['status'] ?? 'Belum Ditangani',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color:
                                  _selectedLaporan['status'] ==
                                      'Sudah Ditangani'
                                  ? Colors.green
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Text(
                          'Jentik: ',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${_selectedLaporan['jumlah_jentik'] ?? 0} ekor',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: (_selectedLaporan['jumlah_jentik'] ?? 0) > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _selectedLaporan['created_at'] != null
                              ? DateFormat('dd MMM yyyy').format(
                                  DateTime.parse(
                                    _selectedLaporan['created_at'],
                                  ).toLocal(),
                                )
                              : '-',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailLaporanScreen(
                                laporan: _selectedLaporan,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Lihat Detail Laporan',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
