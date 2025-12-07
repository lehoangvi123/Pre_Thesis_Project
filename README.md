Pre_Thesis_Project 🚀

Smart Personal Expense Tracker with AI-based Financial Insights

📄 Giới thiệu

Pre_Thesis_Project là một ứng dụng quản lý chi tiêu cá nhân được phát triển bằng Flutter, nhằm giúp người dùng:

Ghi lại thu nhập – chi tiêu, phân loại theo danh mục (category)

Phân tích và trực quan hóa chi tiêu bằng biểu đồ (pie chart, line chart …)

(Trong tương lai) Tích hợp module AI để đưa ra lời khuyên tiết kiệm, dự đoán xu hướng chi tiêu

Ứng dụng là phần của đồ án tốt nghiệp — kết hợp công nghệ mobile cross-platform, Firebase backend, và AI cho Fintech cá nhân.

🧰 Tech Stack

Flutter (Dart)

Backend: Firebase (Auth, Firestore, Storage, Messaging)

State management: Provider / Riverpod

UI & Charts: fl_chart

(Có thể) AI Integration: OpenAI API / Google Gemini

🚀 Cách cài đặt & chạy ứng dụng
1. Chuẩn bị môi trường

Cài Flutter SDK theo hướng dẫn chính thức từ Flutter. 
Google Codelabs
+1

Cài VS Code + plugin Dart & Flutter

Cài Android Studio + Android Emulator (hoặc dùng thiết bị thật) để chạy app Android 
simplyflutter.hashnode.dev
+1

2. Clone project
git clone https://github.com/lehoangvi123/Pre_Thesis_Project.git
cd Pre_Thesis_Project

3. Cài dependencies
flutter pub get


Lệnh này sẽ tải tất cả package cần thiết được khai báo trong pubspec.yaml. 
Medium
+1

4. Khởi động Android Emulator

Mở Android Studio → Device Manager → chọn hoặc tạo Virtual Device (ví dụ: Pixel 5 + Android 13) → nhấn Run để khởi động emulator. 
simplyflutter.hashnode.dev
+1

Hoặc trong VS Code, mở Command Palette → “Flutter: Launch Emulator” → chọn emulator để chạy. 
Medium
+1

5. Chạy ứng dụng

Trong VS Code:

Mở dự án — chắc chắn bạn đang ở thư mục root (nơi chứa pubspec.yaml)

Ở thanh chọn thiết bị (device selector) → chọn emulator hoặc thiết bị thật

Nhấn F5 hoặc vào Run → Start Debugging

Hoặc bạn có thể chạy từ terminal:

flutter run


Nếu mọi thứ đúng, app sẽ được build và chạy trong emulator / device. 
Medium
+1

6. Một số lệnh hữu ích khi phát triển

Hot reload: khi chỉnh UI / layout → giúp thay đổi nhanh mà không restart app hoàn toàn

flutter clean: khi gặp lỗi build/gradle hoặc muốn build sạch lại → sau đó chạy flutter pub get → flutter run lại. Việc này thường giúp khắc phục lỗi.
