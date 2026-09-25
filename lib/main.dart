import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite Split Rectangles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
      ),
      home: const InfiniteSplitScreen(),
    );
  }
}

enum DarkLightStyle { blackAndWhite, colorful }

/// Immutable node representing a rectangle or a split container
class SplitNode {
  final String id;
  final Color color;
  final bool isSplit;
  final SplitNode? firstChild;
  final SplitNode? secondChild;
  final bool isHorizontal;
  final double splitRatio;

  const SplitNode({
    required this.id,
    required this.color,
    this.isSplit = false,
    this.firstChild,
    this.secondChild,
    this.isHorizontal = true,
    this.splitRatio = 0.5,
  });

  int get count {
    if (!isSplit || firstChild == null || secondChild == null) return 1;
    return firstChild!.count + secondChild!.count;
  }

  /// Recursively recolor nodes using shades of a base color
  SplitNode recolorWith(Color baseColor, Random rng) {
    final hsl = HSLColor.fromColor(baseColor);
    final newColor = hsl
        .withLightness(
          (hsl.lightness + (rng.nextDouble() * 0.4 - 0.2)).clamp(0.2, 0.85),
        )
        .withSaturation(
          (hsl.saturation + (rng.nextDouble() * 0.3 - 0.15)).clamp(0.3, 1.0),
        )
        .toColor();

    if (!isSplit || firstChild == null || secondChild == null) {
      return SplitNode(
        id: id,
        color: newColor,
        isSplit: false,
      );
    }

    return SplitNode(
      id: id,
      color: newColor,
      isSplit: true,
      isHorizontal: isHorizontal,
      splitRatio: splitRatio,
      firstChild: firstChild!.recolorWith(baseColor, rng),
      secondChild: secondChild!.recolorWith(baseColor, rng),
    );
  }
}

class InfiniteSplitScreen extends StatefulWidget {
  const InfiniteSplitScreen({super.key});

  @override
  State<InfiniteSplitScreen> createState() => _InfiniteSplitScreenState();
}

