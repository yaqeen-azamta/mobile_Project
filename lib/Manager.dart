class Manager {
  final int managerId;
  final String fullName;
  final String email;
  final String phone;
  final String passwordManager;
  final String nationalId;
  final String? imageName;

  Manager({
    required this.managerId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.passwordManager,
    required this.nationalId,
    this.imageName,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      managerId: int.parse(json['manager_id'].toString()),
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      passwordManager: json['passwordManager'],
      nationalId: json['national_id'],
      imageName: json['imageName'],
    );
  }
}
