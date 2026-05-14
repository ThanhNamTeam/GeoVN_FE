# V-GeoStats: Setup Guide

## Hướng dẫn Cài Đặt

Dự án này sử dụng SQLite để lưu trữ dữ liệu các tỉnh thành Việt Nam từ file GeoJSON.

### 1. Chuẩn Bị Database

#### Option A: Sử dụng Database Sẵn Có

Nếu bạn đã có file `vietnam_provinces.db`, hãy:

1. Tạo thư mục: `assets/databases/`
2. Đặt file `vietnam_provinces.db` vào thư mục trên

#### Option B: Tạo Database từ GeoJSON (Khuyến Nghị)

Bảng `provinces` trong database cần có cấu trúc:

```sql
CREATE TABLE provinces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  geometry TEXT NOT NULL,  -- GeoJSON Polygon hoặc MultiPolygon (dạng JSON string)
  population REAL,
  area REAL
);
```

**Ví dụ dữ liệu geometry:**

```json
{
  "type": "Polygon",
  "coordinates": [
    [
      [102.5, 19.5],
      [102.6, 19.5],
      [102.6, 19.6],
      [102.5, 19.6],
      [102.5, 19.5]
    ]
  ]
}
```

Hoặc MultiPolygon (cho các tỉnh có đảo):

```json
{
  "type": "MultiPolygon",
  "coordinates": [
    [
      [
        [102.5, 19.5],
        [102.6, 19.5],
        [102.6, 19.6],
        [102.5, 19.6],
        [102.5, 19.5]
      ]
    ],
    [
      [
        [103.5, 20.5],
        [103.6, 20.5],
        [103.6, 20.6],
        [103.5, 20.6],
        [103.5, 20.5]
      ]
    ]
  ]
}
```

### 2. Cấu Hình pubspec.yaml

Đảm bảo các dependencies đã được thêm:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^8.1.0
  sqflite: ^2.4.2+1
  provider: ^6.1.5+1
  fl_chart: ^1.2.0
  path: ^1.9.1

assets:
  - assets/databases/vietnam_provinces.db
```

### 3. Chạy Project

```bash
cd geovn_fe
flutter pub get
flutter run
```

### 4. Giao Diện

**MainScreen** hiển thị:

- **Trái**: Bản đồ Trước Sáp Nhập (Before Merger)
- **Phải**:
  - Danh sách tỉnh với tìm kiếm
  - Bản đồ Sau Sáp Nhập (After Merger) - có màu khác để phân biệt

**Tương Tác**:

- Click vào tỉnh trong danh sách để highlight nó trên bản đồ
- Tỉnh được chọn sẽ có màu đậm và viền neon trên cả 2 bản đồ

### 5. Cấu Trúc Project

```
lib/
├── main.dart
├── screens/
│   └── main_screen.dart
├── models/
│   └── province_model.dart
├── services/
│   └── database_helper.dart
├── widgets/
│   └── vietnam_map_painter.dart
```

### 6. Ghi Chú Quan Trọng

- **Scaling Logic**: Painter tự động tính toán bounds của tất cả provinces và scale vừa với canvas size
- **Coordinate System**: Dữ liệu GeoJSON dùng [Longitude, Latitude] nhưng Y axis sẽ được flip để vẽ đúng (lat tăng = canvas Y giảm)
- **MultiPolygon Support**: Painter hỗ trợ cả Polygon (1 danh sách điểm) và MultiPolygon (nhiều danh sách - cho các tỉnh có đảo)

### 7. Xử Lý Lỗi Thường Gặp

**Lỗi: "File database not found"**

- Kiểm tra assets/databases/vietnam_provinces.db có tồn tại không
- Kiểm tra pubspec.yaml đã khai báo assets chưa

**Lỗi: "Invalid geometry"**

- Kiểm tra chuỗi JSON geometry có hợp lệ không
- Đảm bảo coordinates là số, không phải string

**Bản đồ không hiển thị đúng**

- Kiểm tra bounds của geometry (phải nằm trong khoảng kinh độ 8-110, vĩ độ 1-23 của VN)
