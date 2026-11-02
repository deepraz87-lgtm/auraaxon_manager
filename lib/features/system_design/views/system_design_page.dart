import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:uuid/uuid.dart';
import '../providers/system_design_provider.dart';

class SystemDesignPage extends ConsumerStatefulWidget {
  const SystemDesignPage({super.key});

  @override
  ConsumerState<SystemDesignPage> createState() => _SystemDesignPageState();
}

class _SystemDesignPageState extends ConsumerState<SystemDesignPage> {
  final List<FlowElement> _selectedElements = [];

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    final isCtrlPressed =
        RawKeyboard.instance.keysPressed.contains(
          LogicalKeyboardKey.controlLeft,
        ) ||
        RawKeyboard.instance.keysPressed.contains(
          LogicalKeyboardKey.controlRight,
        );

    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyY) {
        if (_selectedElements.length > 1) {
          _alignNodesVertically();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.keyX) {
        if (_selectedElements.length > 1) {
          _alignNodesHorizontally();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        if (_selectedElements.length > 1) {
          _makeNodesSameSize();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.keyZ && isCtrlPressed) {
        ref.read(systemDesignProvider.notifier).undo();
        final dashboard = ref.read(systemDesignProvider).dashboard;
        if (dashboard != null) {
          _forceRepaint(dashboard);
          setState(() {
            _selectedElements
                .clear(); // Clear selection since objects might be recreated
          });
        }
      }
    }
  }

  void _forceRepaint(Dashboard dashboard) {
    try {
      // A small hack to force the dashboard canvas to repaint
      // if updating element.position directly doesn't trigger it.
      final z = dashboard.zoomFactor;
      dashboard.setZoomFactor(z + 0.001);
      dashboard.setZoomFactor(z);
    } catch (e) {}
  }

  void _alignNodesVertically() {
    ref.read(systemDesignProvider.notifier).saveSnapshot();

    final anchor = _selectedElements.first;
    final targetX = anchor.position.dx;

    for (int i = 1; i < _selectedElements.length; i++) {
      final element = _selectedElements[i];
      element.position = Offset(targetX, element.position.dy);
    }

    final dashboard = ref.read(systemDesignProvider).dashboard;
    if (dashboard != null) {
      _forceRepaint(dashboard);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aligned nodes vertically (Y Axis)')),
    );
  }

  void _alignNodesHorizontally() {
    ref.read(systemDesignProvider.notifier).saveSnapshot();

    final anchor = _selectedElements.first;
    final targetY = anchor.position.dy;

    for (int i = 1; i < _selectedElements.length; i++) {
      final element = _selectedElements[i];
      element.position = Offset(element.position.dx, targetY);
    }

    final dashboard = ref.read(systemDesignProvider).dashboard;
    if (dashboard != null) {
      _forceRepaint(dashboard);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aligned nodes horizontally (X Axis)')),
    );
  }

  void _makeNodesSameSize() {
    ref.read(systemDesignProvider.notifier).saveSnapshot();

    final anchor = _selectedElements.first;
    final targetSize = anchor.size;

    for (int i = 1; i < _selectedElements.length; i++) {
      final element = _selectedElements[i];
      element.size = targetSize;
    }

    final dashboard = ref.read(systemDesignProvider).dashboard;
    if (dashboard != null) {
      _forceRepaint(dashboard);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Made nodes same size (S Key)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(systemDesignProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft premium background
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboardState.error != null
          ? Center(child: Text('Error: ${dashboardState.error}'))
          : Builder(
              builder: (context) {
                final dashboard = dashboardState.dashboard;
                if (dashboard == null)
                  return const Center(child: Text('No Dashboard'));

                return Stack(
                  children: [
                    // 1. Grid Background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(
                          gridSize: 25.0,
                          dotColor: Colors.blueGrey.withOpacity(0.2),
                        ),
                      ),
                    ),

                    // 2. The FlowChart Canvas with Ctrl+Scroll Zoom and Right Click
                    Positioned.fill(
                      child: Listener(
                        onPointerDown: (event) {
                          // Save snapshot on pointer down to capture state before potential drag
                          ref
                              .read(systemDesignProvider.notifier)
                              .saveSnapshot();

                          if (event.buttons == kSecondaryMouseButton) {
                            // Right Click
                            if (_selectedElements.isNotEmpty) {
                              final isMulti = _selectedElements.length > 1;
                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  event.position.dx,
                                  event.position.dy,
                                  event.position.dx,
                                  event.position.dy,
                                ),
                                items: [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(
                                      isMulti
                                          ? 'Edit Selected Nodes'
                                          : 'Edit Node',
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      isMulti
                                          ? 'Delete Selected (${_selectedElements.length})'
                                          : 'Delete Node',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ).then((value) {
                                if (value == 'edit') {
                                  _showEditNodeDialog(
                                    context,
                                    dashboard,
                                    _selectedElements,
                                  );
                                } else if (value == 'delete') {
                                  ref
                                      .read(systemDesignProvider.notifier)
                                      .saveSnapshot();
                                  for (var element in _selectedElements) {
                                    dashboard.removeElement(element);
                                  }
                                  setState(() {
                                    _selectedElements.clear();
                                  });
                                }
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please left-click a node first to select it for options.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            final isCtrlPressed =
                                RawKeyboard.instance.keysPressed.contains(
                                  LogicalKeyboardKey.controlLeft,
                                ) ||
                                RawKeyboard.instance.keysPressed.contains(
                                  LogicalKeyboardKey.controlRight,
                                );

                            if (isCtrlPressed) {
                              final zoomDelta = pointerSignal.scrollDelta.dy > 0
                                  ? -0.1
                                  : 0.1;
                              try {
                                dashboard.setZoomFactor(
                                  dashboard.zoomFactor + zoomDelta,
                                );
                              } catch (e) {}
                            }
                          }
                        },
                        child: FlowChart(
                          dashboard: dashboard,
                          onDashboardTapped: ((context, position) {
                            for (var element in _selectedElements) {
                              element.borderColor = Colors.black;
                              element.borderThickness = 1.0;
                            }
                            setState(() {
                              _selectedElements.clear();
                            });
                          }),
                          onDashboardLongTapped: ((context, position) {}),
                          onElementLongPressed: (context, position, element) {
                            dashboard.removeElement(element);
                          },
                          onElementPressed: (context, position, element) {
                            final isCtrlPressed =
                                RawKeyboard.instance.keysPressed.contains(
                                  LogicalKeyboardKey.controlLeft,
                                ) ||
                                RawKeyboard.instance.keysPressed.contains(
                                  LogicalKeyboardKey.controlRight,
                                );

                            setState(() {
                              if (isCtrlPressed) {
                                // Toggle selection
                                if (_selectedElements.contains(element)) {
                                  _selectedElements.remove(element);
                                  element.borderColor = Colors.black;
                                  element.borderThickness = 1.0;
                                } else {
                                  _selectedElements.add(element);
                                  element.borderColor = Colors.blueAccent;
                                  element.borderThickness = 3.0;
                                }
                              } else {
                                // Single selection
                                if (!_selectedElements.contains(element) ||
                                    _selectedElements.length > 1) {
                                  for (var el in _selectedElements) {
                                    el.borderColor = Colors.black;
                                    el.borderThickness = 1.0;
                                  }
                                  _selectedElements.clear();
                                  _selectedElements.add(element);
                                  element.borderColor = Colors.blueAccent;
                                  element.borderThickness = 3.0;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    // 3. Floating Modern Toolbar (Glassmorphism)
                    Positioned(
                      left: 20,
                      top: 20,
                      bottom: 20,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 70,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildToolItem(
                                      icon: Icons.web,
                                      tooltip: 'Web Site',
                                      onPressed: () => _addNode(
                                        dashboard,
                                        ElementKind.rectangle,
                                        'Web Site',
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    _buildToolItem(
                                      icon: Icons.smartphone,
                                      tooltip: 'Mobile App',
                                      onPressed: () => _addNode(
                                        dashboard,
                                        ElementKind.rectangle,
                                        'Mobile App',
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    _buildToolItem(
                                      icon: Icons.storage,
                                      tooltip: 'Database / Storage',
                                      onPressed: () => _addNode(
                                        dashboard,
                                        ElementKind.storage,
                                        'Database',
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    _buildToolItem(
                                      icon: Icons.description,
                                      tooltip: 'Page / Screen',
                                      onPressed: () => _addNode(
                                        dashboard,
                                        ElementKind.parallelogram,
                                        'Page',
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    _buildToolItem(
                                      icon: Icons.api,
                                      tooltip: 'API / Service',
                                      onPressed: () => _addNode(
                                        dashboard,
                                        ElementKind.hexagon,
                                        'API Service',
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    _buildToolItem(
                                      icon: Icons.call_split,
                                      tooltip: 'Logic / Decision',
                                      onPressed: () => _addNode(
                                        dashboard,
                                        ElementKind.diamond,
                                        'Decision',
                                      ),
                                    ),
                                    if (dashboardState.customTools.isNotEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 5.0,
                                        ),
                                        child: Divider(
                                          indent: 15,
                                          endIndent: 15,
                                        ),
                                      ),
                                    ...dashboardState.customTools.map((tool) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 15.0,
                                        ),
                                        child: GestureDetector(
                                          onLongPress: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Delete Custom Tool?',
                                                ),
                                                content: Text(
                                                  'Are you sure you want to delete "${tool.name}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      ref
                                                          .read(
                                                            systemDesignProvider
                                                                .notifier,
                                                          )
                                                          .removeCustomTool(
                                                            tool.id,
                                                          );
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: _buildToolItem(
                                            icon: IconData(
                                              tool.iconCode,
                                              fontFamily: 'MaterialIcons',
                                            ),
                                            tooltip: tool.name,
                                            onPressed: () => _addNode(
                                              dashboard,
                                              tool.kind,
                                              tool.name,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      child: Divider(indent: 15, endIndent: 15),
                                    ),
                                    _buildToolItem(
                                      icon: Icons.add,
                                      tooltip: 'Add Custom Tool',
                                      color: Colors.blueAccent,
                                      onPressed: () =>
                                          _showAddCustomToolDialog(context),
                                    ),
                                    const SizedBox(height: 15),
                                    _buildToolItem(
                                      icon: Icons.delete_sweep,
                                      tooltip: 'Clear Canvas',
                                      color: Colors.redAccent,
                                      onPressed: () {
                                        ref
                                            .read(systemDesignProvider.notifier)
                                            .clearDashboard();
                                        setState(() {
                                          _selectedElements.clear();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 4. Project Selection Top Bar
                    Positioned(
                      top: 20,
                      left: 110,
                      right: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.folder,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      dashboardState.currentProjectName ??
                                          'Loading...',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _showSwitchProjectDialog(
                                          context,
                                          ref,
                                          dashboardState.projects,
                                        );
                                      },
                                      icon: const Icon(Icons.swap_horiz),
                                      label: const Text('Switch'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.blueAccent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _showNewProjectDialog(context, ref);
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('New'),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        ref
                                            .read(systemDesignProvider.notifier)
                                            .saveDiagram();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Project saved successfully!',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = const Color(0xFF4A4A68),
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          hoverColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
      ),
    );
  }

  void _addNode(Dashboard dashboard, ElementKind kind, String label) {
    final uuid = const Uuid().v4();
    final element = FlowElement(
      position: const Offset(
        250,
        150,
      ), // Default position slightly offset from toolbar
      size: const Size(180, 80),
      text: label,
      kind: kind,
      handlers: [
        Handler.bottomCenter,
        Handler.topCenter,
        Handler.leftCenter,
        Handler.rightCenter,
      ],
    );
    dashboard.addElement(element);
  }

  // --- Edit Node Dialog ---
  void _showEditNodeDialog(
    BuildContext context,
    Dashboard dashboard,
    List<FlowElement> elements,
  ) {
    if (elements.isEmpty) return;

    final anchor = elements.first;
    final isMulti = elements.length > 1;

    final textController = TextEditingController(
      text: isMulti ? '' : anchor.text,
    );
    double scaleValue = anchor.size.width / 180.0;
    if (scaleValue < 0.5) scaleValue = 0.5;
    if (scaleValue > 5.0) scaleValue = 5.0;

    final Map<String, Color> colorOptions = {
      'Default': Colors.white,
      'Blue': Colors.blue.shade100,
      'Green': Colors.green.shade100,
      'Red': Colors.red.shade100,
      'Yellow': Colors.yellow.shade100,
      'Orange': Colors.orange.shade100,
      'Purple': Colors.purple.shade100,
      'Grey': Colors.grey.shade200,
    };

    String selectedColorName = 'Default';
    for (var entry in colorOptions.entries) {
      if (entry.value.value == anchor.backgroundColor.value) {
        selectedColorName = entry.key;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isMulti ? 'Edit Selected Nodes' : 'Edit Node'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMulti)
                      TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                          labelText: 'Node Name',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                    if (!isMulti) const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Size Scale: ${scaleValue.toStringAsFixed(1)}x'),
                        Slider(
                          value: scaleValue,
                          min: 0.5,
                          max: 3.0,
                          divisions: 25,
                          onChanged: (val) => setState(() => scaleValue = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedColorName,
                      decoration: const InputDecoration(
                        labelText: 'Background Color',
                        border: OutlineInputBorder(),
                      ),
                      items: colorOptions.keys.map((String name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: colorOptions[name],
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value != null) selectedColorName = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    for (var element in elements) {
                      dashboard.removeElement(element);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isMulti ? 'Nodes deleted!' : 'Node deleted!',
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(isMulti ? 'Delete Nodes' : 'Delete Node'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(systemDesignProvider.notifier).saveSnapshot();

                    final newColor =
                        colorOptions[selectedColorName] ?? Colors.white;

                    for (var element in elements) {
                      String currentText = element.text;
                      if (!isMulti) {
                        currentText = textController.text;
                        element.text = currentText;
                      }

                      // Base text size
                      double baseTextSize = 16.0;
                      if (currentText.length > 50) {
                        baseTextSize = 9.0;
                      } else if (currentText.length > 35) {
                        baseTextSize = 11.0;
                      } else if (currentText.length > 20) {
                        baseTextSize = 13.0;
                      }

                      element.textSize = baseTextSize * scaleValue;
                      element.size = Size(
                        180.0 * scaleValue,
                        80.0 * scaleValue,
                      );
                      element.backgroundColor = newColor;
                    }
                    _forceRepaint(dashboard);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCustomToolDialog(BuildContext context) {
    final nameController = TextEditingController();
    ElementKind selectedKind = ElementKind.rectangle;
    int selectedIconCode = Icons.star.codePoint;

    final icons = {
      'Star': Icons.star.codePoint,
      'Computer': Icons.computer.codePoint,
      'Cloud': Icons.cloud.codePoint,
      'Database': Icons.storage.codePoint,
      'Device': Icons.devices.codePoint,
      'Folder': Icons.folder.codePoint,
      'Security': Icons.security.codePoint,
      'Web': Icons.web.codePoint,
      'App': Icons.smartphone.codePoint,
      'Router': Icons.router.codePoint,
      'Server': Icons.dns.codePoint,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Custom Tool'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tool Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ElementKind>(
                      value: selectedKind,
                      decoration: const InputDecoration(
                        labelText: 'Shape',
                        border: OutlineInputBorder(),
                      ),
                      items: ElementKind.values.map((kind) {
                        return DropdownMenuItem(
                          value: kind,
                          child: Text(kind.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedKind = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedIconCode,
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        border: OutlineInputBorder(),
                      ),
                      items: icons.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.value,
                          child: Row(
                            children: [
                              Icon(
                                IconData(
                                  entry.value,
                                  fontFamily: 'MaterialIcons',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(entry.key),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedIconCode = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    final tool = CustomToolTemplate(
                      id: const Uuid().v4(),
                      name: nameController.text.trim(),
                      kind: selectedKind,
                      iconCode: selectedIconCode,
                    );
                    ref.read(systemDesignProvider.notifier).addCustomTool(tool);
                    Navigator.pop(context);
                  },
                  child: const Text('Add Tool'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSwitchProjectDialog(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> projects,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Switch Project'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ListTile(
                  leading: const Icon(
                    Icons.account_tree,
                    color: Colors.blueAccent,
                  ),
                  title: Text(project['name']),
                  onTap: () {
                    ref
                        .read(systemDesignProvider.notifier)
                        .loadDiagram(project['id'], project['name']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showNewProjectDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Project'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  ref
                      .read(systemDesignProvider.notifier)
                      .createNewProject(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

// Custom Grid Painter to create a dot grid background
class _GridPainter extends CustomPainter {
  final double gridSize;
  final Color dotColor;

  _GridPainter({required this.gridSize, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; x != 0 && y < size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }

    // Fill first column explicitly
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawCircle(Offset(0, y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
