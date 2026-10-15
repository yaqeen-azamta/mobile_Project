import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color burgundy = Color(0xFF800020);

  final String _apiUrl = "http://10.0.2.2/car_rental_backend/api/signup.php";

  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  InputDecoration _dec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: burgundy, width: 2),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validateInputs() {
    final name = _nameCtrl.text.trim();
    final natId = _idCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (name.isEmpty ||
        natId.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        pass.isEmpty) {
      _snack("Please fill all fields");
      return false;
    }

    if (natId.length != 6) {
      _snack("National ID must be exactly 6 digits");
      return false;
    }

    if (phone.length != 9) {
      _snack("Phone number must be exactly 9 digits");
      return false;
    }

    final emailLower = email.toLowerCase();
    if (!emailLower.endsWith("@gmail.com")) {
      _snack("Email must end with @gmail.com");
      return false;
    }

    if (pass.length < 6) {
      _snack("Password must be at least 6 characters");
      return false;
    }

    return true;
  }

  Future<void> _signup() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(_apiUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['full_name'] = _nameCtrl.text.trim();
      request.fields['national_id'] = _idCtrl.text.trim();
      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['phone'] = _phoneCtrl.text.trim();
      request.fields['passwordCustom'] = _passwordCtrl.text;
      if (_selectedImage != null) {
        final file = await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
          filename: _selectedImage!.path.split('/').last,
        );
        request.files.add(file);
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      print("===== STATUS CODE =====");
      print(streamed.statusCode);

      print("===== RESPONSE HEADERS =====");
      print(streamed.headers);

      print("===== RAW SERVER RESPONSE =====");
      print(body);
      print("==============================");

      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        _snack("Invalid server response");
        print("JSON ERROR: $e");
        return;
      }

      if (streamed.statusCode == 200 && data["success"] == true) {
        _snack("Account created ✅");

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        _snack(data["message"]?.toString() ?? "Signup failed");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(title: const Text("Create Account"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    _selectedImage != null ? FileImage(_selectedImage!) : null,
                child: _selectedImage == null
                    ? const Icon(Icons.camera_alt, size: 35)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add Profile Image",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: _dec("Full Name", Icons.person),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: _dec("National ID (6 digits)", Icons.badge),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec("Email (must be @gmail.com)", Icons.email),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: _dec("Phone Number (9 digits)", Icons.phone),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: _dec("Password", Icons.lock),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: burgundy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Sign Up",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: burgundy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
