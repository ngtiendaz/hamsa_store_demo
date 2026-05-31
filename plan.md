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

### PHASE 3: Module 1 — Auth & User Management (Phần Đăng nhập/Đăng xuất & Đăng ký)
- [x] 3.1. Viết `AuthRepository` giao tiếp với Supabase Auth.
- [x] 3.2. Viết `LoginViewModel` xử lý logic login.
- [x] 3.3. Thiết kế lại `LoginView` đẹp mắt hơn, hỗ trợ:
  - Checkbox "Ghi nhớ đăng nhập" (lưu token session).
  - Hiển thị danh sách tối đa 3 tài khoản đã đăng nhập gần đây.
  - Nút dẫn tới màn hình Đăng ký.
- [x] 3.4. Thêm chức năng đăng ký cho khách hàng:
  - Cập nhật `AuthRepository` và `AuthViewModel` hỗ trợ đăng ký.
  - Tạo `RegisterViewModel` và màn hình `RegisterView` (email, mật khẩu, xác nhận mật khẩu).
  - Tự động gán role `'customer'` và tạo hồ sơ profile sau khi đăng ký thành công.
- [ ] 3.5. Viết `ForgotPasswordViewModel` và thiết kế `ForgotPasswordView` (gửi mail reset password - optional).
- [ ] 3.6. Xử lý chức năng Logout (xóa session và clear profile state).

### PHASE 4: Module 2 — Phân quyền & Navigation
- [x] 4.1. Xây dựng `RouteGuard` để chặn truy cập trái phép ở cấp router (dựa vào role và trạng thái active).
- [x] 4.2. Cấu hình `AppRouter` sử dụng `GoRouter` để định vị tất cả các trang và gắn Guard.
- [x] 4.3. Thiết kế `MainLayout`:
  - Nhận `userRole` hiện tại từ Auth state.
  - Ẩn/hiển thị menu tương ứng:
    - `admin`: hiển thị Dashboard (nếu có), Quản lý user, Quản lý sản phẩm, Quản lý đơn hàng, Trang cá nhân.
    - `employee`: hiển thị Quản lý sản phẩm (read-only), Quản lý đơn hàng, Trang cá nhân (Ẩn menu Quản lý user).
  - Hỗ trợ responsive: Desktop dùng Sidebar, Mobile dùng Drawer/Bottom Navigation.

### PHASE 5: Module 1 — Admin User Management (Quản lý Người dùng)
- [x] 5.1. Viết `AdminUserRepository` truy vấn, lọc, sửa thông tin trong bảng `profiles` (không lọc bỏ vai trò customer).
- [x] 5.2. Viết `AdminUserListViewModel` xử lý load danh sách, tìm kiếm và phân trang người dùng (sửa thông báo tiếng Việt thành người dùng).
- [x] 5.3. Thiết kế `AdminUserListView` (chỉ `admin` truy cập):
  - Hiển thị danh sách người dùng dạng table.
  - Bộ tìm kiếm theo tên hoặc email.
  - Bộ lọc trạng thái hoạt động (`is_active`) và phân quyền (`role`, bao gồm lọc Khách hàng).
