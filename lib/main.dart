import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Mahasiswa',
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: AbsensiLoginForm(),
        ),
      ),
    );
  }
}

class AbsensiLoginForm extends StatefulWidget {
  final http.Client? client;
  const AbsensiLoginForm({super.key, this.client});

  @override
  State<AbsensiLoginForm> createState() => _AbsensiLoginFormState();
}

class _AbsensiLoginFormState extends State<AbsensiLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  final nimController = TextEditingController();
  final kelasController = TextEditingController();
  final deviceController = TextEditingController();
  String? jenisKelamin;
  bool _isLoading = false;

  http.Client get client => widget.client ?? http.Client();

  Future<void> submitAbsensi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    var url = Uri.parse('https://absensi-mobile.primakarauniversity.ac.id/api/absensi');
    var dataAbsen = {
      "nama": namaController.text.trim(),
      "nim": nimController.text.trim(),
      "kelas": kelasController.text.trim(),
      "jenis_kelamin": jenisKelamin,
      "device": deviceController.text.trim(),
    };

    try {
      final response = await client.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(dataAbsen),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) print("HTTP Gagal. Status: ${response.statusCode}, Body: ${response.body}");
        throw Exception("Server Error: ${response.statusCode}");
      }

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        final finalResponse = {
          'status': result['status'],
          'message': result['message'],
          'data': dataAbsen,
        };
        if (kDebugMode) print('Respons Sukses Gabungan: ${jsonEncode(finalResponse)}');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Berhasil'),
            content: Text(finalResponse['message'] as String),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (result['status'] == 'error') {
        var msg = result['message'];
        String errorDisplay = "";
        // Field error detail: jika backend kirim Map of errors
        if (msg is Map) {
          errorDisplay = msg.entries
              .map((e) =>
                  "${e.key.toUpperCase()}: ${(e.value as List).join(", ")}")
              .join("\n");
        } else {
          errorDisplay = msg.toString();
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(errorDisplay),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gagal Mengirim'),
          content: Text("Gagal mengirim: Cek koneksi internet Anda atau cek data Anda dengan benar!. ($e)"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    setState(() { _isLoading = false; });
  }

  @override
  void dispose() {
    namaController.dispose();
    nimController.dispose();
    kelasController.dispose();
    deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Absensi Mahasiswa",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(
                        labelText: "Nama", prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.trim().isEmpty ? "Nama harus diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nimController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "NIM",
                        prefixIcon: Icon(Icons.confirmation_number)),
                    validator: (v) => v == null || v.trim().isEmpty ? "NIM harus diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        prefixIcon: Icon(Icons.people)),
                    items: ['Laki-Laki', 'Perempuan']
                        .map((jk) =>
                            DropdownMenuItem(value: jk, child: Text(jk)))
                        .toList(),
                    initialValue: jenisKelamin,
                    onChanged: (val) => setState(() => jenisKelamin = val),
                    validator: (v) => v == null ? "Jenis kelamin harus dipilih" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: deviceController,
                    decoration: const InputDecoration(
                        labelText: "Jenis Device",
                        prefixIcon: Icon(Icons.phone_android)),
                    validator: (v) => v == null || v.trim().isEmpty ? "Device harus diisi" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: kelasController,
                    decoration: const InputDecoration(
                        labelText: "Kelas", prefixIcon: Icon(Icons.class_)),
                    validator: (v) => v == null || v.trim().isEmpty ? "Kelas harus diisi" : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : submitAbsensi,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