class _InfiniteSplitScreenState extends State<InfiniteSplitScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Random _random = Random();

  // History tracking for Undo / Redo
  late List<SplitNode> _history;
  int _historyIndex = 0;

  // Dark & Light Mode for rectangles
  bool _isDarkLightMode = false;
  DarkLightStyle _darkLightStyle = DarkLightStyle.blackAndWhite;

  // Settings customizable in Drawer
  double _gap = 3.0;
  double _borderRadius = 6.0;
  double _borderWidth = 0.0;
  final Color _borderColor = Colors.white70;
  double _splitRatio = 0.5; // Resize proportion for splits
  bool _useSingleColorMode = false;
  Color _selectedColor = Colors.indigoAccent;

  final List<Color> _palette = const [
    Colors.indigoAccent,
    Colors.deepPurpleAccent,
    Colors.tealAccent,
    Colors.amberAccent,
    Colors.deepOrangeAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.lightGreenAccent,
  ];

  @override
  void initState() {
    super.initState();
    _history = [
      SplitNode(
        id: '0',
        color: _selectedColor,
      ),
    ];
    _historyIndex = 0;
  }

  SplitNode get _currentRoot => _history[_historyIndex];

  Color _generateNextColor() {
    if (_useSingleColorMode) {
      final hsl = HSLColor.fromColor(_selectedColor);
      return hsl
          .withLightness(
            (hsl.lightness + (_random.nextDouble() * 0.4 - 0.2))
                .clamp(0.2, 0.85),
          )
          .withSaturation(
            (hsl.saturation + (_random.nextDouble() * 0.3 - 0.15))
                .clamp(0.3, 1.0),
          )
          .toColor();
    } else {
      return HSLColor.fromAHSL(
        1.0,
        _random.nextDouble() * 360,
        0.65 + _random.nextDouble() * 0.25,
        0.45 + _random.nextDouble() * 0.2,
      ).toColor();
    }
  }

  /// Calculates the color to display.
  /// If Dark & Light mode is OFF: returns the original color.
  /// If Dark & Light mode is ON: returns dark/light contrast shades.
  Color _getDisplayColor(SplitNode node, int depth) {
    if (!_isDarkLightMode) {
      return node.color; // Returns original color!
    }

    final isDarkPiece = (node.id.hashCode + depth).isEven;

    if (_darkLightStyle == DarkLightStyle.blackAndWhite) {
      // High contrast Dark & Light monochrome
      if (isDarkPiece) {
        final darkShade = 24 + (node.id.hashCode.abs() % 24);
        return Color.fromARGB(255, darkShade, darkShade, darkShade + 4);
      } else {
        final lightShade = 230 + (node.id.hashCode.abs() % 25);
        return Color.fromARGB(255, lightShade, lightShade, lightShade);
      }
    } else {
      // Dark & Light colored tones
      final hsl = HSLColor.fromColor(node.color);
      if (isDarkPiece) {
        return hsl
            .withLightness(0.18)
            .withSaturation(0.70)
            .toColor();
      } else {
        return hsl
            .withLightness(0.85)
            .withSaturation(0.65)
            .toColor();
      }
    }
  }

  void _onRectangleTap(String targetId, bool isWide) {
    final updated = _splitNode(_currentRoot, targetId, isWide);
    if (updated != null) {
      setState(() {
        // Discard forward history on new action
        _history = _history.sublist(0, _historyIndex + 1);
        _history.add(updated);
        _historyIndex++;
      });
    }
  }

  SplitNode? _splitNode(SplitNode node, String targetId, bool isWide) {
    if (node.id == targetId) {
      if (node.isSplit) return node;
      return SplitNode(
        id: node.id,
        color: node.color,
        isSplit: true,
        isHorizontal: isWide,
        splitRatio: _splitRatio,
        firstChild: SplitNode(
          id: '${node.id}-1',
          color: _generateNextColor(),
        ),
        secondChild: SplitNode(
          id: '${node.id}-2',
          color: _generateNextColor(),
        ),
      );
    }

    if (!node.isSplit || node.firstChild == null || node.secondChild == null) {
      return null;
    }

    final newLeft = _splitNode(node.firstChild!, targetId, isWide);
    if (newLeft != null) {
      return SplitNode(
        id: node.id,
        color: node.color,
        isSplit: true,
        isHorizontal: node.isHorizontal,
        splitRatio: node.splitRatio,
        firstChild: newLeft,
        secondChild: node.secondChild,
      );
    }

    final newRight = _splitNode(node.secondChild!, targetId, isWide);
    if (newRight != null) {
      return SplitNode(
        id: node.id,
        color: node.color,
        isSplit: true,
        isHorizontal: node.isHorizontal,
        splitRatio: node.splitRatio,
        firstChild: node.firstChild,
        secondChild: newRight,
      );
    }

    return null;
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
      });
    }
  }

  void _reload() {
    final newRoot = SplitNode(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      color: _selectedColor,
    );
    setState(() {
      _history = _history.sublist(0, _historyIndex + 1);
      _history.add(newRoot);
      _historyIndex++;
    });
  }

  void _recolorAll() {
    final recolored = _currentRoot.recolorWith(_selectedColor, _random);
    setState(() {
      _history = _history.sublist(0, _historyIndex + 1);
      _history.add(recolored);
      _historyIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = _historyIndex > 0;
    final canRedo = _historyIndex < _history.length - 1;
    final count = _currentRoot.count;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Settings Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Counter Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.crop_square_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Dark & Light Mode Toggle Button
          IconButton(
            icon: Icon(
              _isDarkLightMode ? Icons.contrast : Icons.contrast_outlined,
              color: _isDarkLightMode ? Colors.amberAccent : Colors.white70,
            ),
            tooltip: _isDarkLightMode
                ? 'Dark & Light Mode: ON (Click to restore colors)'
                : 'Dark & Light Mode: OFF (Click to activate)',
            onPressed: () {
              setState(() {
                _isDarkLightMode = !_isDarkLightMode;
              });
            },
          ),
          // Before (Undo)
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Before (Undo)',
            onPressed: canUndo ? _undo : null,
          ),
          // After (Redo)
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'After (Redo)',
            onPressed: canRedo ? _redo : null,
          ),
          // Reload / Reset
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload (Reset to 1)',
            onPressed: _reload,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(_gap),
          child: _buildNodeWidget(_currentRoot, 0),
        ),
      ),
    );
  }

  Widget _buildNodeWidget(SplitNode node, int depth) {
    if (!node.isSplit || node.firstChild == null || node.secondChild == null) {
      final displayColor = _getDisplayColor(node, depth);

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= constraints.maxHeight;
            return GestureDetector(
              onTap: () => _onRectangleTap(node.id, isWide),
              child: Container(
                margin: EdgeInsets.all(_gap / 2),
                decoration: BoxDecoration(
                  color: displayColor,
                  borderRadius: BorderRadius.circular(_borderRadius),
                  border: _borderWidth > 0
                      ? Border.all(color: _borderColor, width: _borderWidth)
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    final firstFlex = (_splitRatio * 100).round().clamp(10, 90);
    final secondFlex = 100 - firstFlex;

    final children = [
      Expanded(
        flex: firstFlex,
        child: _buildNodeWidget(node.firstChild!, depth + 1),
      ),
      Expanded(
        flex: secondFlex,
        child: _buildNodeWidget(node.secondChild!, depth + 1),
      ),
    ];

    return node.isHorizontal
        ? Row(children: children)
        : Column(children: children);
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.indigoAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Customizations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20),

            // Dark & Light Mode Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark & Light Colors Mode'),
              subtitle: Text(
                _isDarkLightMode
                    ? 'Active (click to restore colors)'
                    : 'Turn on for dark and light contrast',
              ),
              secondary: Icon(
                Icons.contrast,
                color: _isDarkLightMode ? Colors.amberAccent : Colors.white60,
              ),
              value: _isDarkLightMode,
              thumbColor: const WidgetStatePropertyAll(Colors.amberAccent),
              onChanged: (val) => setState(() => _isDarkLightMode = val),
            ),

            if (_isDarkLightMode) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Black & White'),
                    selected:
                        _darkLightStyle == DarkLightStyle.blackAndWhite,
                    selectedColor: Colors.amberAccent.withValues(alpha: 0.3),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _darkLightStyle =
                            DarkLightStyle.blackAndWhite);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Color Shades'),
                    selected: _darkLightStyle == DarkLightStyle.colorful,
                    selectedColor: Colors.amberAccent.withValues(alpha: 0.3),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() =>
                            _darkLightStyle = DarkLightStyle.colorful);
                      }
                    },
                  ),
                ],
              ),
            ],

            const Divider(height: 20),

            // Gap Slider
            _buildSliderSection(
              title: 'Gap (Spacing)',
              valueText: '${_gap.toStringAsFixed(1)} px',
              child: Slider(
                value: _gap,
                min: 0.0,
                max: 20.0,
                divisions: 40,
                activeColor: Colors.indigoAccent,
                onChanged: (val) => setState(() => _gap = val),
              ),
            ),

            // Border Radius Slider
            _buildSliderSection(
              title: 'Border Radius',
              valueText: '${_borderRadius.toStringAsFixed(0)} px',
              child: Slider(
                value: _borderRadius,
                min: 0.0,
                max: 32.0,
                divisions: 32,
                activeColor: Colors.indigoAccent,
                onChanged: (val) => setState(() => _borderRadius = val),
              ),
            ),

            // Border Width Slider
            _buildSliderSection(
              title: 'Border Width',
              valueText: '${_borderWidth.toStringAsFixed(1)} px',
              child: Slider(
                value: _borderWidth,
                min: 0.0,
                max: 8.0,
                divisions: 16,
                activeColor: Colors.indigoAccent,
                onChanged: (val) => setState(() => _borderWidth = val),
              ),
            ),

            // Resize Split Ratio Slider
            _buildSliderSection(
              title: 'Split Proportion (Resize)',
              valueText:
                  '${(_splitRatio * 100).toInt()}% / ${(100 - (_splitRatio * 100).toInt())}%',
              child: Column(
                children: [
                  Slider(
                    value: _splitRatio,
                    min: 0.2,
                    max: 0.8,
                    divisions: 24,
                    activeColor: Colors.indigoAccent,
                    onChanged: (val) => setState(() => _splitRatio = val),
                  ),
                  Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (_splitRatio * 100).round().clamp(10, 90),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.indigoAccent,
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (100 - (_splitRatio * 100).round())
                              .clamp(10, 90),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.tealAccent,
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Pick Colors Section
            const Text(
              'Pick Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Color Swatches
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _palette.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 20,
                            color: Colors.black87,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Single Color Family switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use Picked Color Family'),
              subtitle: const Text('New splits use shades of picked color'),
              value: _useSingleColorMode,
              thumbColor: const WidgetStatePropertyAll(Colors.indigoAccent),
              onChanged: (val) => setState(() => _useSingleColorMode = val),
            ),

            const SizedBox(height: 12),

            // Recolor All Button
            OutlinedButton.icon(
              icon: const Icon(Icons.palette_outlined),
              label: const Text('Apply Picked Color to All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.indigoAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _recolorAll,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required String valueText,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueText,
                style: const TextStyle(color: Colors.indigoAccent),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