- [x] 5.4. Viết `AdminUserFormViewModel` & thiết kế `AdminUserFormView`:
  - Form thêm người dùng gọi Edge Function `admin-create-user` để tạo Supabase Auth và đồng bộ profile.
  - Mặc định người dùng nội bộ mới là `employee`; checkbox quản trị viên mới chuyển thành `admin`; không cho tạo `customer`.
  - Form sửa thông tin: `name`, `phone`, `role`, `is_active`.
  - Không cho sửa email.
  - Vô hiệu hóa người dùng bằng thao tác xóa mềm `is_active = false` (không xóa cứng Auth).
  - Không cho admin tự hạ quyền hoặc tự vô hiệu hóa chính mình trên giao diện.
  - Giao diện chi tiết dùng dropdown trạng thái; danh sách chỉ giữ nút sửa và hiển thị avatar lớn hơn, không có divider giữa các dòng.
  - Tùy chỉnh chi tiết đối với tài khoản Khách hàng (customer): chuyển Tên và Số điện thoại sang read-only, ẩn checkbox "Quyền quản trị viên", chỉ cho phép sửa trạng thái tài khoản.
  - Đồng bộ nhãn giao diện admin sang "Người dùng".

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
  - Validate form: Tên nội bộ và tên thương mại bắt buộc, giá > 0, tồn kho > 0.
  - Database vẫn cho phép tồn kho về `0` sau khi bán hết; điều kiện tồn kho `> 0` áp dụng khi admin lưu form sản phẩm.
  - Khi xóa sản phẩm: xóa cứng nếu chưa có dữ liệu liên quan; nếu đã nằm trong giỏ hàng, đơn hàng hoặc lịch sử tồn kho thì chỉ chuyển trạng thái `inactive`.

### PHASE 6.5: Module — Quản lý Danh mục & Nhãn hàng (Category & Brand Management)
- [x] 6.5.1. Viết `AdminCategoryRepository` thực hiện CRUD danh mục với logic re-route sản phẩm liên quan về "Khác" khi xóa.
- [ ] 6.5.2. Viết `CategoryListViewModel` và `CategoryFormViewModel`.
- [ ] 6.5.3. Thiết kế `CategoryListView` và `CategoryFormView` (giao diện tương tự Quản lý sản phẩm).
- [x] 6.5.4. Viết `AdminBrandRepository` thực hiện CRUD nhãn hàng với logic re-route sản phẩm liên quan về "Khác" khi xóa.
  - Xóa danh mục và nhãn hàng qua RPC transaction để chuyển toàn bộ sản phẩm liên quan về bản ghi `Khác` trước khi xóa.
- [ ] 6.5.5. Viết `BrandListViewModel` và `BrandFormViewModel`.
- [ ] 6.5.6. Thiết kế `BrandListView` và `BrandFormView` (giao diện tương tự Quản lý sản phẩm).
- [ ] 6.5.7. Đăng ký router và cấu hình route cho Category & Brand trong `app_router.dart`.

### PHASE 7: Module 4 — Quản lý đơn hàng (Order Management)
- [x] 7.1. Viết `AdminOrderRepository` tương tác với bảng `orders` và `order_items`.
- [x] 7.2. Xây dựng logic tạo đơn hàng (`OrderCreateViewModel` & `OrderCreateView`):
  - Cho phép thêm sản phẩm vào giỏ hàng.
  - Chọn khách hàng (hoặc dùng tài khoản mặc định `retail_customer`).
  - Tính tổng tiền đơn hàng tự động.
  - Cho phép nhập ghi chú đơn hàng.
  - Thực hiện trừ tồn kho sản phẩm tương ứng và tạo đơn hàng bằng transaction (hoặc RPC/Database trigger để đảm bảo an toàn).
- [x] 7.3. Viết `OrderListViewModel` & thiết kế `OrderListView`:
  - Tìm kiếm đơn hàng theo mã đơn (`order_code`) hoặc tên khách hàng.
  - Bộ lọc đơn hàng theo trạng thái và khoảng thời gian (hỗ trợ chọn khoảng thời gian bằng DateRangePicker cho cả Admin, Employee và Customer).
  - Phân trang hiển thị (mặc định tải 20 đơn hàng đầu, hỗ trợ chuyển trang trước/sau với giao diện hiển thị số trang giống như Quản lý người dùng).
- [x] 7.4. Viết `OrderDetailViewModel` & thiết kế `OrderDetailView` hiển thị chi tiết đơn hàng (thông tin KH, các sản phẩm kèm giá snapshot, ghi chú, trạng thái).
- [x] 7.5. Xử lý chức năng Hủy đơn hàng:
  - Chỉ cho phép hủy khi đơn hàng ở trạng thái `pending_confirmation`.
  - Khi hủy đơn, cập nhật trạng thái đơn thành `cancelled`, đồng thời cộng lại số lượng tồn kho cho các sản phẩm trong đơn hàng.
  - Chuẩn hóa hiển thị thời gian đơn hàng theo múi giờ Việt Nam UTC+7 từ dữ liệu `timestamptz`.

