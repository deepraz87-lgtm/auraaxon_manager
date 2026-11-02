class ProductModel {
  final String id;
  final String name;
  final String version;
  final String status;
  final String releaseDate;
  final String category;
  final double price;
  final double monthlyFee;
  final String description;
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.version,
    required this.status,
    required this.releaseDate,
    required this.category,
    required this.price,
    this.monthlyFee = 0.0,
    required this.description,
    required this.imageUrl,
  });

  // API එකෙන් ලැබෙන JSON දත්ත Model එකක් බවට පත් කිරීමට
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      version: json['version']?.toString() ?? 'Unknown',
      status: json['status']?.toString() ?? 'Unknown',
      releaseDate: json['releaseDate']?.toString() ?? 'Unknown',
      category: json['category']?.toString() ?? 'Software',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      monthlyFee: double.tryParse(json['monthly_fee']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}
