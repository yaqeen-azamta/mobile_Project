class Employee {
  final int employeeId;
  final String fullName;
  final String email;
  final String nationalId;
  final String? phone;
  final String? imageName; // ✅ nullable

  Employee({
    required this.employeeId,
    required this.fullName,
    required this.email,
    required this.nationalId,
    this.phone,
    this.imageName,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
        employeeId: int.parse(json['employee_id'].toString()),
        fullName: json['full_name'] ?? '',
        email: json['email'] ?? '',
        nationalId: json['national_id'] ?? '',
        phone: json['phone'],
        imageName: json['imageName']);
  }
}
