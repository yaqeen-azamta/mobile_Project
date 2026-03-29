class CarImage {
  final int carImagesId;
  final int carId;
  final String imageName;

  CarImage({
    required this.carImagesId,
    required this.carId,
    required this.imageName,
  });

  factory CarImage.fromJson(Map<String, dynamic> json) {
    return CarImage(
      carImagesId: int.parse(json['car_images_id'].toString()),
      carId: int.parse(json['car_id'].toString()),
      imageName: json['imageName'],
    );
  }
}
