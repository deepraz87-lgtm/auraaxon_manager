class BusinessTypeModel {
  final String id;
  final String name;
  final String icon;
  final String categoryId;
  final List<String> allowedTabs;

  BusinessTypeModel({
    required this.id,
    required this.name,
    this.icon = 'storefront',
    this.categoryId = '',
    required this.allowedTabs,
  });

  factory BusinessTypeModel.fromJson(String id, Map<String, dynamic> json) {
    return BusinessTypeModel(
      id: id,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'storefront',
      categoryId: json['categoryId']?.toString() ?? '',
      allowedTabs: (json['allowedTabs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      if (categoryId.isNotEmpty) 'categoryId': categoryId,
      'allowedTabs': allowedTabs,
    };
  }
}