### PHASE 8: Module 5 — Trang cá nhân (Profile)
- [x] 8.1. Viết `ProfileRepository` để cập nhật dữ liệu của user hiện tại.
- [x] 8.2. Viết `ProfileViewModel` & thiết kế `ProfileView`:
  - Hiển thị email (read-only), role (read-only).
  - Cho phép sửa: tên, số điện thoại, avatar (tải ảnh lên Supabase Storage hoặc nhập link URL văn bản).
  - Không cho phép người dùng tự đổi role của chính mình.
  - Dùng chung giao diện responsive cho customer và route profile nội bộ.
  - Tối ưu giao diện web toàn chiều rộng, căn trái nội dung và đưa vai trò lên gần tên người dùng.
  - Đổi nhãn customer `Profile` thành `Cá nhân`.
  - Thêm migration tạo bucket `avatars`, giới hạn loại ảnh và policy chỉ cho phép user ghi avatar của chính mình.
  - Thêm RLS policy cập nhật profile chính chủ và trigger chặn user tự sửa `email`, `role`, `is_active`.
  - Khắc phục cache avatar khi upload đè file: gắn version vào URL public, khai báo MIME type và tắt cache Storage cho file mới.
- [ ] 8.3. Viết `ChangePasswordViewModel` & thiết kế `ChangePasswordView`:
  - Đổi mật khẩu thông qua hàm `updatePassword` của Supabase Auth.
  - Validate mật khẩu mới >= 6 ký tự và xác nhận mật khẩu phải khớp.

### PHASE 8.5: Module — Ví điện tử HamsaPay (HamsaPay Wallet)
- [ ] 8.5.1. Tạo model `wallet_model.dart` và `wallet_transaction_model.dart` để ánh xạ ví và lịch sử giao dịch.
- [ ] 8.5.2. Cập nhật `ProfileRepository` các hàm lấy số dư ví, lấy lịch sử và nạp/rút tiền qua Postgres RPC.
- [ ] 8.5.3. Cập nhật `ProfileViewModel` quản lý trạng thái số dư ví, tải lịch sử và thực hiện nạp/rút.
- [ ] 8.5.4. Thiết kế `HamsapayCard` sang trọng hiển thị số dư, có nút nạp, rút và mở dialog lịch sử.
- [ ] 8.5.5. Thiết kế `WalletHistoryDialog` hiển thị lịch sử giao dịch của ví với phân loại trạng thái nạp, rút, thanh toán, hoàn tiền.
- [ ] 8.5.6. Tích hợp `HamsapayCard` vào `ProfileForm` trong trang Cá nhân.

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

### PHASE 10: Trang chủ Customer & Catalog
- [x] 10.1. Tạo `CustomerProductRepository` chỉ đọc sản phẩm đang hoạt động, hỗ trợ tìm kiếm, lọc danh mục, lọc nhãn hàng và phân trang.
- [x] 10.2. Tạo `CustomerHomeViewModel`, `CustomerProductDetailViewModel` và `CustomerCartViewModel` theo MVVM + Provider.
- [x] 10.3. Xây dựng `CustomerLayout` responsive:
  - App dùng bottom menu gồm Trang chủ, Giỏ hàng, Đơn hàng, Cá nhân.
  - Web dùng thanh điều hướng bên trái và vùng nội dung responsive.
- [x] 10.4. Xây dựng trang chủ customer:
  - Grid sản phẩm active, app hiển thị 2 card mỗi dòng.
  - Có tìm kiếm, bộ lọc danh mục, nhãn hàng.
  - Card hiển thị ảnh, tên, giá và nút thêm vào giỏ hàng.
  - Hiển thị thanh phân trang `Trước / Sau`, mỗi trang cố định 40 sản phẩm.
  - Toàn bộ vùng card, bao gồm ảnh sản phẩm trên web, có thể bấm để mở trang chi tiết; nút thêm giỏ hàng giữ thao tác riêng.
