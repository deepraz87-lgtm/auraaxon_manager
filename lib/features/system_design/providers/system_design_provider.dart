import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:uuid/uuid.dart';
import '../models/diagram_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomToolTemplate {
  final String id;
  final String name;
  final ElementKind kind;
  final int iconCode;

  CustomToolTemplate({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconCode,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'kind': kind.name, 'iconCode': iconCode};
  }

  factory CustomToolTemplate.fromMap(Map<String, dynamic> map) {
    return CustomToolTemplate(
      id: map['id'],
      name: map['name'],
      kind: ElementKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => ElementKind.rectangle,
      ),
      iconCode: map['iconCode'] ?? 0,
    );
  }
}

class SystemDesignState {
  final Dashboard? dashboard;
  final List<Map<String, dynamic>> projects;
  final List<CustomToolTemplate> customTools;
  final String? currentProjectId;
  final String? currentProjectName;
  final bool isLoading;
  final String? error;

  SystemDesignState({
    this.dashboard,
    this.projects = const [],
    this.customTools = const [],
    this.currentProjectId,
    this.currentProjectName,
    this.isLoading = false,
    this.error,
  });

  SystemDesignState copyWith({
    Dashboard? dashboard,
    List<Map<String, dynamic>>? projects,
    List<CustomToolTemplate>? customTools,
    String? currentProjectId,
    String? currentProjectName,
    bool? isLoading,
    String? error,
  }) {
    return SystemDesignState(
      dashboard: dashboard ?? this.dashboard,
      projects: projects ?? this.projects,
      customTools: customTools ?? this.customTools,
      currentProjectId: currentProjectId ?? this.currentProjectId,
      currentProjectName: currentProjectName ?? this.currentProjectName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final systemDesignProvider =
    StateNotifierProvider<SystemDesignNotifier, SystemDesignState>((ref) {
      return SystemDesignNotifier();
    });

class SystemDesignNotifier extends StateNotifier<SystemDesignState> {
  SystemDesignNotifier() : super(SystemDesignState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await _loadCustomTools();
    await loadProjects();
  }

  Future<void> _loadCustomTools() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toolsStr = prefs.getString('custom_tools');
      if (toolsStr != null) {
        final List<dynamic> decoded = jsonDecode(toolsStr);
        final tools = decoded
            .map((m) => CustomToolTemplate.fromMap(m))
            .toList();
        state = state.copyWith(customTools: tools);
      }
    } catch (e) {
      print('Error loading custom tools: $e');
    }
  }

  Future<void> saveCustomTools() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toolsStr = jsonEncode(
        state.customTools.map((t) => t.toMap()).toList(),
      );
      await prefs.setString('custom_tools', toolsStr);
    } catch (e) {
      print('Error saving custom tools: $e');
    }
  }

  void addCustomTool(CustomToolTemplate tool) {
    final updatedList = List<CustomToolTemplate>.from(state.customTools)
      ..add(tool);
    state = state.copyWith(customTools: updatedList);
    saveCustomTools();
  }

  void removeCustomTool(String id) {
    final updatedList = state.customTools.where((t) => t.id != id).toList();
    state = state.copyWith(customTools: updatedList);
    saveCustomTools();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<List<Map<String, dynamic>>> _undoStack = [];
  String _lastSnapshotString = "";

  void saveSnapshot() {
    final dashboard = state.dashboard;
    if (dashboard == null) return;

    final snapshot = dashboard.elements.map((e) => e.toMap()).toList();
    final snapshotString = snapshot.toString();

    if (snapshotString != _lastSnapshotString) {
      // Deep copy the snapshot just to be safe
      final copy = snapshot.map((e) => Map<String, dynamic>.from(e)).toList();
      _undoStack.add(copy);
      _lastSnapshotString = snapshotString;

      if (_undoStack.length > 30) {
        _undoStack.removeAt(0);
      }
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final dashboard = state.dashboard;
    if (dashboard == null) return;

    final lastSnapshot = _undoStack.removeLast();
    _lastSnapshotString = lastSnapshot
        .toString(); // Update the hash so next save works correctly

    dashboard.removeAllElements();
    for (var elMap in lastSnapshot) {
      try {
        final element = FlowElement.fromMap(Map<String, dynamic>.from(elMap));
        dashboard.addElement(element);
      } catch (e) {
        print('Error parsing element on undo: $e');
      }
    }
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snapshot = await _firestore
          .collection('diagrams')
          .orderBy('updatedAt', descending: true)
          .get();
      final projects = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'name': doc.data()['name'] ?? 'Untitled Project',
            },
          )
          .toList();

      if (projects.isNotEmpty) {
        // Load the first one by default
        await loadDiagram(
          projects.first['id'] as String,
          projects.first['name'] as String,
          projects: projects,
        );
      } else {
        // Create a default one if none exist
        await createNewProject('My First Architecture');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadDiagram(
    String id,
    String name, {
    List<Map<String, dynamic>>? projects,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      projects: projects ?? state.projects,
    );
    try {
      final doc = await _firestore.collection('diagrams').doc(id).get();
      final dashboard = Dashboard();

      if (doc.exists) {
        final data = doc.data()!;
        final elementsList = List<Map<String, dynamic>>.from(
          data['elements'] ?? [],
        );

        for (var elMap in elementsList) {
          try {
            final element = FlowElement.fromMap(
              Map<String, dynamic>.from(elMap),
            );
            dashboard.addElement(element);
          } catch (e) {
            print('Error parsing element: $e');
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        dashboard: dashboard,
        currentProjectId: id,
        currentProjectName: name,
      );

      _undoStack.clear();
      _lastSnapshotString = "";
      saveSnapshot(); // Initial snapshot
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createNewProject(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newDoc = _firestore.collection('diagrams').doc();
      await newDoc.set({
        'name': name,
        'elements': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final newProject = {'id': newDoc.id, 'name': name};
      final updatedProjects = [newProject, ...state.projects];

      final dashboard = Dashboard();
      state = state.copyWith(
        isLoading: false,
        dashboard: dashboard,
        currentProjectId: newDoc.id,
        currentProjectName: name,
        projects: updatedProjects,
      );

      _undoStack.clear();
      _lastSnapshotString = "";
      saveSnapshot(); // Initial snapshot
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveDiagram() async {
    if (state.dashboard == null || state.currentProjectId == null) return;

    try {
      final elementsMap = state.dashboard!.elements
          .map((e) => e.toMap())
          .toList();

      await _firestore.collection('diagrams').doc(state.currentProjectId).set({
        'name': state.currentProjectName,
        'elements': elementsMap,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving diagram: $e');
    }
  }

  void addElement(FlowElement element) {
    saveSnapshot();
    state.dashboard?.addElement(element);
  }

  void clearDashboard() {
    saveSnapshot();
    state.dashboard?.removeAllElements();
  }
}
