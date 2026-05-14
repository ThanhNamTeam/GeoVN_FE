import 'dart:convert';

class Province {
  final String id;
  final String name;
  final double population;
  final double area;
  final Map<String, dynamic> geometry;
  final Map<String, dynamic> rawRow;

  Province({
    required this.id,
    required this.name,
    required this.population,
    required this.area,
    required this.geometry,
    required this.rawRow,
  });


  List<List<List<List<double>>>> getCoordinates() {
    if (geometry.isEmpty || !geometry.containsKey('coordinates')) return [];
    final type = geometry['type'] as String;
    final coords = geometry['coordinates'] as List;

    try {
      if (type == 'Polygon') {

        return [coords.map((ring) => (ring as List).map((pt) => [(pt[0] as num).toDouble(), (pt[1] as num).toDouble()]).toList()).toList()];
      } else if (type == 'MultiPolygon') {
        return coords.map((poly) => (poly as List).map((ring) => (ring as List).map((pt) => [(pt[0] as num).toDouble(), (pt[1] as num).toDouble()]).toList()).toList()).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }


  String getMergerDetails() {

    if (rawRow['is_merged'] == 1 || (rawRow['merged_into_id'] != null && rawRow['merged_into_id'] != '—')) {
      return "Thông tin sáp nhập: Tỉnh này có liên quan đến thay đổi địa giới (Mã đích: ${rawRow['merged_into_id']}).";
    }


    const keys = ['description', 'ghi_chu', 'note', 'history'];
    for (final k in keys) {
      if (rawRow[k] != null && rawRow[k].toString().trim().isNotEmpty) {
        return rawRow[k].toString();
      }
    }
    return 'Không có dữ liệu sáp nhập cụ thể trong CSDL.';
  }

  factory Province.fromMap(Map<String, dynamic> map) {
    return Province(
      id: (map['id'] ?? map['ma_tinh'] ?? '').toString(),
      name: (map['name'] ?? map['ten_tinh'] ?? '').toString(),
      population: double.tryParse(map['population']?.toString() ?? '0') ?? 0,
      area: double.tryParse(map['area']?.toString() ?? '0') ?? 0,
      geometry: map['geometry'] is String ? jsonDecode(map['geometry']) : (map['geometry'] ?? {}),
      rawRow: map,
    );
  }
}