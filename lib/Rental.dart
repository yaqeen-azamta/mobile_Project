class Rental {
  final int rentalId;
  final int customerId;
  final int carId;
  final DateTime startDate;
  final DateTime endDate;
  final String rentalStatus;
  final double? totalPrice;

  Rental({
    required this.rentalId,
    required this.customerId,
    required this.carId,
    required this.startDate,
    required this.endDate,
    required this.rentalStatus,
    this.totalPrice,
  });
  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      rentalId: int.parse(json['rental_id'].toString()),
      customerId: int.parse(json['customer_id'].toString()),
      carId: int.parse(json['car_id'].toString()),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      rentalStatus: json['rental_status'],
      totalPrice: json['total_price'] == null
          ? null
          : double.parse(json['total_price'].toString()),
    );
  }
}
