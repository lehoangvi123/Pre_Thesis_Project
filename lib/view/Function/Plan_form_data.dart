// lib/view/Function/Plan/plan_form_data.dart
// Constants & data cho form lập kế hoạch

class PlanFormData {

  // ── Nghề nghiệp (thêm "Khác" + text field) ──────────────
  static const occupations = [
    {'v': 'Student',    'i': '🎓', 'l': 'Sinh viên'},
    {'v': 'Employee',   'i': '💼', 'l': 'Nhân viên'},
    {'v': 'Freelancer', 'i': '💻', 'l': 'Freelancer'},
    {'v': 'Business',   'i': '🏢', 'l': 'Kinh doanh'},
    {'v': 'Doctor',     'i': '🩺', 'l': 'Y / Dược'},
    {'v': 'Teacher',    'i': '📚', 'l': 'Giáo viên'},
    {'v': 'Engineer',   'i': '⚙️', 'l': 'Kỹ sư'},
    {'v': 'Other',      'i': '✏️', 'l': 'Khác...'},
  ];

  // ── 64 tỉnh thành Việt Nam ───────────────────────────────
  static const provinces = [
    // Miền Nam
    {'v': 'HCM',         'l': 'TP. Hồ Chí Minh',    'r': 'south'},
    {'v': 'BinhDuong',   'l': 'Bình Dương',           'r': 'south'},
    {'v': 'DongNai',     'l': 'Đồng Nai',             'r': 'south'},
    {'v': 'LongAn',      'l': 'Long An',              'r': 'south'},
    {'v': 'TienGiang',   'l': 'Tiền Giang',           'r': 'south'},
    {'v': 'BenTre',      'l': 'Bến Tre',              'r': 'south'},
    {'v': 'VinhLong',    'l': 'Vĩnh Long',            'r': 'south'},
    {'v': 'TraVinh',     'l': 'Trà Vinh',             'r': 'south'},
    {'v': 'HauGiang',    'l': 'Hậu Giang',            'r': 'south'},
    {'v': 'SocTrang',    'l': 'Sóc Trăng',            'r': 'south'},
    {'v': 'BacLieu',     'l': 'Bạc Liêu',             'r': 'south'},
    {'v': 'CaMau',       'l': 'Cà Mau',               'r': 'south'},
    {'v': 'KienGiang',   'l': 'Kiên Giang',           'r': 'south'},
    {'v': 'AnGiang',     'l': 'An Giang',             'r': 'south'},
    {'v': 'DongThap',    'l': 'Đồng Tháp',            'r': 'south'},
    {'v': 'CanTho',      'l': 'Cần Thơ',              'r': 'south'},
    {'v': 'BaRiaVT',     'l': 'Bà Rịa - Vũng Tàu',   'r': 'south'},
    {'v': 'BinhPhuoc',   'l': 'Bình Phước',           'r': 'south'},
    {'v': 'TayNinh',     'l': 'Tây Ninh',             'r': 'south'},
    // Miền Trung
    {'v': 'DaNang',      'l': 'Đà Nẵng',              'r': 'central'},
    {'v': 'HueTT',       'l': 'Thừa Thiên Huế',       'r': 'central'},
    {'v': 'QuangNam',    'l': 'Quảng Nam',            'r': 'central'},
    {'v': 'QuangNgai',   'l': 'Quảng Ngãi',           'r': 'central'},
    {'v': 'BinhDinh',    'l': 'Bình Định',            'r': 'central'},
    {'v': 'PhuYen',      'l': 'Phú Yên',              'r': 'central'},
    {'v': 'KhanhHoa',    'l': 'Khánh Hòa',            'r': 'central'},
    {'v': 'NinhThuan',   'l': 'Ninh Thuận',           'r': 'central'},
    {'v': 'BinhThuan',   'l': 'Bình Thuận',           'r': 'central'},
    {'v': 'QuangBinh',   'l': 'Quảng Bình',           'r': 'central'},
    {'v': 'QuangTri',    'l': 'Quảng Trị',            'r': 'central'},
    {'v': 'HaTinh',      'l': 'Hà Tĩnh',              'r': 'central'},
    {'v': 'NghAn',       'l': 'Nghệ An',              'r': 'central'},
    {'v': 'ThanhHoa',    'l': 'Thanh Hóa',            'r': 'central'},
    // Tây Nguyên
    {'v': 'DakLak',      'l': 'Đắk Lắk',              'r': 'highland'},
    {'v': 'DakNong',     'l': 'Đắk Nông',             'r': 'highland'},
    {'v': 'GiaLai',      'l': 'Gia Lai',              'r': 'highland'},
    {'v': 'KonTum',      'l': 'Kon Tum',              'r': 'highland'},
    {'v': 'LamDong',     'l': 'Lâm Đồng',             'r': 'highland'},
    // Miền Bắc
    {'v': 'Hanoi',       'l': 'Hà Nội',               'r': 'north'},
    {'v': 'HaiPhong',    'l': 'Hải Phòng',            'r': 'north'},
    {'v': 'QuangNinh',   'l': 'Quảng Ninh',           'r': 'north'},
    {'v': 'HaiDuong',    'l': 'Hải Dương',            'r': 'north'},
    {'v': 'HungYen',     'l': 'Hưng Yên',             'r': 'north'},
    {'v': 'ThaiBinh',    'l': 'Thái Bình',            'r': 'north'},
    {'v': 'NamDinh',     'l': 'Nam Định',             'r': 'north'},
    {'v': 'NinhBinh',    'l': 'Ninh Bình',            'r': 'north'},
    {'v': 'HaNam',       'l': 'Hà Nam',               'r': 'north'},
    {'v': 'VinhPhuc',    'l': 'Vĩnh Phúc',            'r': 'north'},
    {'v': 'BacNinh',     'l': 'Bắc Ninh',             'r': 'north'},
    {'v': 'PhuTho',      'l': 'Phú Thọ',              'r': 'north'},
    {'v': 'TuyenQuang',  'l': 'Tuyên Quang',          'r': 'north'},
    {'v': 'YenBai',      'l': 'Yên Bái',              'r': 'north'},
    {'v': 'LaoC ai',     'l': 'Lào Cai',              'r': 'north'},
    {'v': 'HaGiang',     'l': 'Hà Giang',             'r': 'north'},
    {'v': 'CaoBang',     'l': 'Cao Bằng',             'r': 'north'},
    {'v': 'BacKan',      'l': 'Bắc Kạn',              'r': 'north'},
    {'v': 'LangSon',     'l': 'Lạng Sơn',             'r': 'north'},
    {'v': 'ThaiNguyen',  'l': 'Thái Nguyên',          'r': 'north'},
    {'v': 'BacGiang',    'l': 'Bắc Giang',            'r': 'north'},
    {'v': 'SonLa',       'l': 'Sơn La',               'r': 'north'},
    {'v': 'HoaBinh',     'l': 'Hòa Bình',             'r': 'north'},
    {'v': 'DienbienPhu', 'l': 'Điện Biên',            'r': 'north'},
    {'v': 'LaiChau',     'l': 'Lai Châu',             'r': 'north'},
    {'v': 'HaNam',       'l': 'Hà Nam',               'r': 'north'},
  ];

