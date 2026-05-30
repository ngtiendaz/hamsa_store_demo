# PLAN.md — Kế hoạch phát triển dự án Hamsa Store Demo (5 Module)

Tài liệu này chứa kế hoạch chi tiết và checklist các công việc từ đầu đến cuối để xây dựng dự án **Hamsa Store Demo**. Kế hoạch tập trung chính xác vào 5 module được yêu cầu và tuân thủ các quy tắc trong [RULE.md](file:///Users/macbook/Code/Hamsa/hamsa_store_demo/rule.md).

---

## 📂 Danh sách các file dự kiến trong dự án

Dưới đây là cấu trúc thư mục và danh sách các file sẽ được tạo/sửa đổi:

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   │   └── supabase_config.dart          # Cấu hình Supabase (URL & Anon Key)
│   ├── services/
│   │   ├── supabase_service.dart         # Service quản lý Supabase client
│   │   └── storage_service.dart          # Service upload file (avatar)
│   ├── router/
│   │   ├── app_router.dart               # Định tuyến tập trung (GoRouter)
│   │   └── route_guard.dart              # Guard kiểm tra auth và check role
│   ├── constants/
│   │   ├── app_constants.dart            # Hằng số toàn ứng dụng
│   │   ├── app_routes.dart               # Định nghĩa các route name/path
│   │   └── app_enums.dart                # Enum trạng thái, vai trò
│   ├── theme/
│   │   ├── app_theme.dart                # Theme chung cho app
│   │   ├── app_colors.dart               # Bảng màu
│   │   └── app_text_styles.dart          # Font chữ & Text style
│   ├── widgets/
│   │   ├── app_button.dart               # Custom Button dùng chung
│   │   ├── app_text_field.dart           # Custom TextField dùng chung
│   │   ├── app_table.dart                # Widget Table dùng chung
│   │   ├── app_dialog.dart               # Widget Dialog hiển thị thông báo/xác nhận
│   │   ├── app_loading.dart              # Widget loading trạng thái
│   │   ├── app_empty_state.dart          # Widget hiển thị khi danh sách trống
│   │   └── app_error_state.dart          # Widget hiển thị lỗi
│   └── layout/
│       ├── main_layout.dart              # Layout chính có Sidebar/Drawer & AppBar
│       └── responsive_layout.dart        # Helper xây dựng giao diện Responsive
│
├── data/
│   ├── models/
│   │   ├── profiles_model.dart           # Model tài khoản người dùng
│   │   ├── products_model.dart           # Model sản phẩm
│   │   ├── cart_model.dart               # Model giỏ hàng
│   │   ├── cart_item_model.dart          # Model chi tiết item trong giỏ hàng
│   │   ├── order_model.dart              # Model đơn hàng
│   │   └── order_item_model.dart         # Model chi tiết đơn hàng
│   └── dto/
│       └── pagination_result.dart        # DTO đóng gói dữ liệu phân trang
│
└── features/
    ├── admin/
    │   ├── users/
    │   │   ├── repository/
    │   │   │   └── admin_user_repository.dart
    │   │   ├── viewmodel/
    │   │   │   ├── admin_user_list_view_model.dart
    │   │   │   └── admin_user_form_view_model.dart
    │   │   └── view/
    │   │       ├── admin_user_list_view.dart
    │   │       └── admin_user_form_view.dart
    │   │
    │   ├── products/
    │   │   ├── repository/
    │   │   │   └── admin_product_repository.dart
    │   │   ├── viewmodel/
    │   │   │   ├── product_list_view_model.dart
    │   │   │   └── product_form_view_model.dart
    │   │   └── view/
    │   │       ├── product_list_view.dart
    │   │       └── product_form_view.dart
    │   │
    │   └── orders/
    │       ├── repository/
    │       │   └── admin_order_repository.dart
    │       ├── viewmodel/
    │       │   ├── order_list_view_model.dart
    │       │   ├── order_detail_view_model.dart
    │       │   └── order_create_view_model.dart
    │       └── view/
    │           ├── order_list_view.dart
    │           ├── order_detail_view.dart
    │           └── order_create_view.dart
    │
    └── user/
        ├── auth/
        │   ├── repository/
        │   │   └── auth_repository.dart
        │   ├── viewmodel/
        │   │   ├── login_view_model.dart
        │   │   └── forgot_password_view_model.dart
        │   └── view/
        │       ├── login_view.dart
        │       └── forgot_password_view.dart
        │
        └── profile/
            ├── repository/
            │   └── profile_repository.dart
            ├── viewmodel/
            │   ├── profile_view_model.dart
            │   └── change_password_view_model.dart
            └── view/
                ├── profile_view.dart
                └── change_password_view.dart
```

---

## 📝 CHECKLIST CHI TIẾT CÁC BƯỚC THỰC HIỆN

### PHASE 1: Khởi tạo dự án & Cài đặt thư viện
- [x] 1.0. Tạo cấu trúc thư mục và các file khung theo thiết kế.
- [x] 1.1. Cập nhật `pubspec.yaml` để thêm các thư viện cần thiết:
  - `supabase_flutter` (kết nối Supabase)
  - `provider` (quản lý state)
  - `go_router` (định tuyến và route guard)
  - `intl` (format tiền tệ, ngày tháng)
  - `cached_network_image` (load ảnh avatar/sản phẩm)
  - `image_picker` (chọn ảnh upload)
- [x] 1.2. Chạy lệnh cài đặt: `flutter pub get`
- [x] 1.3. Cấu hình Supabase Service & Config:
  - Tạo `supabase_config.dart` chứa URL và Anon Key
  - Tạo `supabase_service.dart` khởi tạo client kết nối

### PHASE 2: Xây dựng các Core Models & DTOs
- [x] 2.1. Xây dựng `profiles_model.dart` chứa thông tin người dùng từ bảng `profiles`.
  - Có các helper: `isAdmin`, `isEmployee`, `isCustomer`.
- [x] 2.2. Xây dựng `products_model.dart` chứa thông tin sản phẩm (internal_name, trade_name, price, stock, status).
- [x] 2.3. Xây dựng `cart_item_model.dart` và `cart_model.dart` hỗ trợ giỏ hàng.
- [x] 2.4. Xây dựng `order_model.dart` và `order_item_model.dart` chứa thông tin đơn hàng và snapshot sản phẩm.
- [x] 2.5. Xây dựng `pagination_result.dart` để tái sử dụng cấu trúc phân trang.

### PHASE 3: Module 1 — Auth & User Management (Phần Đăng nhập/Đăng xuất)
- [x] 3.1. Viết `AuthRepository` giao tiếp với Supabase Auth.
- [x] 3.2. Viết `LoginViewModel` xử lý logic login.
- [x] 3.3. Thiết kế `LoginView` cho phép nhập email/password.
  - Kiểm tra `is_active` của profile sau đăng nhập. Nếu `is_active = false` thì đăng xuất ngay và báo lỗi "Tài khoản đã bị vô hiệu hóa".
- [ ] 3.4. Viết `ForgotPasswordViewModel` và thiết kế `ForgotPasswordView` (gửi mail reset password - optional).
- [ ] 3.5. Xử lý chức năng Logout (xóa session và clear profile state).

### PHASE 4: Module 2 — Phân quyền & Navigation
- [x] 4.1. Xây dựng `RouteGuard` để chặn truy cập trái phép ở cấp router (dựa vào role và trạng thái active).
- [x] 4.2. Cấu hình `AppRouter` sử dụng `GoRouter` để định vị tất cả các trang và gắn Guard.
- [x] 4.3. Thiết kế `MainLayout`:
  - Nhận `userRole` hiện tại từ Auth state.
  - Ẩn/hiển thị menu tương ứng:
    - `admin`: hiển thị Dashboard (nếu có), Quản lý user, Quản lý sản phẩm, Quản lý đơn hàng, Trang cá nhân.
    - `employee`: hiển thị Quản lý sản phẩm (read-only), Quản lý đơn hàng, Trang cá nhân (Ẩn menu Quản lý user).
  - Hỗ trợ responsive: Desktop dùng Sidebar, Mobile dùng Drawer/Bottom Navigation.

### PHASE 5: Module 1 — Admin User Management (Quản lý User)
- [ ] 5.1. Viết `AdminUserRepository` truy vấn, lọc, sửa thông tin trong bảng `profiles`.
- [ ] 5.2. Viết `AdminUserListViewModel` xử lý load danh sách, tìm kiếm và phân trang user.
- [ ] 5.3. Thiết kế `AdminUserListView` (chỉ `admin` truy cập):
  - Hiển thị danh sách user dạng table.
  - Bộ tìm kiếm theo tên hoặc email.
  - Bộ lọc trạng thái hoạt động (`is_active`) và phân quyền (`role`).
- [ ] 5.4. Viết `AdminUserFormViewModel` & thiết kế `AdminUserFormView`:
  - Form thêm user (hướng dẫn tạo Auth bằng Supabase Console, đồng bộ tạo profile mới bằng cách cập nhật).
  - Form sửa thông tin: `name`, `phone`, `role`, `is_active`.
  - Không cho sửa email.
  - Vô hiệu hóa người dùng bằng cách gán `is_active = false` (không xóa cứng Auth).

### PHASE 6: Module 3 — Quản lý sản phẩm (Product Management)
- [x] 6.1. Viết `AdminProductRepository` thực hiện các thao tác CRUD sản phẩm.
- [x] 6.2. Viết `ProductListViewModel` xử lý logic tìm kiếm, phân trang và tải danh sách sản phẩm.
- [x] 6.3. Thiết kế `ProductListView`:
  - Danh sách sản phẩm phân trang (20 sản phẩm/trang).
  - Ô tìm kiếm theo tên sản phẩm hoặc barcode.
  - Phân quyền hiển thị:
    - `admin`: hiển thị các nút Thêm mới, Sửa, Xóa mềm (chuyển `status = inactive`).
    - `employee`: **chỉ xem** danh sách và chi tiết, ẩn toàn bộ nút thêm/sửa/xóa.
- [x] 6.4. Viết `ProductFormViewModel` & thiết kế `ProductFormView`:
  - Form thêm/sửa sản phẩm gồm các trường: Tên nội bộ (bắt buộc), Tên thương mại, Barcode, Giá, Tồn kho, Trạng thái.
  - Validate form: Tên nội bộ bắt buộc, Giá >= 0, Tồn kho >= 0.

### PHASE 6.5: Module — Quản lý Danh mục & Nhãn hàng (Category & Brand Management)
- [ ] 6.5.1. Viết `AdminCategoryRepository` thực hiện CRUD danh mục với logic re-route về "Khác" khi xóa.
- [ ] 6.5.2. Viết `CategoryListViewModel` và `CategoryFormViewModel`.
- [ ] 6.5.3. Thiết kế `CategoryListView` và `CategoryFormView` (giao diện tương tự Quản lý sản phẩm).
- [ ] 6.5.4. Viết `AdminBrandRepository` thực hiện CRUD nhãn hàng với logic re-route về "Khác" khi xóa.
- [ ] 6.5.5. Viết `BrandListViewModel` và `BrandFormViewModel`.
- [ ] 6.5.6. Thiết kế `BrandListView` và `BrandFormView` (giao diện tương tự Quản lý sản phẩm).
- [ ] 6.5.7. Đăng ký router và cấu hình route cho Category & Brand trong `app_router.dart`.

### PHASE 7: Module 4 — Quản lý đơn hàng (Order Management)
- [ ] 7.1. Viết `AdminOrderRepository` tương tác với bảng `orders` và `order_items`.
- [ ] 7.2. Xây dựng logic tạo đơn hàng (`OrderCreateViewModel` & `OrderCreateView`):
  - Cho phép thêm sản phẩm vào giỏ hàng.
  - Chọn khách hàng (hoặc dùng tài khoản mặc định `retail_customer`).
  - Tính tổng tiền đơn hàng tự động.
  - Cho phép nhập ghi chú đơn hàng.
  - Thực hiện trừ tồn kho sản phẩm tương ứng và tạo đơn hàng bằng transaction (hoặc RPC/Database trigger để đảm bảo an toàn).
- [ ] 7.3. Viết `OrderListViewModel` & thiết kế `OrderListView`:
  - Tìm kiếm đơn hàng theo mã đơn (`order_code`) hoặc tên khách hàng.
  - Bộ lọc đơn hàng theo trạng thái và khoảng thời gian.
- [ ] 7.4. Viết `OrderDetailViewModel` & thiết kế `OrderDetailView` hiển thị chi tiết đơn hàng (thông tin KH, các sản phẩm kèm giá snapshot, ghi chú, trạng thái).
- [ ] 7.5. Xử lý chức năng Hủy đơn hàng:
  - Chỉ cho phép hủy khi đơn hàng ở trạng thái `pending_confirmation`.
  - Khi hủy đơn, cập nhật trạng thái đơn thành `cancelled`, đồng thời cộng lại số lượng tồn kho cho các sản phẩm trong đơn hàng.

### PHASE 8: Module 5 — Trang cá nhân (Profile)
- [ ] 8.1. Viết `ProfileRepository` để cập nhật dữ liệu của user hiện tại.
- [ ] 8.2. Viết `ProfileViewModel` & thiết kế `ProfileView`:
  - Hiển thị email (read-only), role (read-only).
  - Cho phép sửa: tên, số điện thoại, avatar (tải ảnh lên Supabase Storage hoặc nhập link URL văn bản).
  - Không cho phép người dùng tự đổi role của chính mình.
- [ ] 8.3. Viết `ChangePasswordViewModel` & thiết kế `ChangePasswordView`:
  - Đổi mật khẩu thông qua hàm `updatePassword` của Supabase Auth.
  - Validate mật khẩu mới >= 6 ký tự và xác nhận mật khẩu phải khớp.

### PHASE 9: Polish UI & Test luồng (Final Review)
- [ ] 9.1. Tạo bộ widget dùng chung (`AppButton`, `AppTextField`, `AppTable`, `LoadingWidget`, `ErrorStateWidget`, `EmptyStateWidget`).
- [ ] 9.2. Chuẩn hóa hiển thị trạng thái và nhãn bằng tiếng Việt.
- [ ] 9.3. Viết và chạy seed data test trên database Supabase để có sẵn dữ liệu demo.
- [ ] 9.4. Kiểm tra toàn bộ luồng nghiệp vụ trên cả giao diện Web và Mobile.
- [ ] 9.5. Tạo file báo cáo kết quả kiểm thử `walkthrough.md`.
- [x] 9.6. Polish responsive UI app:
  - Đưa nút `Ngừng bán` và `Cập nhật` xuống cuối form chi tiết sản phẩm trên mobile, cho phép co giãn theo chiều rộng màn hình.
  - Lược bỏ trạng thái hoạt động khỏi giao diện quản lý nhãn hàng.
  - Thu gọn nút thêm mới trên mobile của danh mục và nhãn hàng để giao diện đồng nhất.
  - Đưa nút `Xóa` và `Cập nhật` xuống cuối form chi tiết danh mục, nhãn hàng trên mobile; sửa hàng trạng thái danh mục không overflow.
  - Thêm viền mặc định cho text field của danh mục, nhãn hàng; dãn đều nút thêm mới trên mobile và cố định chiều cao card kèm ellipsis.

---

## 🚦 Quy tắc cập nhật checklist
- Sau khi hoàn thành bất kỳ bước nào trong checklist này, AI sẽ cập nhật ký tự `[ ]` thành `[x]` để theo dõi tiến độ.
- Nếu có bất kỳ điều chỉnh hoặc thêm bớt tính năng nào, AI phải sửa đổi nội dung checklist này ngay lập tức.
