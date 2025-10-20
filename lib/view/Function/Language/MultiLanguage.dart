import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // HomeView
      'hi_welcome_back': 'Hi, Welcome Back',
      'total_balance': 'Total Balance',
      'total_expenses': 'Total Expenses',
      'expenses_looks_good': '30% Of Your Expenses, Looks Good',
      'on_goals': 'On Goals',
      'groceries_last_week': 'Groceries Last Week',
      'food_last_week': 'Food Last Week',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'year': 'Year',
      'salary': 'Salary',
      'groceries': 'Groceries',
      'rent': 'Rent',
      'transport': 'Transport',
      'food': 'Food',
      
      // AnalysisView
      'analysis': 'Analysis',
      'view_financial_insights': 'View your financial insights',
      'income_expenses': 'Income & Expenses',
      'income': 'Income',
      'expense': 'Expense',
      'my_targets': 'My Targets',
      'shopping_budget': 'Shopping Budget',
      'food_budget': 'Food Budget',
      'travel_budget': 'Travel Budget',
      
      // TransactionView
      'transaction': 'Transaction',
      'track_spending': 'Track your spending',
      'april': 'April',
      'march': 'March',
      'monthly_label': 'Monthly',
      'pantry': 'Pantry',
      'fuel': 'Fuel',
      'dinner': 'Dinner',
      
      // CategoriesView
      'categories': 'Categories',
      'manage_categories': 'Manage your expense categories',
      'medicine': 'Medicine',
      'gifts': 'Gifts',
      'savings': 'Savings',
      'entertainment': 'Entertainment',
      'more': 'More',
      
      // SettingsView
      'settings': 'Settings',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'receive_app_notifications': 'Receive app notifications',
      'email_notifications': 'Email Notifications',
      'receive_email_updates': 'Receive email updates',
      'budget_alerts': 'Budget Alerts',
      'budget_limit_reached': 'Get notified when budget limit is reached',
      'expense_reminders': 'Expense Reminders',
      'daily_reminders': 'Daily reminders to log expenses',
      'display': 'Display',
      'dark_mode': 'Dark Mode',
      'use_dark_theme': 'Use dark theme',
      'language': 'Language',
      'choose_language': 'Choose your preferred language',
      'about': 'About',
      'app_version': 'App Version',
      'about_us': 'About Us',
      'terms_conditions': 'Terms & Conditions',
      'read_terms': 'Read our terms of service',
      'privacy_policy': 'Privacy Policy',
      'view_privacy': 'View privacy policy',
      
      // ProfileView
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'security': 'Security',
      'converting_currency': 'Converting Currency',
      'help': 'Help',
      'logout': 'Logout',
      'are_you_sure_logout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'ok': 'Ok',
      
      // LoginView
      'welcome_back': 'Welcome Back',
      'login_to_account': 'Login to your account',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'log_in': 'Log In',
      'or_continue_with': 'Or continue with',
      'google': 'Google',
      'facebook': 'Facebook',
      'dont_have_account': 'Don\'t have an account? ',
      'sign_up': 'Sign Up',
    },
    'vi': {
      // HomeView
      'hi_welcome_back': 'Xin chào, Chào mừng bạn quay lại',
      'total_balance': 'Tổng số dư',
      'total_expenses': 'Tổng chi tiêu',
      'expenses_looks_good': '30% Chi tiêu của bạn, Có vẻ tốt',
      'on_goals': 'Theo mục tiêu',
      'groceries_last_week': 'Hàng tạp hóa tuần trước',
      'food_last_week': 'Thức ăn tuần trước',
      'daily': 'Hàng ngày',
      'weekly': 'Hàng tuần',
      'monthly': 'Hàng tháng',
      'year': 'Năm',
      'salary': 'Lương',
      'groceries': 'Hàng tạp hóa',
      'rent': 'Tiền thuê',
      'transport': 'Vận chuyển',
      'food': 'Thức ăn',
      
      // AnalysisView
      'analysis': 'Phân tích',
      'view_financial_insights': 'Xem thông tin tài chính của bạn',
      'income_expenses': 'Thu nhập và Chi tiêu',
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'my_targets': 'Mục tiêu của tôi',
      'shopping_budget': 'Ngân sách mua sắm',
      'food_budget': 'Ngân sách thức ăn',
      'travel_budget': 'Ngân sách du lịch',
      
      // TransactionView
      'transaction': 'Giao dịch',
      'track_spending': 'Theo dõi chi tiêu của bạn',
      'april': 'Tháng Tư',
      'march': 'Tháng Ba',
      'monthly_label': 'Hàng tháng',
      'pantry': 'Tủ',
      'fuel': 'Nhiên liệu',
      'dinner': 'Bữa tối',
      
      // CategoriesView
      'categories': 'Danh mục',
      'manage_categories': 'Quản lý danh mục chi tiêu của bạn',
      'medicine': 'Thuốc',
      'gifts': 'Quà tặng',
      'savings': 'Tiết kiệm',
      'entertainment': 'Giải trí',
      'more': 'Thêm',
      
      // SettingsView
      'settings': 'Cài đặt',
      'notifications': 'Thông báo',
      'push_notifications': 'Thông báo đẩy',
      'receive_app_notifications': 'Nhận thông báo từ ứng dụng',
      'email_notifications': 'Thông báo email',
      'receive_email_updates': 'Nhận cập nhật qua email',
      'budget_alerts': 'Cảnh báo ngân sách',
      'budget_limit_reached': 'Nhận cảnh báo khi đạt giới hạn ngân sách',
      'expense_reminders': 'Nhắc nhở chi tiêu',
      'daily_reminders': 'Nhắc nhở hàng ngày ghi lại chi tiêu',
      'display': 'Hiển thị',
      'dark_mode': 'Chế độ tối',
      'use_dark_theme': 'Sử dụng giao diện tối',
      'language': 'Ngôn ngữ',
      'choose_language': 'Chọn ngôn ngữ ưa thích',
      'about': 'Giới thiệu',
      'app_version': 'Phiên bản ứng dụng',
      'about_us': 'Giới thiệu về chúng tôi',
      'terms_conditions': 'Điều khoản & Điều kiện',
      'read_terms': 'Đọc điều khoản dịch vụ của chúng tôi',
      'privacy_policy': 'Chính sách bảo mật',
      'view_privacy': 'Xem chính sách bảo mật',
      
      // ProfileView
      'profile': 'Hồ sơ',
      'edit_profile': 'Chỉnh sửa hồ sơ',
      'security': 'Bảo mật',
      'converting_currency': 'Chuyển đổi tiền tệ',
      'help': 'Trợ giúp',
      'logout': 'Đăng xuất',
      'are_you_sure_logout': 'Bạn có chắc chắn muốn đăng xuất không?',
      'cancel': 'Hủy',
      'ok': 'Được',
      
      // LoginView
      'welcome_back': 'Chào mừng quay lại',
      'login_to_account': 'Đăng nhập vào tài khoản của bạn',
      'email': 'Email',
      'password': 'Mật khẩu',
      'forgot_password': 'Quên mật khẩu?',
      'log_in': 'Đăng nhập',
      'or_continue_with': 'Hoặc tiếp tục với',
      'google': 'Google',
      'facebook': 'Facebook',
      'dont_have_account': 'Bạn chưa có tài khoản? ',
      'sign_up': 'Đăng ký',
    },
  };

  static String currentLanguage = 'en';

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLanguage = prefs.getString('selected_language') ?? 'en';
  }

  static Future<void> setLanguage(String languageCode) async {
    currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
  }

  static String translate(String key) {
    return _translations[currentLanguage]?[key] ?? _translations['en']?[key] ?? key;
  }

  static String get(String key) => translate(key);
}