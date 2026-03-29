import 'dart:convert';
import 'package:car_retal/manager_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'EmployeeRentalsScreen.dart';
import 'signup_screen.dart';
import 'car_list_screen.dart';

class ManagerHomeScreen extends StatelessWidget {
  final String fullName;
  const ManagerHomeScreen({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manager")),
      body: Center(child: Text("Welcome Manager: $fullName")),
    );
  }
}

class CustomerHomeScreen extends StatelessWidget {
  final String fullName;
  const CustomerHomeScreen({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer")),
      body: Center(child: Text("Welcome Customer: $fullName")),
    );
  }
}

// ===============================
// Login Screen
// ===============================
class LoginScreen extends StatefulWidget {
  final bool fromRent;
  const LoginScreen({super.key, this.fromRent = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color burgundy = Color(0xFF800020);
  static const Color darkGrey = Color(0xFF2B2B2B);

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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

  Future<void> _doLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final url = Uri.parse(
        "http://10.0.2.2/car_rental_backend/api/login.php",
      );

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (data["success"] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Login failed")),
        );
        return;
      }

      final role = data["role"]?.toString() ?? "";
      final user = data["user"] as Map<String, dynamic>;

      final fullName = user["full_name"]?.toString() ?? "";
      final int userId = user["id"];
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove("customer_id");
      await prefs.remove("employee_id");
      await prefs.remove("manager_id");

      if (role == "customer") {
        await prefs.setInt("customer_id", userId);
      } else if (role == "employee") {
        await prefs.setInt("employee_id", userId);
      } else if (role == "manager") {
        await prefs.setInt("manager_id", userId);
      }

      await prefs.setString("full_name", fullName);
      await prefs.setString("role", role);
      await prefs.setBool("isLoggedIn", true);

      if (!mounted) return;
      if (role == "manager") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ManagerDashboardScreen()),
        );
      } else if (role == "employee") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeRentalsScreen(
              employeeName: fullName,
              employeeImageUrl: "",
            ),
          ),
        );
      } else if (role == "customer") {
        if (widget.fromRent) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CarListScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.directions_car, size: 70, color: burgundy),
              const SizedBox(height: 10),
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: darkGrey,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Login to continue",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec("Email", Icons.email),
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
                  onPressed: _loading ? null : _doLogin,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Login",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
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
      ),
    );
  }
}
