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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      version: json['version']?.toString() ?? 'v1.0.0',
      status: json['status']?.toString() ?? 'Active',
      releaseDate: (json['releaseDate'] ?? json['release_date'])?.toString() ?? '',
      category: json['category']?.toString() ?? 'Software',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      monthlyFee: double.tryParse((json['monthly_fee'] ?? json['monthlyFee'])?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString() ?? '',
    );
  }
}
