import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';

// 🔥 SENJATA BARU: REVERSE GEOCODING (Penerjemah Koordinat ke Alamat) 🔥
import 'package:geocoding/geocoding.dart';

// ⚠️ PASTIKAN JALUR INI SESUAI UNTUK MEMANGGIL PROVIDER DASHBOARD
import 'package:jentik_nyamuk/features/laporan/providers/laporan_provider.dart';

class TambahLaporanScreen extends ConsumerStatefulWidget {
  const TambahLaporanScreen({super.key});

  @override
  ConsumerState<TambahLaporanScreen> createState() =>
      _TambahLaporanScreenState();
}

class _TambahLaporanScreenState extends ConsumerState<TambahLaporanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lokasiController =
      TextEditingController(); // Untuk Nama Tempat (Misal: Bak Mandi)

  // 🔥 CONTROLLER BARU UNTUK ALAMAT JALAN 🔥
  final _alamatController = TextEditingController();

  final _jentikController = TextEditingController();
  final _catatanController = TextEditingController();

  String _kondisiAir = 'Jernih';
  bool _isLoading = false;
  final primaryGreen = const Color(0xFF1D8B41);

  // Variabel penampung Foto
  Uint8List? _fotoBytes;
  String? _fotoNama;
  String? _fotoMime;

  // Variabel penampung GPS
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  String _locationStatusText = 'Mencari lokasi GPS...';

  @override
  void initState() {
    super.initState();
    _ambilLokasiGPS();
  }

  // 🔥 FUNGSI SAKTI 2.0: MENANGKAP KOORDINAT & MENERJEMAHKAN KE NAMA JALAN 🔥
  Future<void> _ambilLokasiGPS() async {
    setState(() {
      _isGettingLocation = true;
      _locationStatusText = 'Meminta izin akses GPS...';
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isGettingLocation = false;
          _locationStatusText = 'GPS di HP kamu mati. Silakan aktifkan!';
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isGettingLocation = false;
            _locationStatusText = 'Izin GPS ditolak oleh pengguna.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isGettingLocation = false;
          _locationStatusText = 'Izin GPS ditolak permanen di pengaturan HP.';
        });
        return;
      }

      setState(() => _locationStatusText = 'Mengunci koordinat bumi...');

      // Mengunci Posisi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      setState(() => _locationStatusText = 'Menerjemahkan ke nama jalan...');

      // 🔥 PROSES MENDETEKSI NAMA JALAN (REVERSE GEOCODING) 🔥
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _latitude!,
          _longitude!,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Menyusun format alamat (Contoh: Jl. Sudirman, Semarang)
          String jalan = place.street ?? '';
          String area = place.subLocality ?? place.locality ?? '';

          // Memasukkan hasil deteksi ke kolom input agar bisa diedit user
          _alamatController.text = '$jalan, $area'
              .replaceAll(RegExp(r'^,\s*'), '')
              .trim();
        }
      } catch (e) {
        debugPrint("Gagal menerjemahkan alamat: $e");
        // Jika gagal translate, biarkan user mengetik manual
      }

      setState(() {
        _isGettingLocation = false;
        _locationStatusText = 'Lokasi berhasil dikunci! 📍';
      });
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
        _locationStatusText = 'Gagal mengambil lokasi: $e';
      });
    }
  }

  Future<void> _pilihFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1D8B41)),
                title: Text('Ambil dari Kamera', style: GoogleFonts.poppins()),
                onTap: () async {
                  final XFile? file = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 50,
                  );
                  if (context.mounted) Navigator.pop(context, file);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF1D8B41),
                ),
                title: Text('Ambil dari Galeri', style: GoogleFonts.poppins()),
                onTap: () async {
                  final XFile? file = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 50,
                  );
                  if (context.mounted) Navigator.pop(context, file);
                },
              ),
            ],
          ),
        );
      },
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _fotoBytes = bytes;
        _fotoNama = image.name;
        _fotoMime = image.mimeType ?? 'image/jpeg';
      });
    }
  }

  // 🔥 FUNGSI UTAMA: MENGIRIM DATA + ALAMAT KE NODE.JS 🔥
  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tolong lampirkan foto bukti!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final kodeOrg = prefs.getString('kodeOrganisasi') ?? '';
      const String baseUrlHost = 'https://womb-catnip-unweave.ngrok-free.dev';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrlHost/api/laporan'),
      );

      // Masukkan data Teks Umum
      request.fields['kode_organisasi'] = kodeOrg;
      request.fields['nama_lokasi'] = _lokasiController.text;

      // 🔥 MENGIRIMKAN ALAMAT LENGKAP KE SERVER 🔥
      request.fields['alamat'] = _alamatController.text.trim().isEmpty
          ? 'Tidak ada alamat tercatat'
          : _alamatController.text.trim();

      request.fields['jumlah_jentik'] = _jentikController.text;
      request.fields['kondisi_air'] = _kondisiAir;
      request.fields['catatan'] = _catatanController.text;
      request.fields['status'] = 'Belum Ditangani';

      request.fields['latitude'] = _latitude != null
          ? _latitude.toString()
          : '';
      request.fields['longitude'] = _longitude != null
          ? _longitude.toString()
          : '';

      // Masukkan data File Foto
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          _fotoBytes!,
          filename: _fotoNama,
          contentType: MediaType.parse(_fotoMime!),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ref.invalidate(daftarLaporanProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mantap! Laporan & Lokasi berhasil disimpan.'),
              backgroundColor: Color(0xFF1D8B41),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Gagal menyimpan data ke server');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _lokasiController.dispose();
    _alamatController.dispose(); // Jangan lupa hapus dari memori
    _jentikController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buat Laporan',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UPLOAD FOTO
              _buildLabel('Foto Bukti Jentik'),
              GestureDetector(
                onTap: _pilihFoto,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                    image: _fotoBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_fotoBytes!),
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                  child: _fotoBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Ketuk untuk ambil foto',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // MONITOR STATUS GPS
              _buildLabel('Titik Koordinat Lokasi'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _latitude != null
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null ? Icons.location_on : Icons.gps_fixed,
                      color: _latitude != null ? primaryGreen : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationStatusText,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (_latitude != null && _longitude != null)
                            Text(
                              'Lat: ${_latitude!.toStringAsFixed(5)} | Lng: ${_longitude!.toStringAsFixed(5)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_isGettingLocation)
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          size: 20,
                          color: Colors.black54,
                        ),
                        onPressed: _ambilLokasiGPS,
                      )
                    else
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // NAMA TEMPAT KECIL
              _buildLabel('Nama Tempat Spesifik'),
              _buildTextField(
                controller: _lokasiController,
                hint: 'Contoh: Bak Mandi Kelas 10 / Drum Belakang',
                icon: Icons.push_pin_outlined,
              ),
              const SizedBox(height: 20),

              // 🔥 KOLOM ALAMAT JALAN (OTOMATIS TERISI & BISA DIEDIT) 🔥
              _buildLabel('Alamat Lengkap / Jalan'),
              _buildTextField(
                controller: _alamatController,
                hint: 'Silahkan Ketik Alamat...',
                icon: Icons.map_outlined,
                maxLines: 2, // Dibuat 2 baris karena alamat biasanya panjang
              ),
              const SizedBox(height: 20),

              // JUMLAH JENTIK
              _buildLabel('Jumlah Jentik Ditemukan'),
              _buildTextField(
                controller: _jentikController,
                hint: 'Isi dengan angka (Misal: 5)',
                icon: Icons.bug_report_outlined,
                isNumber: true,
              ),
              const SizedBox(height: 20),

              // KONDISI AIR
              _buildLabel('Kondisi Air'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _kondisiAir,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black54,
                    ),
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    items: ['Jernih', 'Keruh', 'Menggenang', 'Kering'].map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) =>
                        setState(() => _kondisiAir = newValue!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CATATAN
              _buildLabel('Catatan (Opsional)'),
              _buildTextField(
                controller: _catatanController,
                hint: 'Tambahkan keterangan bila perlu...',
                icon: Icons.notes,
                maxLines: 3,
                isRequired: false,
              ),
              const SizedBox(height: 40),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (_isLoading || _isGettingLocation)
                      ? null
                      : _submitLaporan,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isGettingLocation
                              ? 'Menyelaraskan GPS...'
                              : 'Kirim Laporan & Bukti',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: Colors.grey.shade500)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: const Color(0xFF1D8B41), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty))
          return 'Kolom ini wajib diisi';
        return null;
      },
    );
  }
}
