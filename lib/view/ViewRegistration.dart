import 'package:flutter/material.dart';
import '../controller/ControllerRegistration.dart';
import '../model/ModelRegistration.dart';

class ViewRegistration extends StatefulWidget {
  const ViewRegistration({super.key});

  @override
  State<ViewRegistration> createState() => _ViewRegistrationState();
}

class _ViewRegistrationState extends State<ViewRegistration> {
  late Future<List<UserModel>> _pendingUsersFuture;
  final ControllerRegistration controller = ControllerRegistration();
  final gradientColors = [
    const Color(0xFF665C3C),
    const Color(0xFF1E1E1E),
    const Color(0xFF1E1E1E),
  ];
  String? _loadingUserId;

  @override
  void initState() {
    super.initState();
    _pendingUsersFuture = controller.fetchPendingUsers();
    _refreshUserList();
  }

  void _refreshUserList() {
    setState(() {
      _pendingUsersFuture = controller.fetchPendingUsers();
    });
  }

  Future<void> _showResultDialog(String title, String message) async {
    if (!mounted) return; // Pastikan widget masih ada di tree
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleApprove(String userId) async {
    setState(() {
      _loadingUserId = userId; // Mulai loading untuk user ini
    });

    try {
      await controller.approveUser(userId);
      // Jika berhasil, tampilkan dialog sukses
      await _showResultDialog('Sukses', 'Pengguna berhasil disetujui.');
      // Muat ulang daftar untuk menghapus pengguna yang sudah disetujui
      _refreshUserList();
    } catch (e) {
      // Jika gagal, tampilkan dialog error
      await _showResultDialog(
          'Gagal', e.toString().replaceFirst("Exception: ", ""));
    } finally {
      // Hentikan loading setelah selesai, baik sukses maupun gagal
      if (mounted) {
        setState(() {
          _loadingUserId = null;
        });
      }
    }
  }

  Future<void> _handleReject(String userId) async {
    setState(() {
      _loadingUserId = userId; // Mulai loading untuk user ini
    });

    try {
      await controller.rejectUser(userId);
      // Jika berhasil, tampilkan dialog sukses
      await _showResultDialog('Sukses', 'Pengguna berhasil ditolak.');
      // Muat ulang daftar untuk menghapus pengguna yang sudah ditolak
      _refreshUserList();
    } catch (e) {
      // Jika gagal, tampilkan dialog error
      await _showResultDialog(
          'Gagal', e.toString().replaceFirst("Exception: ", ""));
    } finally {
      // Hentikan loading setelah selesai
      if (mounted) {
        setState(() {
          _loadingUserId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        appBar: AppBar(
          title: const Text('Persetujuan Registrasi'),
          backgroundColor: const Color(0xFFF2C94C),
          foregroundColor: Colors.black,
        ),
        // Gunakan FutureBuilder untuk membangun UI berdasarkan hasil Future
        body: FutureBuilder<List<UserModel>>(
          future: _pendingUsersFuture,
          builder: (context, snapshot) {
            // 1. Saat data sedang dimuat
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.hasData) {
              final users = snapshot.data!;
              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'Tidak ada user baru',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    color: const Color(0xFFF2C94C),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 35),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Role: ${user.role}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _handleApprove(user.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _handleReject(user.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            // Fallback jika tidak ada kondisi yang terpenuhi
            return const Center(child: Text('Tidak ada data'));
          },
        ),
      ),
    );
  }
}
