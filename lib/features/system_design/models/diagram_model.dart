import 'package:flutter_flow_chart/flutter_flow_chart.dart';

class DiagramModel {
  final String id;
  final String name;
  final List<Map<String, dynamic>> elements;
  
  DiagramModel({
    required this.id,
    required this.name,
    required this.elements,
  });

  factory DiagramModel.fromMap(Map<String, dynamic> map, String id) {
    return DiagramModel(
      id: id,
      name: map['name'] ?? 'Untitled',
      elements: List<Map<String, dynamic>>.from(map['elements'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'elements': elements,
    };
  }
}
