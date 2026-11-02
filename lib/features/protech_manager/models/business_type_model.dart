class BusinessTypeModel {
  final String id;
  final String name;
  final List<String> allowedTabs;

  BusinessTypeModel({
    required this.id,
    required this.name,
    required this.allowedTabs,
  });

  factory BusinessTypeModel.fromJson(String id, Map<String, dynamic> json) {
    return BusinessTypeModel(
      id: id,
      name: json['name']?.toString() ?? '',
      allowedTabs: (json['allowedTabs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'allowedTabs': allowedTabs,
    };
  }
}
