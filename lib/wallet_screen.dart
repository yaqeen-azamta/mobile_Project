import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');

    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    String newText = text;
    if (text.length >= 3) {
      newText = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 0.0;
  bool loading = true;

  // Controllers
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt("customer_id");

    if (customerId == null) return;

    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/get_customer_profile.php?customer_id=$customerId",
    );

    final res = await http.get(url);
    final json = jsonDecode(res.body);

    if (json["success"] == true) {
      setState(() {
        balance = double.parse(json["customer"]["balance"].toString());
        loading = false;
      });
    }
  }

  Future<void> _payAndAddToWallet() async {
    final amount = double.tryParse(_amountCtrl.text.trim());

    if (amount == null || amount <= 0) {
      _toast("Enter valid amount");
      return;
    }

    if (_cardNumberCtrl.text.trim().length < 16) {
      _toast("Invalid card number");
      return;
    }

    if (!_expiryCtrl.text.contains('/')) {
      _toast("Invalid expiry date");
      return;
    }

    if (_cvvCtrl.text.trim().length < 3) {
      _toast("Invalid CVV");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt("customer_id");

    final url = Uri.parse(
      "http://10.0.2.2/car_rental_backend/api/add_wallet_credit.php",
    );

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "customer_id": customerId,
        "amount": amount,
      }),
    );

    if (!res.body.trim().startsWith("{")) {
      _toast("Server error");
      return;
    }

    final json = jsonDecode(res.body);

    if (json["success"] == true) {
      setState(() {
        balance = double.parse(json["balance"].toString());
        _cardNumberCtrl.clear();
        _expiryCtrl.clear();
        _cvvCtrl.clear();
        _amountCtrl.clear();
      });

      Navigator.pop(context, true);
    } else {
      _toast(json["message"] ?? "Payment failed");
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Wallet")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text("Current Balance"),
                  const SizedBox(height: 10),
                  Text(
                    "${balance.toStringAsFixed(2)} ₪",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _cardNumberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Card Number",
                hintText: "1234 5678 9012 3456",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ExpiryDateInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Expiry (MM/YY)",
                      hintText: "MM/YY",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvvCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: "CVV",
                      hintText: "***",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                hintText: "Enter amount",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _payAndAddToWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF800020),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Pay & Add to Wallet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
