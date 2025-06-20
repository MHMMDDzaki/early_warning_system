import 'dart:io';
import 'package:early_warning_system/controller/ControllerDrive.dart';
import 'package:early_warning_system/model/ModelDrive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwtUtils.dart';

class Viewdrive extends StatefulWidget {
  const Viewdrive({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
    const Color(0xFF665C3C),
    const Color(0xFF1E1E1E),
    const Color(0xFF1E1E1E),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAndCheckAuth();
  }

  Future<void> _showAlertDialog(
      BuildContext context, String title, String message,
      {bool isSuccess = false, VoidCallback? onSuccessDismiss}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12.0), // Atur radius sesuai keinginan
            side: const BorderSide(color: Colors.yellow, width: 2.0),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
                if (isSuccess && onSuccessDismiss != null) {
                  onSuccessDismiss(); // Call additional action if provided
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeAndCheckAuth() async {
    prefs = await SharedPreferences.getInstance();
    await _checkAuth();
    if (!mounted) return; // Panggil _checkAuth setelah prefs diinisialisasi
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
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Future<void> fetchAll() async {
    setState(() {
      isLoading = true;
    });
    try {
      await fetchTriggerValues();
    } catch (e) {
      if (!mounted) return;
      await _showAlertDialog(context, 'Error',
          'Gagal memuat data: ${e.toString().replaceFirst("Exception: ", "")}');
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
          if (!mounted) return;
          await _showAlertDialog(context, 'File Tidak Valid',
              'Hanya file MP3 yang diperbolehkan.');
          return;
        }
        setState(() {
          tempUploadedFile = file;
          tempFileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check BEFORE using context
      await _showAlertDialog(context, 'Error Memilih File',
          'Gagal memilih file: ${e.toString().replaceFirst("Exception: ", "")}');
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> saveChanges() async {
    setState(() {
      isSaving = true;
      // isUploading akan di-handle secara spesifik di sekitar pemanggilan upload
    });

    final token = prefs.getString('token');
    if (token == null || token.isEmpty || isTokenExpired(token)) {
      if (mounted) {
        await _showAlertDialog(context, 'Sesi Berakhir',
            'Sesi Anda telah berakhir. Silakan login kembali.',
            onSuccessDismiss: () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          }
        });
        await prefs.remove('token');
        if (!mounted) return;
        setState(() {
          isSaving = false;
          isUploading = false; // Reset isUploading as well for robustness
        });
        // if (mounted) {
        //
        //   Navigator.pushNamedAndRemoveUntil(
        //       context, '/login', (route) => false);
        // }
      }
      return;
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
      if (!mounted) return;
      await _showAlertDialog(context, 'Sukses', 'Perubahan berhasil disimpan.',
          isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      await _showAlertDialog(context, 'Gagal Menyimpan',
          'Gagal menyimpan perubahan: ${e.toString().replaceFirst("Exception: ", "")}');
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
      rethrow;
    }
  }

  Future<bool> confirmExitOrSave() async {
    if (!hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perubahan belum disimpan'),
        content:
            const Text('Apakah Anda ingin menyimpan perubahan sebelum keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    if (result == true) {
      await saveChanges();
    }
    return result != null;
  }

  Future<bool> _handlePop() async {
    if (!hasUnsavedChanges) return true; // Allow pop

    final result = await showDialog<bool>(
      context: context, // Context for dialog
      builder: (ctx) => AlertDialog(
        title: const Text('Perubahan belum disimpan'),
        content: const Text('Apakah Anda ingin menyimpan perubahan sebelum keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Don't save, allow pop
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), // Save, then pop
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (!mounted) return false; // Don't allow pop if widget unmounted during dialog

    if (result == true) {
      await saveChanges();
      // After saving, we typically want to allow the pop.
      // `saveChanges` might navigate if token expired.
      // If still mounted and save was successful, allow pop.
      return mounted; // Allow pop if still mounted (saveChanges didn't navigate away for other reasons)
    } else if (result == false) {
      return true; // User chose "Tidak", allow pop
    }
    return false; // Dialog dismissed (e.g. back button), don't allow pop by default
  }

  @override
  void dispose() {
    triggerOnController.dispose();
    triggerOffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return; // The pop already happened, nothing for us to do.
        }
        final bool shouldPop = await _handlePop(); // Your existing logic
        if (shouldPop && mounted) {
          Navigator.of(this.context).pop();
        }
      },
      child: Stack(
        // Wrap with Stack to show loading overlay
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
                stops: const [0.2, 0.6, 1.0],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                toolbarHeight: 140,
                title: const Padding(
                  padding: EdgeInsets.only(top: 10, left: 10),
                  child: Text(
                    'Dashboard \nAdmin',
                    style: TextStyle(fontSize: 48, color: Colors.white),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () async {
                      final bool canProceed = await _handlePop();
                      if (!mounted) return;

                      if (canProceed) {
                        await prefs.clear();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(this.context, '/login', (route) => false);
                      }
                    },
                    icon: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: SvgPicture.asset(
                            'assets/icons/logout.svg',
                            height: 35,
                            width: 35,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFE41D1D),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const Text(
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
                      const SizedBox(height: 40),
                      buildOutlinedTextField(
                        label: 'Rsam Trigger Off',
                        controller: triggerOffController,
                      ),
                      const SizedBox(height: 40),
                      buildButton(
                          text: 'Upload Alarm',
                          onPressed: pickTempFile,
                          isLoading: isUploading,
                          fontSize: 20),
                      if (tempFileName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.music_note,
                                  color: Colors.white70),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tempFileName!,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(
                        height: 150,
                      ),
                      buildButton(
                          text: 'SAVE',
                          onPressed: saveChanges,
                          isLoading: isSaving,
                          fontSize: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading || isSaving || isUploading)
            Container(
              color: Colors.black.withAlpha((255 * 0.7).round()),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFF2C94C)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isLoading
                          ? 'Memuat data...'
                          : isUploading
                              ? 'Mengunggah file...'
                              : 'Menyimpan perubahan...',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
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
      style: const TextStyle(color: Colors.white),
      enabled: !(isDisabled ?? false),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.black,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF2C94C)),
        ),
      ),
    );
  }

  Widget buildButton({
    required String text,
    required VoidCallback onPressed,
    required double fontSize,
    bool? isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isLoading ?? false) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF2C94C),
          padding: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        child: (isLoading ?? false)
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                text,
                style: TextStyle(color: Colors.black, fontSize: fontSize),
              ),
      ),
    );
  }
}
