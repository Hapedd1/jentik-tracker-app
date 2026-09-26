import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Paket peta bawaan OpenStreetMap
import 'package:latlong2/latlong.dart'; // Paket pengelola angka koordinat
import 'package:google_fonts/google_fonts.dart';

class LihatPetaScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String namaLokasi;

  const LihatPetaScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.namaLokasi,
  });

  @override
  Widget build(BuildContext context) {
    // Gabungkan latitude & longitude menjadi objek koordinat LatLng khusus peta
    final LatLng titikJentik = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lokasi Temuan Jentik',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🔥 KOMPONEN UTAMA WIDGET PETA DIGITAL 🔥
          FlutterMap(
            options: MapOptions(
              initialCenter:
                  titikJentik, // Membuka peta langsung fokus ke koordinat jentik
              initialZoom: 16.0, // Tingkat kedekatan/zoom peta
            ),
            children: [
              // 1. Mengunduh gambar peta dari OpenStreetMap server gratis resmi
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jentik_tracker.app',
              ),
              // 2. Menanamkan PIN Penanda Merah di atas peta
              MarkerLayer(
                markers: [
                  Marker(
                    point: titikJentik,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 45,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // --- KARTU INFORMASI MELAYANG DI BAWAH PETA ---
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bug_report, color: Colors.red),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            namaLokasi,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
