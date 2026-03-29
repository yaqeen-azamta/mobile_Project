class Car {
  final int carId;
  final String plateNumber;
  final String brand;
  final String model;
  final int year;
  final String type;
  final double dailyPrice;
  final String status;
  final String color;
  final int seats;

  Car({
    required this.carId,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.year,
    required this.type,
    required this.dailyPrice,
    required this.status,
    required this.color,
    required this.seats,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      carId: int.parse(json['car_id'].toString()),
      plateNumber: json['plate_number'],
      brand: json['brand'],
      model: json['model'],
      year: int.parse(json['year'].toString()),
      type: json['type'],
      dailyPrice: double.parse(json['daily_price'].toString()),
      status: json['status'],
      color: json['color'],
      seats: int.parse(json['seats'].toString()),
    );
  }
}