  static const regionLabels = {
    'south':    '🌴 Miền Nam',
    'central':  '🌊 Miền Trung',
    'highland': '⛰️ Tây Nguyên',
    'north':    '❄️ Miền Bắc',
  };

  // ── Tình trạng chỗ ở (thêm Lưu xá, Không có nhà) ────────
  static const livingStatuses = [
    {'v': 'WithFamily',  'i': '👨‍👩‍👧', 'l': 'Ở cùng gia đình'},
    {'v': 'Renting',     'i': '🏠',    'l': 'Thuê nhà/phòng trọ'},
    {'v': 'OwnHouse',    'i': '🔑',    'l': 'Có nhà riêng'},
    {'v': 'Dormitory',   'i': '🏫',    'l': 'Ký túc xá / Lưu xá'},
    {'v': 'Boarding',    'i': '🛏️',   'l': 'Nhà trọ sinh viên'},
    {'v': 'NoHouse',     'i': '🏕️',   'l': 'Chưa có nhà ở cố định'},
  ];

  // ── Mục tiêu tài chính (multi-select) ────────────────────
  static const savingGoals = [
    {'v': 'Emergency', 'i': '🛡️', 'l': 'Quỹ khẩn cấp'},
    {'v': 'BuyHouse',  'i': '🏠',  'l': 'Mua nhà'},
    {'v': 'BuyCar',    'i': '🚗',  'l': 'Mua xe'},
    {'v': 'Travel',    'i': '✈️',  'l': 'Du lịch'},
    {'v': 'Invest',    'i': '📈',  'l': 'Đầu tư'},
    {'v': 'Retire',    'i': '🏖️', 'l': 'Hưu trí sớm'},
    {'v': 'Education', 'i': '🎓',  'l': 'Học tập / Du học'},
    {'v': 'Wedding',   'i': '💍',  'l': 'Đám cưới'},
    {'v': 'Business',  'i': '💼',  'l': 'Khởi nghiệp'},
    {'v': 'Health',    'i': '💊',  'l': 'Quỹ y tế'},
  ];

  // Income stability options
  static const incomeStabilities = [
    {'v': 'Stable',   'i': '📈', 'l': 'Ổn định\n(lương cố định)'},
    {'v': 'Unstable', 'i': '📉', 'l': 'Không ổn định\n(theo dự án)'},
    {'v': 'Mixed',    'i': '↕️', 'l': 'Hỗn hợp\n(lương + thêm)'},
    {'v': 'None',     'i': '🎓', 'l': 'Chưa có\n(sinh viên)'},
  ];

  static const incomeSources = [
    'Lương chính', 'Freelance', 'Kinh doanh',
    'Đầu tư', 'Trợ cấp gia đình', 'Học bổng', 'Cho thuê tài sản',
  ];

  static const ageRanges = [
    {'v': '<22',   'l': 'Dưới 22'},
    {'v': '22-30', 'l': '22 - 30'},
    {'v': '31-40', 'l': '31 - 40'},
    {'v': '40+',   'l': 'Trên 40'},
  ];

  static const maritalStatuses = [
    {'v': 'Single',   'l': 'Độc thân'},
    {'v': 'Married',  'l': 'Đã kết hôn'},
    {'v': 'Divorced', 'l': 'Đã ly hôn'},
  ];

  // Helper: city name from value
  static String cityName(String v) {
    for (final p in provinces) {
      if (p['v'] == v) return p['l']!;
    }
    return v;
  }

  // Helper: occupation label from value
  static String occupationLabel(String v, String customOccupation) {
    if (v == 'Other') return customOccupation.isEmpty ? 'Khác' : customOccupation;
    for (final o in occupations) {
      if (o['v'] == v) return o['l']!;
    }
    return v;
  }
}