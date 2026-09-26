import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

// 🔥 UBAH IMPORT INI: Kita lempar user ke PilihPeranScreen saat Logout
import 'package:jentik_nyamuk/features/auth/presentation/pages/pilih_peran_screen.dart';
import 'package:jentik_nyamuk/features/profil/providers/profile_provider.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  final primaryGreen = const Color(0xFF1D8B41);
  final bgLight = const Color(0xFFF8FAF9);

  String _nama = 'Memuat...';
  String _email = 'Memuat...';
  String _noHp = 'Memuat...';
  String _fotoProfil = '';

  @override
  void initState() {
    super.initState();
    _loadDataUser();
  }

  Future<void> _loadDataUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nama = prefs.getString('nama_lengkap') ?? 'Relawan Jentik';
      _email = prefs.getString('email') ?? 'Belum ada email';
      _noHp = prefs.getString('no_hp') ?? '-';
      _fotoProfil = prefs.getString('foto_profil') ?? '';
    });
  }

  Future<void> _pilihDanUploadFoto() async {
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
                    imageQuality: 40,
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
                    imageQuality: 40,
                  );
                  if (context.mounted) Navigator.pop(context, file);
                },
              ),
            ],
          ),
        );
      },
    );

    if (image == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      const String baseUrlHost = 'https://womb-catnip-unweave.ngrok-free.dev';
      final bytes = await image.readAsBytes();
      final filename = image.name;
      final mimeType = image.mimeType ?? 'image/jpeg';

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrlHost/api/user/update-foto'),
      );
      request.fields['email'] = _email;
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String newFotoUrl = data['foto_url'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('foto_profil', newFotoUrl);
        setState(() => _fotoProfil = newFotoUrl);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diubah!'),
              backgroundColor: Color(0xFF1D8B41),
            ),
          );
      } else {
        throw Exception('Server merespons kode kesalahan');
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _tampilDialogGantiNama() async {
    final TextEditingController namaController = TextEditingController(
      text: _nama,
    );
    bool isSaving = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Ganti Nama',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: TextField(
                controller: namaController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan nama baru',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (namaController.text.trim().isEmpty) return;
                          setStateDialog(() => isSaving = true);
                          try {
                            const String baseUrl =
                                'https://womb-catnip-unweave.ngrok-free.dev/api';
                            final response = await http.put(
                              Uri.parse('$baseUrl/user/update-nama'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'email': _email,
                                'nama_lengkap': namaController.text.trim(),
                              }),
                            );
                            if (response.statusCode == 200) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'nama_lengkap',
                                namaController.text.trim(),
                              );
                              setState(
                                () => _nama = namaController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nama berhasil diubah!'),
                                    backgroundColor: Color(0xFF1D8B41),
                                  ),
                                );
                              }
                            } else {
                              throw Exception('Gagal mengubah nama');
                            }
                          } catch (e) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                          } finally {
                            if (context.mounted)
                              setStateDialog(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Simpan',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _tampilDialogGantiPassword() async {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Ganti Password',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPassController,
                    obscureText: obscureOld,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Password Lama',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureOld ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setStateDialog(() => obscureOld = !obscureOld),
                      ),
                      filled: true,
                      fillColor: bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Password Baru',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setStateDialog(() => obscureNew = !obscureNew),
                      ),
                      filled: true,
                      fillColor: bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (oldPassController.text.isEmpty ||
                              newPassController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Isi semua kolom!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setStateDialog(() => isSaving = true);
                          try {
                            const String baseUrl =
                                'https://womb-catnip-unweave.ngrok-free.dev/api';
                            final response = await http.put(
                              Uri.parse('$baseUrl/user/update-password'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'email': _email,
                                'password_lama': oldPassController.text,
                                'password_baru': newPassController.text,
                              }),
                            );
                            final data = jsonDecode(response.body);
                            if (response.statusCode == 200) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password berhasil diubah!'),
                                    backgroundColor: Color(0xFF1D8B41),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      data['error'] ??
                                          'Gagal mengubah password',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                            }
                          } catch (e) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error jaringan: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                          } finally {
                            if (context.mounted)
                              setStateDialog(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Simpan',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFFE8F5E9),
                          backgroundImage: _fotoProfil.isNotEmpty
                              ? NetworkImage(
                                  'https://womb-catnip-unweave.ngrok-free.dev$_fotoProfil',
                                )
                              : null,
                          child: _fotoProfil.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pilihDanUploadFoto,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2, right: 2),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _nama,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  profileAsync.when(
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    error: (err, stack) => const SizedBox(),
                    data: (data) {
                      final isGuru = data['role'] == 'guru';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Text(
                          isGuru ? '🎓 Ketua Organisasi' : '👤 Anggota Relawan',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isGuru
                                ? const Color(0xFF1976D2)
                                : primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        profileAsync.when(
                          loading: () => _buildInfoRow('Kode Org.', '...'),
                          error: (err, stack) =>
                              _buildInfoRow('Kode Org.', '-'),
                          data: (data) => _buildInfoRow(
                            'Kode Org.',
                            data['kodeOrganisasi'] ?? '-',
                          ),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('Email', _email),
                        const Divider(height: 24),
                        _buildInfoRow('No. HP', _noHp),
                        const Divider(height: 24),
                        _buildInfoRow('Bergabung', 'Terdaftar'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Pengaturan',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          Icons.person_outline,
                          'Ganti Nama',
                          onTap: _tampilDialogGantiNama,
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          Icons.lock_outline,
                          'Ganti Password',
                          onTap: _tampilDialogGantiPassword,
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          Icons.logout,
                          'Keluar',
                          isDestructive: true,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Keluar Akun?',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Apakah kamu yakin ingin keluar?',
                                  style: GoogleFonts.poppins(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Batal',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.clear();
                                      if (context.mounted) {
                                        // 🔥 UBAH NAVIGASI INI: Melompat ke PilihPeranScreen, bukan LoginScreen
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const PilihPeranScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Ya, Keluar',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: color,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap ?? () {},
    );
  }
}
