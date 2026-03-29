import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'car_list_screen.dart';
import 'login_screen.dart';
import 'EmployeeRentalsScreen.dart';
import 'manager_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Rentals',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: FutureBuilder<Widget>(
        future: getStartScreen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}

Future<Widget> getStartScreen() async {
  final prefs = await SharedPreferences.getInstance();

  final bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
  final String? role = prefs.getString("role");

  if (isLoggedIn) {
    if (role == "manager") {
      return ManagerDashboardScreen();
    }

    if (role == "employee") {
      return EmployeeRentalsScreen(
        employeeName: prefs.getString("full_name") ?? "",
        employeeImageUrl: "",
      );
    }

    if (role == "customer") {
      return CarListScreen();
    }
  }

  return CarListScreen();
}
