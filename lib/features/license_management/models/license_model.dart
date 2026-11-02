class LicenseModel {
  final String id;
  final String customerName;
  final String productName;
  final bool isActive;

  LicenseModel({
    required this.id,
    required this.customerName,
    required this.productName,
    required this.isActive,
  });

  // State යාවත්කාලීන කිරීම සඳහා copyWith ක්‍රමය (method)
  LicenseModel copyWith({
    String? id,
    String? customerName,
    String? productName,
    bool? isActive,
  }) {
    return LicenseModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      productName: productName ?? this.productName,
      isActive: isActive ?? this.isActive,
    );
  }
}
