import 'dart:io';
import 'package:early_warning_system/controller/ControllerDrive.dart';
import 'package:early_warning_system/model/ModelDrive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwtUtils.dart';

class Viewdrive extends StatefulWidget {
  @override
  _ViewdriveState createState() => _ViewdriveState();
}

class _ViewdriveState extends State<Viewdrive> {
  final Controllerdrive controller = Controllerdrive();
  final TextEditingController triggerOnController = TextEditingController();
  final TextEditingController triggerOffController = TextEditingController();
  late SharedPreferences prefs;

  bool isSaving = false;
  bool isUploading = false;
  bool isLoading = true;
  File? tempUploadedFile;
  String? tempFileName;

  int? initialTriggerOn;
  int? initialTriggerOff;
  String? audioUrl; // Tambahkan ini
  String? audioName;

  bool get hasUnsavedChanges {
    final currentOn = int.tryParse(triggerOnController.text);
    final currentOff = int.tryParse(triggerOffController.text);
    return currentOn != initialTriggerOn ||
        currentOff != initialTriggerOff ||
        tempUploadedFile != null; // Cek perubahan file
  }

  final gradientColors = [
    Color(0xFF665C3C),
    Color(0xFF1E1E1E),
    Color(0xFF1E1E1E),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAndCheckAuth();
  }

  Future<void> _initializeAndCheckAuth() async {
    prefs = await SharedPreferences.getInstance(); // Inisialisasi prefs di sini
    await _checkAuth(); // Panggil _checkAuth setelah prefs diinisialisasi
    if (mounted &&
        (prefs.getString('token') != null &&
            !isTokenExpired(prefs.getString('token')!))) {
      // Hanya fetchAll jika token valid dan widget masih mounted
      fetchAll();
    }
  }

