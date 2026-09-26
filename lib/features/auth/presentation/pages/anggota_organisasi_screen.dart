import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnggotaOrganisasiScreen extends StatefulWidget {
  const AnggotaOrganisasiScreen({super.key});

  @override
  State<AnggotaOrganisasiScreen> createState() =>
      _AnggotaOrganisasiScreenState();
}

class _AnggotaOrganisasiScreenState extends State<AnggotaOrganisasiScreen> {
  final primaryGreen = const Color(0xFF1D8B41);
  bool _isLoading = true;
  List _anggota = [];
  String _kodeOrg = '';

  @override
  void initState() {
    super.initState();
    _fetchAnggota();
  }

  Future<void> _fetchAnggota() async {
    final prefs = await SharedPreferences.getInstance();
    _kodeOrg = prefs.getString('kodeOrganisasi') ?? '';

    try {
      final response = await http.get(
        Uri.parse(
          'https://womb-catnip-unweave.ngrok-free.dev/api/organizations/$_kodeOrg/members',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _anggota = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
          'Anggota Organisasi',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kode Organisasi',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _kodeOrg,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Daftar Anggota (${_anggota.length})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _anggota.length,
                    itemBuilder: (context, index) {
                      final user = _anggota[index];
                      final bool isGuru = user['role'] == 'guru';

                      return Card(
                        // 🔥 PERBAIKAN: Menggunakan EdgeInsets.only(bottom: 12)
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isGuru
                                ? primaryGreen.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            child: Icon(
                              isGuru ? Icons.school : Icons.person,
                              color: isGuru ? primaryGreen : Colors.blue,
                            ),
                          ),
                          title: Text(
                            user['nama_lengkap'] ?? 'Tanpa Nama',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            user['email'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isGuru
                                  ? primaryGreen
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isGuru ? 'GURU' : 'MURID',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isGuru ? Colors.white : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
