class Customer {
  final int customerId;
  final String fullName;
  final String nationalId;
  final String email;
  final String phone;
  final String passwordCustom;
  final String? imageName;

  Customer({
    required this.customerId,
    required this.fullName,
    required this.nationalId,
    required this.email,
    required this.phone,
    required this.passwordCustom,
    this.imageName,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: int.parse(json['customer_id'].toString()),
      fullName: json['full_name'],
      nationalId: json['national_id'],
      email: json['email'],
      phone: json['phone'],
      passwordCustom: json['passwordCustom'],
      imageName: json['imageName'],
    );
  }
}