  Future<void> _checkAuth() async {
    final token = prefs.getString('token');

    if (token == null || token.isEmpty || isTokenExpired(token)) {
      await prefs.remove('token'); // Hapus token yang tidak valid/expired
      if (mounted) {
        // Pastikan widget masih dalam tree
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      print("Token is valid.");
    }
  }

  Future<void> fetchAll() async {
    setState(() {
      isLoading = true;
    });
    try {
      await fetchTriggerValues();
    } catch (e) {
      showSnackBar('Gagal memuat data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickTempFile() async {
    setState(() {
      isUploading = true;
    });
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.first.path != null) {
        final file = File(result.files.first.path!);
        if (!file.path.toLowerCase().endsWith('.mp3')) {
          showSnackBar('Hanya file MP3 yang diperbolehkan');
          return;
        }
        setState(() {
          tempUploadedFile = file;
          tempFileName = result.files.first.name;
        });
      }
    } catch (e) {
      showSnackBar('Gagal memilih file: $e');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> saveChanges() async {
    setState(() {
      isSaving = true;
      // isUploading akan di-handle secara spesifik di sekitar pemanggilan upload
    });

    final token = prefs.getString('token');
    if (token == null || token.isEmpty || isTokenExpired(token)) {
      showSnackBar('Sesi Anda telah berakhir. Silakan login kembali.');
      await prefs.remove('token');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return; // Hentikan proses save
    }

    // Inisialisasi dengan nilai yang ada di state, akan di-override jika ada file baru
    String? finalAudioUrl = audioUrl;
    String? finalAudioName = audioName;

    try {
      // Langkah 1: Unggah file baru jika ada, dan dapatkan URL serta nama baru dari server
      if (tempUploadedFile != null) {
        setState(() {
          isUploading = true; // Tampilkan indikator uploading
        });

        // Panggil metode yang sudah dimodifikasi dan dapatkan hasilnya
        final Map<String, String?> uploadResult =
            await controller.uploadFileToLocalApi(tempUploadedFile!);

        setState(() {
          isUploading = false; // Sembunyikan indikator uploading
        });

        // Ambil fileUrl dan fileName dari hasil upload
        finalAudioUrl = uploadResult['fileUrl'];
        finalAudioName = uploadResult['fileName'];

        // Validasi apakah URL dan nama berhasil didapatkan
        if (finalAudioUrl == null || finalAudioName == null) {
          // Anda bisa juga menampilkan pesan error yang lebih spesifik dari uploadResult jika ada
          throw Exception(
              "Gagal mendapatkan URL atau nama file baru setelah unggah.");
        }

        // Bersihkan file temporer setelah berhasil diolah
        tempUploadedFile = null;
        // tempFileName tidak perlu di-update dari uploadResult['fileName'] karena
        // finalAudioName sudah menampungnya dan akan digunakan untuk update state.
        // Anda bisa mengosongkan tempFileName atau mengaturnya ke finalAudioName
        // agar UI konsisten setelah save.
      }

      // Langkah 2: Buat model dengan data terkini (termasuk URL dan nama audio yang sudah benar)
      final updatedTrigger = ModelDrive(
        triggerOn: int.parse(triggerOnController.text),
        triggerOff: int.parse(triggerOffController.text),
        audioUrl: finalAudioUrl, // Gunakan URL yang mungkin baru
        audioName: finalAudioName, // Gunakan nama yang mungkin baru
      );

      // Langkah 3: Kirim pembaruan (termasuk trigger_on, trigger_off, dan info audio yang benar) ke API
      await controller.updateTriggerValues(updatedTrigger);

      // Langkah 4: Update state lokal setelah semua operasi berhasil
      // Ini penting agar UI mencerminkan data yang tersimpan di server
      setState(() {
        initialTriggerOn = updatedTrigger.triggerOn;
        initialTriggerOff = updatedTrigger.triggerOff;
        audioUrl = finalAudioUrl; // Update state dengan URL baru/yang sesuai
        audioName = finalAudioName; // Update state dengan nama baru/yang sesuai

        // Update tempFileName agar konsisten dengan audioName yang tersimpan,
        // ini akan memperbarui tampilan nama file di UI jika Anda menampilkannya.
        if (tempUploadedFile == null) {
          // Hanya jika tidak ada file baru yang dipilih
          tempFileName = finalAudioName;
        }
        // Atau jika Anda ingin menghapus tampilan file setelah save:
        // tempFileName = null;
      });

      showSnackBar('Perubahan berhasil disimpan');
    } catch (e) {
      print(e); // Cetak error ke konsol untuk debugging
      showSnackBar('Gagal menyimpan perubahan: ${e.toString()}');
    } finally {
      setState(() {
        isSaving = false;
        // Pastikan isUploading juga false di blok finally
        if (isUploading) {
          isUploading = false;
        }
      });
    }
  }

// ...
// Dalam fetchAll atau fetchTriggerValues, pastikan tempFileName diinisialisasi dengan benar:
  Future<void> fetchTriggerValues() async {
    try {
      final trigger = await controller.getTriggerValues();
      triggerOnController.text = trigger.triggerOn.toString();
      triggerOffController.text = trigger.triggerOff.toString();
      initialTriggerOn = trigger.triggerOn;
      initialTriggerOff = trigger.triggerOff;
      audioUrl = trigger.audioUrl;
      audioName = trigger.audioName;
      setState(() {
        // Jika tidak ada file yang sedang dipilih untuk diunggah,
        // tampilkan nama file dari server.
        if (tempUploadedFile == null &&
            audioName != null &&
            audioName!.isNotEmpty) {
          tempFileName = audioName;
        }
        // Jika tempUploadedFile ada, tempFileName sudah diisi saat pickTempFile.
      });
    } catch (e) {
      showSnackBar('Gagal mengambil trigger: $e');
    }
  }

  Future<bool> confirmExitOrSave() async {
    if (!hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Perubahan belum disimpan'),
        content: Text('Apakah Anda ingin menyimpan perubahan sebelum keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya'),
          ),
        ],
      ),
    );
    if (result == true) {
      await saveChanges();
    }
    return result != null;
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    triggerOnController.dispose();
    triggerOffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await confirmExitOrSave(),
      child: Stack(
        // Wrap with Stack to show loading overlay
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
                stops: [0.2, 0.6, 1.0],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                toolbarHeight: 140,
                title: Padding(
                  padding: EdgeInsets.only(top: 10, left: 10),
                  child: Text(
                    'Dashboard \nAdmin',
                    style: TextStyle(fontSize: 48, color: Colors.white),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () async {
                      final confirmed = await confirmExitOrSave();
                      await prefs.clear();
                      if (confirmed)
                        Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 7),
                          child: SvgPicture.asset(
                            'assets/icons/logout.svg',
                            height: 35,
                            width: 35,
                            color: Color(0xFFE41D1D),
                          ),
                        ),
                        Text(
                          'EXIT',
                          style:
                              TextStyle(fontSize: 18, color: Color(0xFFE41D1D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 90, 16, 0),
                  child: Column(
                    children: [
                      buildOutlinedTextField(
                        label: 'Rsam Trigger On',
                        controller: triggerOnController,
                      ),
                      SizedBox(height: 40),
                      buildOutlinedTextField(
                        label: 'Rsam Trigger Off',
                        controller: triggerOffController,
                      ),
                      SizedBox(height: 40),
                      buildButton(
                          text: 'Upload Alarm',
                          onPressed: pickTempFile,
                          isLoading: isUploading,
                          font_size: 20),
                      if (tempFileName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.music_note, color: Colors.white70),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tempFileName!,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        height: 150,
                      ),
                      buildButton(
                          text: 'SAVE',
                          onPressed: () async {
                            final confirmed = await confirmExitOrSave();
                            if (confirmed)
                              showSnackBar('Data berhasil disimpan');
                          },
                          isLoading: isSaving,
                          font_size: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading || isSaving || isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFF2C94C)),
                    ),
                    SizedBox(height: 20),
                    Text(
                      isLoading
                          ? 'Memuat data...'
                          : isUploading
                              ? 'Mengunggah file...'
                              : 'Menyimpan perubahan...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildOutlinedTextField({
    required String label,
    required TextEditingController controller,
    bool? isDisabled,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: Colors.white),
      enabled: !(isDisabled ?? false),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.black,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF2C94C)),
        ),
      ),
    );
  }

  Widget buildButton({
    required String text,
    required VoidCallback onPressed,
    required double font_size,
    bool? isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isLoading ?? false) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF2C94C),
          padding: EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        child: (isLoading ?? false)
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                text,
                style: TextStyle(color: Colors.black, fontSize: font_size),
              ),
      ),
    );
  }
}