- [x] 10.5. Xây dựng trang chi tiết sản phẩm customer có gallery ảnh, thumbnail đổi ảnh chính, thông tin chi tiết và nút thêm vào giỏ hàng.
- [x] 10.6. Xây dựng trang giỏ hàng local state và màn hình customer cho tab Đơn hàng, Cá nhân.
- [x] 10.7. Thay test counter template bằng test `CustomerCartViewModel` kiểm tra thêm, giới hạn tồn kho, giảm và xóa sản phẩm.

### PHASE 11: Đồng bộ giỏ hàng Customer với Supabase
- [x] 11.1. Xác minh schema thật qua Supabase REST do phiên làm việc không có Supabase MCP hoặc Stitch MCP:
  - `carts`: `id`, `user_id`, `status`, `created_at`, `updated_at`.
  - `cart_items`: `id`, `cart_id`, `product_id`, `quantity`, `price_snapshot`, `created_at`, `updated_at`.
  - Quan hệ đọc: `carts -> cart_items -> products -> product_images`.
- [x] 11.2. Tạo `CustomerCartRepository` CRUD cart và cart item trên Supabase.
  - Tối ưu thao tác thêm sản phẩm chỉ query `cart.id` trước khi ghi để giảm payload.
- [x] 11.3. Chuyển `CustomerCartViewModel` từ local state sang persisted state:
  - Tự tải cart theo user đăng nhập và xóa state khi logout.
  - Optimistic update, rollback khi lỗi và khóa thao tác theo từng sản phẩm.
  - Đồng bộ lại khi mở tab cart và hỗ trợ pull-to-refresh.
- [x] 11.4. Tối ưu UI cart, catalog, detail:
  - Hiển thị loading theo item, animation nhẹ và tránh thao tác ghi chồng nhau.
  - Tab customer chuyển view không animation để tránh trễ đè view; trang chi tiết dùng fade ngắn.
- [x] 11.5. Cập nhật test `CustomerCartViewModel` dùng fake repository để kiểm tra CRUD persisted state.
- [x] 11.6. Hoàn thiện cách hiển thị và tính tổng giỏ hàng:
  - Badge giỏ hàng đếm số dòng sản phẩm khác nhau, không cộng dồn số lượng từng sản phẩm.
  - Thêm checkbox chọn từng item và chỉ tính tổng tiền của các item đã chọn.
  - Giữ lựa chọn ổn định khi cập nhật số lượng, tự loại bỏ lựa chọn khi item bị xóa hoặc không còn tồn tại sau khi đồng bộ.

### PHASE 11.7: Thanh toán & Quản lý Vòng đời Đơn hàng (Customer Checkout & Order Lifecycle)
- [x] 11.7.1. Deploy các RPC database (`create_order`, `request_cancel_order`, `cancel_request_cancel_order`, `admin_confirm_order`, `admin_approve_cancel_order`) để quản lý đặt hàng, hoàn kho, hoàn tiền ví đồng bộ.
- [x] 11.7.2. Tạo `CustomerOrderRepository` thực hiện đặt hàng, yêu cầu hủy đơn, rút yêu cầu hủy đơn.
- [x] 11.7.3. Tạo `AdminOrderRepository` để lấy danh sách đơn hàng, xác nhận giao hàng và phê duyệt yêu cầu hủy đơn.
- [x] 11.7.4. Tạo `CheckoutViewModel` và thiết kế màn hình `CheckoutView` (điền thông tin nhận hàng, chọn ví HamsaPay hoặc COD).
- [x] 11.7.5. Tích hợp nút thanh toán vào widget `_CartSummary` trong `CustomerCartView` khi có sản phẩm được chọn.
- [x] 11.7.6. Thiết kế màn hình đơn hàng của Khách hàng (`CustomerOrderListView`, `CustomerOrderListViewModel`) hiển thị danh sách đơn hàng thực tế kèm nút yêu cầu hủy/rút yêu cầu hủy.
- [x] 11.7.7. Thiết kế màn hình đơn hàng của Admin/Employee (`AdminOrderListView`, `AdminOrderListViewModel`) cho phép lọc trạng thái, xác nhận giao hàng (Admin/Employee) và phê duyệt hủy đơn (Chỉ Admin).
- [x] 11.7.8. Đăng ký các routes (`/checkout`, `/admin/orders`) trong `app_router.dart` và đăng ký các ViewModels trong `main.dart`.
- [x] 11.7.9. Viết unit tests kiểm chứng toàn bộ luồng thanh toán và cập nhật trạng thái đơn hàng trong `widget_test.dart`.
- [x] 11.7.10. Thiết kế màn hình chi tiết đơn hàng của Khách hàng (`CustomerOrderDetailView`) cho phép xem chi tiết sản phẩm và thao tác nghiệp vụ.


