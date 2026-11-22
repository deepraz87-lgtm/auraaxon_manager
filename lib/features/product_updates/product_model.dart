class ProductVariant {
  final String name;
  final double price;

  ProductVariant({required this.name, required this.price});

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
  };
}

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
  final String warranty;
  final String specs;
  final String condition;
  final List<ProductVariant> variants;

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
    this.warranty = '',
    this.specs = '',
    this.condition = 'Brand New',
    this.variants = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<ProductVariant> parsedVariants = [];
    if (json['variants'] != null && json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    }

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      version: json['version']?.toString() ?? 'v1.0.0',
      status: json['status']?.toString() ?? 'Active',
      releaseDate: (json['releaseDate'] ?? json['release_date'])?.toString() ?? '',
      category: json['category']?.toString() ?? 'Hardware',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      monthlyFee: double.tryParse((json['monthly_fee'] ?? json['monthlyFee'])?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString() ?? '',
      warranty: json['warranty']?.toString() ?? '',
      specs: json['specs']?.toString() ?? '',
      condition: json['condition']?.toString() ?? 'Brand New',
      variants: parsedVariants,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'status': status,
    'releaseDate': releaseDate,
    'category': category,
    'price': price,
    'monthly_fee': monthlyFee,
    'description': description,
    'image_url': imageUrl,
    'warranty': warranty,
    'specs': specs,
    'condition': condition,
    'variants': variants.map((v) => v.toJson()).toList(),
  };
}