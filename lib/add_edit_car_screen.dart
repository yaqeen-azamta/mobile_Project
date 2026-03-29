import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'cars.dart';

const kBurgundy = Color(0xFF800020);

class AddEditCarScreen extends StatefulWidget {
  final Car? car;
  const AddEditCarScreen({super.key, this.car});

  @override
  State<AddEditCarScreen> createState() => _AddEditCarScreenState();
}

class _AddEditCarScreenState extends State<AddEditCarScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandC;
  late final TextEditingController _modelC;
  late final TextEditingController _yearC;
  late final TextEditingController _plateC;
  late final TextEditingController _seatsC;
  late final TextEditingController _priceC;
  late final TextEditingController _colorC;

  String _type = "Sedan";
  String _status = "AVAILABLE";

  File? _image1;
  File? _image2;

  bool _saving = false;
  bool get _isEdit => widget.car != null;

  static const _base = "http://10.0.2.2/car_rental_backend/api";

  static const _types = [
    "Sedan",
    "SUV",
    "Hatchback",
    "Coupe",
    "Van",
    "Pickup",
    "Other"
  ];

  static const _statuses = ["AVAILABLE", "RENTED", "MAINTENANCE", "DISABLED"];

  @override
  void initState() {
    super.initState();
    final c = widget.car;

    _brandC = TextEditingController(text: c?.brand ?? "");
    _modelC = TextEditingController(text: c?.model ?? "");
    _yearC = TextEditingController(text: c?.year.toString() ?? "");
    _plateC = TextEditingController(text: c?.plateNumber ?? "");
    _seatsC = TextEditingController(text: c?.seats.toString() ?? "");
    _priceC = TextEditingController(text: c?.dailyPrice.toString() ?? "");
    _colorC = TextEditingController(text: c?.color ?? "");

    if (c != null) {
      _type = c.type;
      _status = c.status.toUpperCase();
    }
  }

  @override
  void dispose() {
    _brandC.dispose();
    _modelC.dispose();
    _yearC.dispose();
    _plateC.dispose();
    _seatsC.dispose();
    _priceC.dispose();
    _colorC.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (x == null) return;

    setState(() {
      if (index == 1) {
        _image1 = File(x.path);
      } else {
        _image2 = File(x.path);
      }
    });
  }

  String? _req(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  String? _intReq(String? v, String msg) {
    if (v == null || v.trim().isEmpty) return msg;
    return int.tryParse(v) == null ? "Enter valid number" : null;
  }

  String? _doubleReq(String? v, String msg) {
    if (v == null || v.trim().isEmpty) return msg;
    return double.tryParse(v) == null ? "Enter valid number" : null;
  }

  // ---------- SAVE ----------
  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit && (_image1 == null || _image2 == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick two images")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final url = _isEdit ? "$_base/cars_update.php" : "$_base/cars_add.php";
      final req = http.MultipartRequest("POST", Uri.parse(url));

      req.fields.addAll({
        "plate_number": _plateC.text.trim(),
        "brand": _brandC.text.trim(),
        "model": _modelC.text.trim(),
        "year": _yearC.text.trim(),
        "type": _type,
        "daily_price": _priceC.text.trim(),
        "status": _status,
        "color": _colorC.text.trim(),
        "seats": _seatsC.text.trim(),
      });

      if (_isEdit) {
        req.fields["car_id"] = widget.car!.carId.toString();
      }

      if (_image1 != null) {
        req.files.add(
          await http.MultipartFile.fromPath("image1", _image1!.path),
        );
      }

      if (_image2 != null) {
        req.files.add(
          await http.MultipartFile.fromPath("image2", _image2!.path),
        );
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final decoded = json.decode(res.body);

      if (decoded["success"] != true) {
        throw Exception(decoded["message"] ?? "Save failed");
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? "Edit Car" : "Add Car"),
        backgroundColor: kBurgundy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TextFormField(
                controller: _plateC,
                decoration: _dec("Plate Number"),
                validator: (v) => _req(v, "Plate required"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _brandC,
                decoration: _dec("Brand"),
                validator: (v) => _req(v, "Brand required"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _modelC,
                decoration: _dec("Model"),
                validator: (v) => _req(v, "Model required"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _yearC,
                decoration: _dec("Year"),
                keyboardType: TextInputType.number,
                validator: (v) => _intReq(v, "Year required"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _type,
                items: _types
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
                decoration: _dec("Type"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _seatsC,
                decoration: _dec("Seats"),
                keyboardType: TextInputType.number,
                validator: (v) => _intReq(v, "Seats required"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceC,
                decoration: _dec("Daily Price"),
                keyboardType: TextInputType.number,
                validator: (v) => _doubleReq(v, "Price required"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _colorC,
                decoration: _dec("Color"),
                validator: (v) => _req(v, "Color required"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _status,
                items: _statuses
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
                decoration: _dec("Status"),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _pickImage(1),
                icon: const Icon(Icons.image),
                label:
                    Text(_image1 == null ? "Pick Image 1" : "Image 1 Selected"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _pickImage(2),
                icon: const Icon(Icons.image),
                label:
                    Text(_image2 == null ? "Pick Image 2" : "Image 2 Selected"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBurgundy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _saving ? "Saving..." : "Save",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
