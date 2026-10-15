class Booking {
  final int bookingId;
  final String customerName;
  final String pickupDate;
  final String returnDate;
  final String status;
  final double totalPrice;
  final String paymentMethod;
  final int carId;

  Booking({
    required this.bookingId,
    required this.customerName,
    required this.pickupDate,
    required this.returnDate,
    required this.status,
    required this.totalPrice,
    required this.paymentMethod,
    required this.carId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: int.tryParse(json['rental_id']?.toString() ?? '0') ?? 0,
      customerName: json['customer_name'] ?? '',
      pickupDate: json['start_date'] ?? '',
      returnDate: json['end_date'] ?? '',
      status: json['rental_status'] ?? '',
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? '',
      carId: int.tryParse(json['car_id']?.toString() ?? '0') ?? 0,
    );
  }
}
