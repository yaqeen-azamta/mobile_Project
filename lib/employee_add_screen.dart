import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

const kBurgundy = Color(0xFF800020);

class EmployeeAddScreen extends StatefulWidget {
  const EmployeeAddScreen({super.key});

  @override
  State<EmployeeAddScreen> createState() => _EmployeeAddScreenState();
}

class _EmployeeAddScreenState extends State<EmployeeAddScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nationalId = TextEditingController();
  final _password = TextEditingController();

  File? _image;
  bool _saving = false;

  static const String _addEmployeeUrl =
      'http://10.0.2.2/car_rental_backend/api/employees_add.php';

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _nationalId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (x == null) return;
    setState(() => _image = File(x.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final req = http.MultipartRequest(
        "POST",
        Uri.parse(_addEmployeeUrl),
      );

      req.fields['full_name'] = _fullName.text.trim();
      req.fields['email'] = _email.text.trim();
      req.fields['national_id'] = _nationalId.text.trim();
      req.fields['password'] = _password.text;

      if (_phone.text.trim().isNotEmpty) {
        req.fields['phone'] = _phone.text.trim();
      }

      if (_image != null) {
        req.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _image!.path,
          ),
        );
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        throw Exception("HTTP ${res.statusCode}: ${res.body}");
      }

      final decoded = json.decode(res.body);
      final ok = decoded is Map &&
          (decoded['success'] == true || decoded['ok'] == true);

      if (!ok) {
        throw Exception(decoded['message'] ?? "Create failed");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee created")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Employee"),
        backgroundColor: kBurgundy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: kBurgundy.withOpacity(0.12),
                              backgroundImage:
                                  _image != null ? FileImage(_image!) : null,
                              child: _image == null
                                  ? const Icon(Icons.person, color: kBurgundy)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kBurgundy,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text("Pick image"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _fullName,
                          decoration: _dec("Full name", Icons.badge),
                          validator: (v) => (v == null || v.trim().length < 3)
                              ? "Enter full name"
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec("Email", Icons.email),
                          validator: (v) {
                            final s = (v ?? "").trim();
                            if (s.isEmpty) return "Email required";
                            if (!s.contains("@")) return "Invalid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: _dec("Phone (optional)", Icons.phone),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nationalId,
                          decoration: _dec("National ID", Icons.perm_identity),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "National ID required"
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: _dec("Password", Icons.lock),
                          validator: (v) => (v == null || v.length < 6)
                              ? "Min 6 chars"
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBurgundy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _saving ? "Saving..." : "Create Employee",
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