### PHASE 12: Dashboard Admin
- [x] 12.1. Kiểm tra schema Supabase thực tế và tạo RPC `admin_get_dashboard_stats`:
  - Chỉ cho phép tài khoản `admin` đã đăng nhập gọi RPC.
  - Thu hồi quyền thực thi từ `public`, `anon`; chỉ cấp quyền gọi cho `authenticated`.
  - Lọc kỳ thống kê theo tuần, tháng hoặc năm hiện tại với múi giờ `Asia/Ho_Chi_Minh`.
- [x] 12.2. Thống kê doanh thu ròng, đơn đang giao, đã hủy, giao thành công, đã hoàn tiền.
- [x] 12.3. Tính tỷ lệ hoàn đơn và tỷ lệ giao hàng thành công theo kỳ.
- [x] 12.4. Hiển thị sản phẩm sắp hết hàng đang kinh doanh có số lượng tồn kho `< 5`.
- [x] 12.5. Hiển thị top 5 sản phẩm bán chạy theo tổng số lượng mua, bỏ qua đơn đã hủy hoặc giao thất bại.
- [x] 12.6. Tạo `AdminDashboardRepository`, `AdminDashboardViewModel` và giao diện dashboard responsive theo MVVM + Provider.
- [x] 12.7. Thay dashboard mockup trong router bằng dashboard thật và chặn nhân viên truy cập route admin dashboard.
- [x] 12.8. Mở rộng bộ lọc dashboard:
  - Cho phép chọn tuần cụ thể bằng lịch.
  - Cho phép chọn tháng và năm cụ thể bằng dropdown.
  - Cho phép chọn năm cụ thể bằng dropdown.
  - Truyền ngày tham chiếu vào RPC để tính đúng ranh giới kỳ theo múi giờ Việt Nam.
- [x] 12.9. Điều hướng nhanh từ card trạng thái dashboard sang quản lý đơn hàng:
  - Card đang giao, giao thành công và đã hủy mở tab đơn hàng với trạng thái tương ứng.
  - Card đã hoàn tiền mở tab đơn hàng và lọc theo `payment_status` hoàn tiền toàn phần hoặc một phần.
  - Trạng thái lọc được truyền qua query parameter và đồng bộ với dropdown danh sách đơn hàng.
- [x] 12.10. Cho phép bấm sản phẩm sắp hết hàng để mở trang chi tiết sản phẩm và cập nhật tồn kho.

### PHASE 12.5: Điều chỉnh UI Customer Cart
- [x] 12.5.1. Giữ nhãn nút `Thanh toán` trên một dòng và tăng chiều rộng nút trong phần tổng kết giỏ hàng.

---

## 🚦 Quy tắc cập nhật checklist
- Sau khi hoàn thành bất kỳ bước nào trong checklist này, AI sẽ cập nhật ký tự `[ ]` thành `[x]` để theo dõi tiến độ.
- Nếu có bất kỳ điều chỉnh hoặc thêm bớt tính năng nào, AI phải sửa đổi nội dung checklist này ngay lập tức.
