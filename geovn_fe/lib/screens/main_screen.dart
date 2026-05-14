import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/province_model.dart';
import '../service/database_helper.dart';
import '../widgets/vietnam_map_painter.dart';
import 'comparison_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Province> provinces = [];
  bool isLoading = true;

  final TextEditingController _ctrlA = TextEditingController();
  final TextEditingController _ctrlB = TextEditingController();
  final FocusNode _focusA = FocusNode();
  final FocusNode _focusB = FocusNode();

  bool _hoverA = false;
  bool _hoverB = false;

  String? pickAId;
  String? pickBId;
  bool compareActive = false;

  @override
  void initState() {
    super.initState();
    _focusA.addListener(() => setState(() {}));
    _focusB.addListener(() => setState(() {}));
    _loadProvinces();
  }

  @override
  void dispose() {
    _ctrlA.dispose();
    _ctrlB.dispose();
    _focusA.dispose();
    _focusB.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      final data = await DatabaseHelper.getProvinces();
      if (data.isNotEmpty) {
        setState(() {
          provinces = data.map((map) => Province.fromMap(map)).toList();
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading from database: $e');
    }
    _loadMockData();
  }

  void _loadMockData() {
    setState(() {
      provinces = [
        Province.fromMap({
          'id': 'HN',
          'name': 'Hà Nội',
          'population': 8400000,
          'area': 3358.6,
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [[107.82, 16.12], [108.04, 16.12], [108.04, 15.90], [107.82, 15.90], [107.82, 16.12]]
            ]
          },
        }),
        Province.fromMap({
          'id': 'HCM',
          'name': 'TP. Hồ Chí Minh',
          'population': 9300000,
          'area': 2061.0,
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [[108.22, 16.14], [108.52, 16.14], [108.52, 15.86], [108.22, 15.86], [108.22, 16.14]]
            ]
          },
        }),
      ];
      isLoading = false;
    });
  }

  Province? _byId(String? id) {
    if (id == null) return null;
    try {
      return provinces.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  bool get _canCompare => pickAId != null && pickBId != null && pickAId != pickBId;

  Set<String> get _emphasisIds {
    Set<String> ids = {};
    if (pickAId != null) ids.add(pickAId!);
    if (pickBId != null) ids.add(pickBId!);
    return ids;
  }

  void _pickProvince(int slot, Province p) {
    setState(() {
      if (slot == 0) {
        pickAId = p.id;
        _ctrlA.text = p.name;
        _focusA.unfocus();
      } else {
        pickBId = p.id;
        _ctrlB.text = p.name;
        _focusB.unfocus();
      }
      compareActive = true;
    });
  }

  void _clearAll() {
    setState(() {
      pickAId = null;
      pickBId = null;
      _ctrlA.clear();
      _ctrlB.clear();
      compareActive = false;
    });
  }

  void _navigateToComparison(BuildContext context) {
    if (!_canCompare) return;

    final a = _byId(pickAId)!;
    final b = _byId(pickBId)!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonScreen(
          provinceA: a,
          provinceB: b,
        ),
      ),
    );
  }

  List<Province> _filteredList(String filter) {
    final q = filter.trim().toLowerCase();
    final sorted = [...provinces]..sort((a, b) => a.name.compareTo(b.name));
    if (q.isEmpty) return sorted;
    return sorted.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  Widget _searchSlot({
    required int slot,
    required bool isDark,
    required String label,
    required TextEditingController controller,
    required FocusNode focus,
    required bool hover,
    required ValueChanged<bool> onHover,
  }) {
    final showList = focus.hasFocus || hover;
    final list = _filteredList(controller.text);

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !focus.hasFocus) onHover(false);
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 6),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: TextField(
              controller: controller,
              focusNode: focus,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm tỉnh thành...',
                hintStyle: GoogleFonts.beVietnamPro(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12),
                prefixIcon: Icon(Icons.search, size: 20, color: isDark ? Colors.indigoAccent : Colors.indigo),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          if (showList)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final p = list[i];
                  return ListTile(
                    dense: true,
                    title: Text(p.name, style: GoogleFonts.beVietnamPro(fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                    onTap: () => _pickProvince(slot, p),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provA = _byId(pickAId);
    final provB = _byId(pickBId);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Text('V-GeoStats', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.indigo)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Xóa chọn'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _searchSlot(slot: 0, isDark: isDark, label: 'Tỉnh thứ nhất', controller: _ctrlA, focus: _focusA, hover: _hoverA, onHover: (v) => setState(() => _hoverA = v))),
                  const SizedBox(width: 10),
                  Expanded(child: _searchSlot(slot: 1, isDark: isDark, label: 'Tỉnh thứ hai', controller: _ctrlB, focus: _focusB, hover: _hoverB, onHover: (v) => setState(() => _hoverB = v))),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.2) : Colors.grey.shade50,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    child: LayoutBuilder(
                      builder: (_, c) => CustomPaint(
                        size: Size(c.maxWidth, c.maxHeight),
                        painter: VietnamMapPainter(
                          provinces: provinces,
                          emphasisIds: _emphasisIds,
                          dimOutsideEmphasis: _emphasisIds.isNotEmpty,
                          isDarkMode: isDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _canCompare
                          ? 'Đã chọn ${provA?.name} so sánh với ${provB?.name}'
                          : 'Chọn 2 tỉnh để bắt đầu so sánh',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _canCompare ? (isDark ? Colors.cyanAccent : Colors.indigo) : Colors.grey
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _canCompare ? () => _navigateToComparison(context) : null,
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('So sánh'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}