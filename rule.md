# RULE.md — Quy tắc phát triển dự án Hamsa Store Demo

## 1. Tổng quan dự án

Dự án là hệ thống quản lý bán hàng đơn giản, hỗ trợ chạy trên:

- Flutter Mobile App
- Flutter Web
- Backend sử dụng Supabase
- Quản lý state bằng Provider
- Kiến trúc MVVM
- Có phân quyền theo vai trò `admin` và `employee`

Mục tiêu chính là xây dựng hệ thống quản lý user, phân quyền, sản phẩm, đơn hàng và trang cá nhân theo đúng phạm vi đề bài.

---

## 2. Ngôn ngữ trả lời và phong cách làm việc của AI

Mỗi lần AI trả lời hoặc sinh code cho dự án này cần tuân thủ:

- Luôn trả lời bằng tiếng Việt.
- Giải thích ngắn gọn, dễ hiểu, đi thẳng vào vấn đề.
- Khi viết code cần chia rõ từng file, đúng đường dẫn.
- Không viết code gộp lung tung trong một file lớn.
- Ưu tiên code có thể chạy được ngay.
- Nếu dùng MCP như Supabase MCP, Stitch MCP hoặc Firebase MCP thì phải kiểm tra schema/thông tin thực tế trước khi sinh code liên quan đến database.
- Nếu chưa đủ thông tin, phải đưa ra giả định rõ ràng trước khi viết code.
- Không tự ý thay đổi kiến trúc MVVM + Provider nếu không được yêu cầu.
- Không dùng BLoC nếu project đã chọn Provider.
- Không dùng Riverpod nếu chưa được yêu cầu.
- Không hardcode logic nghiệp vụ trong UI.

---

## 3. Công nghệ sử dụng

### 3.1 Frontend

- Flutter
- Dart
- Provider / ChangeNotifier
- Flutter Web
- Flutter Mobile App
- Responsive UI bằng `LayoutBuilder`, `Flex`, `Expanded`, `Flexible`, `Wrap`, `MediaQuery`
- Router tập trung qua `AppRouter`

### 3.2 Backend

Ưu tiên dùng Supabase.

Nếu đề bài hoặc mentor yêu cầu Firebase thì có thể dùng Firebase.

Backend có thể gồm:

- Supabase Auth
- Supabase Database
- Supabase Storage
- Supabase RLS 
- Role trong bảng `profiles` nếu dùng Supabase

### 3.3 State Management

Chỉ dùng Provider:

- `ChangeNotifier`
- `ChangeNotifierProvider`
- `Consumer`
- `Selector`
- `context.read<T>()`
- `context.watch<T>()`

Không gọi trực tiếp API trong View.

Luồng chuẩn:

```text
View -> ViewModel -> Repository -> Service/Client -> Backend
```

---

## 4. Phạm vi đề bài

### M1 — Auth & Quản lý user

Chức năng:

- Đăng nhập email/password
- Đăng xuất
- Quên mật khẩu, optional
- Admin xem danh sách user
- Admin tìm kiếm user theo tên/email
- Admin thêm user
- Admin sửa user
- Admin kích hoạt/vô hiệu hóa user bằng `is_active`
- Không xóa cứng Auth user
- User bị `is_active = false` không được truy cập hệ thống

### M2 — Phân quyền

Role:

- `admin`
- `employee`

Yêu cầu:

- Chặn route theo role
- Ẩn menu theo role
- `admin` có quyền quản lý user, sản phẩm, đơn hàng
- `employee` chỉ được xem một số dữ liệu, không được sửa/xóa nếu đề bài yêu cầu read-only
- Nếu dùng Firebase phải cấu hình Firestore Rules và Custom Claim nếu cần
- Nếu dùng Supabase phải dùng RLS policy hoặc kiểm tra role ở server/database

### M3 — Quản lý sản phẩm

Chức năng:

- Danh sách sản phẩm
- Tìm kiếm theo tên, barcode
- Phân trang 20 sản phẩm/trang
- Thêm sản phẩm
- Sửa sản phẩm
- Soft delete bằng trạng thái `inactive`
- Có trạng thái active/inactive

Form sản phẩm gồm:

- Tên nội bộ
- Tên thương mại
- Barcode
- Giá
- Tồn kho
- Trạng thái

Validate:

- Tên bắt buộc
- Giá >= 0
- Tồn kho >= 0
- Barcode không được trùng nếu hệ thống yêu cầu unique

Phân quyền:

- `admin`: thêm/sửa/xóa mềm
- `employee`: chỉ xem, không hiện nút thêm/sửa/xóa

### M4 — Quản lý đơn hàng

Chức năng:

- Tạo đơn từ giỏ hàng
- Chọn khách hàng hoặc dùng `retail_customer`
- Thêm sản phẩm vào giỏ
- Tính tổng tiền
- Ghi chú đơn hàng
- Danh sách đơn hàng
- Lọc theo trạng thái
- Lọc theo thời gian
- Tìm kiếm theo mã đơn hoặc tên khách hàng
- Xem chi tiết đơn hàng
- Cập nhật trạng thái đơn hàng
- Hủy đơn khi trạng thái là `new_order`

Quy tắc trạng thái:

```text
new_order -> confirmed -> processing -> completed
```

Không cho phép lùi trạng thái.

Chỉ được hủy đơn khi:

```text
status == new_order
```

Khi tạo đơn hàng cần dùng transaction nếu có cập nhật tồn kho.

### M5 — Trang cá nhân

Chức năng:

- Hiển thị email, read-only
- Hiển thị tên
- Hiển thị số điện thoại
- Hiển thị role, read-only
- Sửa tên
- Sửa số điện thoại
- Avatar dùng Storage hoặc URL text
- Đổi mật khẩu
- Không cho user tự đổi role của chính mình

---

## 5. Kiến trúc thư mục bắt buộc

Cấu trúc thư mục chính:

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_guard.dart
│   ├── services/
│   │   ├── supabase_service.dart
│   │   ├── auth_service.dart
│   │   └── storage_service.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── app_routes.dart
│   │   └── app_enums.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   ├── app_table.dart
│   │   ├── app_dialog.dart
│   │   ├── app_loading.dart
│   │   ├── app_empty_state.dart
│   │   └── app_error_state.dart
│   ├── layout/
│   │   ├── main_layout.dart
│   │   ├── side_menu.dart
│   │   ├── top_bar.dart
│   │   └── responsive_layout.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   ├── debounce.dart
│   │   └── result.dart
│   └── errors/
│       ├── app_exception.dart
│       └── error_handler.dart
│
├── data/
│   ├── models/
│   │   ├── profiles_model.dart
│   │   ├── products_model.dart
│   │   ├── cart_model.dart
│   │   ├── cart_item_model.dart
│   │   ├── order_model.dart
│   │   └── order_item_model.dart
│   └── dto/
│       ├── pagination_result.dart
│       └── search_filter.dart
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
    │   │       ├── admin_user_form_view.dart
    │   │       └── widgets/
    │   │           ├── user_table.dart
    │   │           └── user_form.dart
    │   │
    │   ├── products/
    │   │   ├── repository/
    │   │   │   └── admin_product_repository.dart
    │   │   ├── viewmodel/
    │   │   │   ├── product_list_view_model.dart
    │   │   │   └── product_form_view_model.dart
    │   │   └── view/
    │   │       ├── product_list_view.dart
    │   │       ├── product_form_view.dart
    │   │       └── widgets/
    │   │           ├── product_table.dart
    │   │           ├── product_form.dart
    │   │           └── product_filter_bar.dart
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
    │           ├── order_create_view.dart
    │           └── widgets/
    │               ├── order_table.dart
    │               ├── order_status_chip.dart
    │               ├── cart_panel.dart
    │               └── order_summary.dart
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
        │       ├── forgot_password_view.dart
        │       └── widgets/
        │           └── login_form.dart
        │
        ├── profile/
        │   ├── repository/
        │   │   └── profile_repository.dart
        │   ├── viewmodel/
        │   │   ├── profile_view_model.dart
        │   │   └── change_password_view_model.dart
        │   └── view/
        │       ├── profile_view.dart
        │       ├── change_password_view.dart
        │       └── widgets/
        │           ├── profile_form.dart
        │           └── avatar_picker.dart
        │
        └── dashboard/
            ├── viewmodel/
            │   └── dashboard_view_model.dart
            └── view/
                └── dashboard_view.dart
```

---

## 6. Quy tắc đặt tên file và class

### 6.1 File

Dùng snake_case:

```text
product_list_view.dart
product_list_view_model.dart
admin_product_repository.dart
```

Không dùng:

```text
ProductListView.dart
productListView.dart
```

### 6.2 Class

Dùng PascalCase:

```dart
class ProductListView extends StatelessWidget {}
class ProductListViewModel extends ChangeNotifier {}
class AdminProductRepository {}
```

### 6.3 Biến và hàm

Dùng camelCase:

```dart
final productName = '';
Future<void> loadProducts() async {}
```

---

## 7. Quy tắc MVVM

### 7.1 View

View chỉ được làm:

- Hiển thị UI
- Nhận input từ người dùng
- Gọi hàm từ ViewModel
- Điều hướng màn hình
- Hiển thị loading, error, empty state

View không được:

- Gọi Supabase trực tiếp
- Viết query database
- Xử lý nghiệp vụ phức tạp
- Validate nghiệp vụ dài
- Tính toán trạng thái đơn hàng trực tiếp

### 7.2 ViewModel

ViewModel chịu trách nhiệm:

- Quản lý state
- Gọi Repository
- Validate form cơ bản
- Xử lý loading/error/success
- Notify UI bằng `notifyListeners()`
- Debounce search
- Hủy request cũ nếu cần

ViewModel không được:

- Chứa widget
- Truy cập BuildContext nếu không cần thiết
- Gọi database client trực tiếp nếu đã có Repository

### 7.3 Repository

Repository chịu trách nhiệm:

- Làm việc với Supabase
- Query database
- Mapping dữ liệu sang Model
- Transaction
- Batch commit
- Pagination
- Search
- Filter

Repository không được:

- Chứa UI
- Gọi `notifyListeners()`
- Chứa logic hiển thị

---

## 8. Quy tắc Provider

Trong `main.dart` hoặc `app.dart`, đăng ký Provider theo từng module.

Ví dụ:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LoginViewModel()),
    ChangeNotifierProvider(create: (_) => ProductListViewModel()),
  ],
  child: const App(),
);
```

Quy tắc:

- Dùng `context.read<T>()` khi gọi action.
- Dùng `context.watch<T>()` khi cần rebuild UI.
- Dùng `Selector` khi chỉ cần rebuild một phần nhỏ.
- Không gọi async trực tiếp trong `build`.
- Không tạo ViewModel mới liên tục trong `build`.

---

## 9. Quy tắc Responsive UI cho Web và App

Dự án phải hỗ trợ cả Flutter Web và Mobile App.

### 9.1 Layout

Bắt buộc dùng linh hoạt:

- `LayoutBuilder`
- `MediaQuery`
- `Flex`
- `Expanded`
- `Flexible`
- `Wrap`
- `ConstrainedBox`
- `SingleChildScrollView`

### 9.2 Breakpoint gợi ý

```dart
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}
```

### 9.3 Quy tắc UI

- Không fix width cứng cho toàn màn hình.
- Không để table tràn màn hình trên mobile.
- Với web admin, ưu tiên layout sidebar + content.
- Với mobile, sidebar chuyển thành drawer hoặc bottom navigation.
- Form phải có scroll nếu màn hình nhỏ.
- Table trên mobile có thể đổi thành card list.

---

## 10. Quy tắc Auth

### 10.1 Login

Login bằng email/password.

Sau khi login:

1. Lấy thông tin Auth user.
2. Lấy document/profile trong bảng `users`.
3. Kiểm tra `is_active`.
4. Kiểm tra role.
5. Điều hướng vào dashboard tương ứng.

Nếu `is_active = false`:

- Đăng xuất ngay.
- Hiển thị lỗi: "Tài khoản đã bị vô hiệu hóa".

### 10.2 Logout

Khi logout:

- Gọi Supabase/Firebase sign out.
- Clear local state.
- Điều hướng về login.

### 10.3 Forgot Password

Optional.

Nếu làm:

- Gửi email reset password.
- Hiển thị thông báo thành công.
- Không tiết lộ email có tồn tại hay không.

---

## 11. Quy tắc phân quyền

### 11.1 Role

Có 2 role:

```text
admin
employee
```

### 11.2 Admin

Admin được:

- Quản lý user
- Thêm/sửa/vô hiệu user
- Quản lý danh mục
- Thêm/sửa/xóa danh mục
- Quản lý nhãn hàng
- Thêm/sửa/xóa nhãn hàng
- Quản lý sản phẩm  
- Thêm/sửa/xóa mềm sản phẩm
- Quản lý đơn hàng
- Cập nhật trạng thái đơn hàng
- Hủy đơn nếu `new_order`
- Xem và sửa hồ sơ cá nhân

### 11.3 Employee

Employee được:

- Đăng nhập
- Xem dashboard
- Xem sản phẩm
- Xem đơn hàng nếu được yêu cầu
- Xem/sửa hồ sơ cá nhân
- Đổi mật khẩu

Employee không được:

- CRUD user
- Đổi role
- Thêm/sửa/xóa sản phẩm nếu module yêu cầu read-only
- Truy cập route admin user management

### 11.4 Route Guard

Tất cả route cần kiểm tra:

- User đã đăng nhập chưa
- User có `is_active = true` không
- User có đúng role không

Không chỉ ẩn menu, phải chặn cả route.

---

## 12. Quy tắc Supabase

Khi dùng Supabase:

- Không hardcode Supabase URL và anon key trực tiếp nhiều nơi.
- Tạo `SupabaseService` trong `core/services`.
- Bật RLS cho các bảng quan trọng.
- Tạo policy theo role.
- Không để employee sửa dữ liệu admin.
- Không query N+1.
- Dùng select join nếu cần dữ liệu liên quan.
- Dùng pagination bằng `range(from, to)`.
- Dùng transaction/RPC khi tạo đơn hàng và trừ tồn kho.
- Dùng soft delete bằng `deleted_at` hoặc `status = inactive`.
- Dùng `created_at`, `updated_at`, `created_by`, `updated_by` nếu cần tracking.

Ví dụ tránh N+1:

Không làm:

```text
Lấy danh sách order -> mỗi order lại query customer -> mỗi order lại query items
```

Nên làm:

```text
Query order kèm customer và order_items bằng join/select phù hợp
```

## 14. Quy tắc database model dùng chung

Các model dùng chung đặt trong:

```text
lib/data/models/
```

Model bắt buộc có:

- `fromJson`
- `toJson`
- `copyWith`
- Kiểu dữ liệu rõ ràng
- Không để dynamic tràn lan

Ví dụ:

```dart
class ProductModel {
  final String id;
  final String internalName;
  final String? tradeName;
  final String? barcode;
  final double price;
  final int stock;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.internalName,
    this.tradeName,
    this.barcode,
    required this.price,
    required this.stock,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

---

## 15. Quy tắc Tracking

Các bảng chính nên có trường tracking:

```text
created_at
updated_at
created_by
updated_by
deleted_at
deleted_by
```

Tùy bảng có thể rút gọn, nhưng bảng quan trọng nên có đầy đủ:

- users
- products
- orders
- order_items
- customers

### 15.1 Xóa mềm

Ưu tiên xóa mềm cho dữ liệu nghiệp vụ:

- Product: `status = inactive` hoặc `deleted_at != null`
- User: `is_active = false`
- Order: không xóa, chỉ chuyển trạng thái `cancelled` nếu được phép

### 15.2 Xóa cứng

Chỉ xóa cứng với:

- Dữ liệu test
- Dữ liệu nháp chưa phát sinh nghiệp vụ
- Cart item
- Temporary data

Không xóa cứng:

- Auth user
- Order
- Order item
- Transaction log nếu có

---

## 16. Quy tắc query và hiệu năng

### 16.1 Tránh N+1 Query

Không query từng item trong vòng lặp nếu có thể join hoặc batch.

Sai:

```dart
for (final order in orders) {
  final customer = await getCustomer(order.customerId);
}
```

Đúng:

```text
Query orders kèm customer trong một request.
```

### 16.2 Pagination

Danh sách lớn phải phân trang:

- Product: 20/trang
- User: 20/trang
- Order: 20/trang

Không load toàn bộ dữ liệu nếu không cần.

### 16.3 Debounce

Các ô search cần debounce khoảng 300-500ms.

Áp dụng cho:

- Search user
- Search product
- Search order
- Filter order

### 16.4 Abort Controller / Hủy request cũ

Flutter không có AbortController giống JavaScript, nhưng cần xử lý tương đương:

- Dùng request token
- Dùng `CancelableOperation` nếu cần
- Bỏ qua response cũ nếu user đã search từ khóa mới
- Kiểm tra `disposed` trước khi `notifyListeners`

Ví dụ logic:

```dart
int _requestVersion = 0;

Future<void> search(String keyword) async {
  final currentVersion = ++_requestVersion;
  final result = await repository.search(keyword);

  if (currentVersion != _requestVersion) return;

  items = result;
  notifyListeners();
}
```

---

## 17. Quy tắc Transaction và Batch Commit

### 17.1 Khi nào dùng transaction?

Bắt buộc dùng transaction khi:

- Tạo đơn hàng và trừ tồn kho
- Hủy đơn và hoàn tồn kho nếu nghiệp vụ yêu cầu
- Cập nhật trạng thái đơn hàng có kiểm tra trạng thái hiện tại
- Tạo user kèm profile nếu backend hỗ trợ

### 17.2 Khi nào dùng batch commit?

Dùng batch commit khi:

- Tạo nhiều order items
- Cập nhật nhiều document cùng lúc
- Seed dữ liệu mẫu
- Import sản phẩm

### 17.3 Quy tắc tạo đơn hàng

Khi tạo đơn:

1. Kiểm tra giỏ hàng không rỗng.
2. Kiểm tra sản phẩm còn active.
3. Kiểm tra tồn kho đủ.
4. Tạo order.
5. Tạo order_items.
6. Trừ tồn kho.
7. Clear cart.
8. Commit transaction.
9. Nếu lỗi thì rollback.

---

## 18. Quy tắc nghiệp vụ đơn hàng

### 18.1 Trạng thái đơn hàng

Các trạng thái:

```text
new_order
confirmed
processing
completed
cancelled
```

### 18.2 Cập nhật trạng thái

Chỉ cho phép đi tới:

```text
new_order -> confirmed
confirmed -> processing
processing -> completed
```

Không cho phép:

```text
completed -> processing
processing -> confirmed
confirmed -> new_order
cancelled -> trạng thái khác
```

### 18.3 Hủy đơn

Chỉ hủy khi:

```text
status == new_order
```

Sau khi hủy:

```text
status = cancelled
```

Nếu có trừ tồn kho ngay lúc tạo đơn thì cần hoàn tồn kho khi hủy.

---

## 19. Quy tắc module Auth & User

### 19.1 Repository

Đường dẫn:

```text
lib/features/user/auth/repository/auth_repository.dart
lib/features/admin/users/repository/admin_user_repository.dart
```

Repository cần có:

```dart
Future<AppUserModel?> getCurrentUserProfile();
Future<void> login(String email, String password);
Future<void> logout();
Future<void> resetPassword(String email);
Future<List<AppUserModel>> getUsers({String? keyword, int page = 1});
Future<void> createUser(...);
Future<void> updateUser(...);
Future<void> setUserActive(String userId, bool isActive);
```

### 19.2 ViewModel

LoginViewModel cần có state:

```dart
bool isLoading;
String? errorMessage;
String email;
String password;
```

AdminUserListViewModel cần có:

```dart
List<AppUserModel> users;
String keyword;
int currentPage;
bool isLoading;
String? errorMessage;
```

### 19.3 UI

Admin user list cần có:

- Search input
- Table
- Pagination
- Nút thêm user
- Nút sửa
- Switch active/inactive

---

## 20. Quy tắc module Product

### 20.1 Repository

Đường dẫn:

```text
lib/features/admin/products/repository/admin_product_repository.dart
```

Repository cần có:

```dart
Future<PaginationResult<ProductModel>> getProducts({
  String? keyword,
  int page = 1,
  int pageSize = 20,
});

Future<ProductModel?> getProductById(String id);
Future<void> createProduct(ProductModel product);
Future<void> updateProduct(ProductModel product);
Future<void> softDeleteProduct(String id);
```

### 20.2 ViewModel

ProductListViewModel cần có:

```dart
List<ProductModel> products;
String keyword;
int currentPage;
int pageSize;
bool isLoading;
String? errorMessage;
```

### 20.3 UI

Product list cần có:

- Search theo tên/barcode
- Pagination 20/trang
- Table trên web
- Card list trên mobile
- Nút thêm chỉ hiển thị với admin
- Nút sửa chỉ hiển thị với admin
- Nút xóa mềm chỉ hiển thị với admin

---

## 21. Quy tắc module Order

### 21.1 Repository

Đường dẫn:

```text
lib/features/admin/orders/repository/admin_order_repository.dart
```

Repository cần có:

```dart
Future<PaginationResult<OrderModel>> getOrders({
  String? keyword,
  String? status,
  DateTime? fromDate,
  DateTime? toDate,
  int page = 1,
  int pageSize = 20,
});

Future<OrderModel?> getOrderDetail(String id);
Future<void> createOrder(...);
Future<void> updateOrderStatus(String orderId, String nextStatus);
Future<void> cancelOrder(String orderId);
```

### 21.2 ViewModel

OrderCreateViewModel cần có:

```dart
List<CartItemModel> cartItems;
CustomerModel? selectedCustomer;
String note;
double totalAmount;
bool isLoading;
String? errorMessage;
```

OrderListViewModel cần có:

```dart
List<OrderModel> orders;
String keyword;
String? selectedStatus;
DateTime? fromDate;
DateTime? toDate;
int currentPage;
bool isLoading;
String? errorMessage;
```

### 21.3 UI

Order list cần có:

- Search mã đơn / tên khách hàng
- Filter trạng thái
- Filter thời gian
- Table/list
- Nút xem chi tiết

Order detail cần có:

- Thông tin khách hàng
- Danh sách sản phẩm
- Tổng tiền
- Ghi chú
- Trạng thái
- Nút cập nhật trạng thái nếu hợp lệ
- Nút hủy nếu trạng thái là `new_order`

---

## 22. Quy tắc module Profile

### 22.1 Repository

Đường dẫn:

```text
lib/features/user/profile/repository/profile_repository.dart
```

Repository cần có:

```dart
Future<AppUserModel?> getProfile();
Future<void> updateProfile({
  required String name,
  required String phone,
  String? avatarUrl,
});
Future<void> changePassword(String newPassword);
```

### 22.2 UI

Profile view cần có:

- Email read-only
- Role read-only
- Name editable
- Phone editable
- Avatar URL hoặc upload
- Button lưu
- Button đổi mật khẩu

Không cho user tự sửa role.

---

## 23. Quy tắc xử lý lỗi

Mọi ViewModel cần có:

```dart
bool isLoading = false;
String? errorMessage;
```

Khi gọi API:

```dart
try {
  isLoading = true;
  errorMessage = null;
  notifyListeners();

  await repository.doSomething();
} catch (e) {
  errorMessage = ErrorHandler.getMessage(e);
} finally {
  isLoading = false;
  notifyListeners();
}
```

Không hiển thị lỗi raw quá kỹ thuật cho người dùng.

Ví dụ:

Không nên:

```text
PostgrestException: duplicate key value violates unique constraint
```

Nên:

```text
Dữ liệu đã tồn tại, vui lòng kiểm tra lại.
```

---

## 24. Quy tắc validate

### 24.1 Login

- Email không được rỗng
- Email đúng định dạng
- Password không được rỗng

### 24.2 User

- Name không được rỗng
- Email đúng định dạng
- Role chỉ được là `admin` hoặc `employee`
- Phone có thể optional

### 24.3 Product

- Tên nội bộ không được rỗng
- Giá >= 0
- Tồn kho >= 0
- Trạng thái chỉ được là `active` hoặc `inactive`

### 24.4 Order

- Giỏ hàng không rỗng
- Số lượng sản phẩm > 0
- Không tạo đơn với sản phẩm inactive
- Không tạo đơn nếu tồn kho không đủ

### 24.5 Profile

- Tên không được rỗng
- Số điện thoại optional
- Password mới đủ độ dài nếu đổi mật khẩu

---

## 25. Quy tắc UI Design

Dùng theme tập trung trong:

```text
lib/core/theme/
```

Không hardcode màu ở nhiều nơi.

Phải có:

- `AppColors`
- `AppTextStyles`
- `AppTheme`

Widget dùng chung đặt tại:

```text
lib/core/widgets/
```

Ví dụ widget dùng chung:

- Button
- TextField
- Table
- Dialog
- Loading
- EmptyState
- ErrorState
- StatusChip

View-specific widget đặt trong:

```text
features/.../view/widgets/
```

Không đưa widget chỉ dùng cho một màn hình vào `core/widgets`.

---

## 26. Quy tắc AppRouter

Router đặt tại:

```text
lib/core/router/app_router.dart
```

Route guard đặt tại:

```text
lib/core/router/route_guard.dart
```

Route cần phân quyền:

```dart
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const users = '/admin/users';
  static const products = '/admin/products';
  static const orders = '/admin/orders';
  static const profile = '/profile';
}
```

Quy tắc:

- Nếu chưa login -> về `/login`
- Nếu inactive -> logout và về `/login`
- Nếu không đủ quyền -> về dashboard hoặc màn hình unauthorized
- Không chỉ ẩn menu, phải chặn route

---

## 27. Quy tắc MCP

Khi làm việc với MCP:

- Nếu có Supabase MCP, phải kiểm tra bảng, cột, policy trước khi viết query.
- Nếu có Stitch MCP, phải tận dụng để hỗ trợ tạo UI hoặc kiểm tra design nếu phù hợp.
- Nếu MCP trả về schema khác với rule này, phải báo lại điểm khác biệt.
- Không tự bịa tên bảng/cột nếu MCP đã có schema thật.
- Khi sinh code Repository, phải khớp với schema thật.
- Nếu chưa có schema, dùng schema đề xuất và ghi rõ là giả định.

---

## 28. Quy tắc bảo mật

- Không commit API key thật lên git.
- Không hardcode service role key trong Flutter.
- Flutter chỉ được dùng anon key với Supabase.
- Các thao tác admin quan trọng phải bảo vệ bằng RLS/policy hoặc server function.
- Không tin dữ liệu từ client.
- Không cho client tự set role nếu không có quyền.
- Không cho user tự sửa `is_active`, `role`, `created_by`.
- Không log password/token.

---

## 29. Quy tắc seed dữ liệu

Có thể seed user bằng:

- Script mentor: `scripts/intern/seed_intern_data.js`
- Firebase Console
- Supabase SQL Editor
- Supabase MCP nếu có hỗ trợ

Quy tắc:

- User Auth và bảng `users` phải khớp id.
- Không tạo user chỉ trong bảng `users` mà không có Auth nếu cần login.
- Tài khoản test cần ghi rõ role.
- Không seed dữ liệu trùng barcode/email.

---

## 30. Checklist hoàn thành module

### M1 — Auth & User

Hoàn thành khi:

- Login/logout chạy được.
- User inactive không vào được app.
- Admin xem danh sách user được.
- Admin search user theo tên/email được.
- Admin thêm/sửa user được.
- Admin bật/tắt `is_active` được.
- Employee không vào được màn quản lý user.

### M2 — Phân quyền

Hoàn thành khi:

- Menu hiển thị đúng theo role.
- Route bị chặn nếu không đủ quyền.
- Employee không thể truy cập URL admin user trực tiếp.
- Backend rule/policy bảo vệ dữ liệu đúng.

### M3 — Product

Hoàn thành khi:

- Danh sách sản phẩm hiển thị đúng.
- Search tên/barcode hoạt động.
- Pagination 20/trang hoạt động.
- Admin thêm/sửa/xóa mềm được.
- Product inactive không bị xóa cứng.
- Employee chỉ xem, không thao tác sửa/xóa.

### M4 — Order

Hoàn thành khi:

- Tạo đơn từ giỏ hàng được.
- Tính tổng tiền đúng.
- Danh sách đơn hàng có filter/search.
- Xem chi tiết đơn hàng được.
- Cập nhật trạng thái chỉ tiến.
- Hủy được khi `new_order`.
- Không hủy được khi đã xử lý.
- Tạo đơn có transaction khi ảnh hưởng tồn kho.

### M5 — Profile

Hoàn thành khi:

- Xem được email, name, phone, role.
- Email và role read-only.
- Sửa name/phone được.
- Đổi mật khẩu được.
- Không tự đổi role được.

---

## 31. Quy tắc khi prompt AI sinh code

Khi yêu cầu AI sinh code, cần ghi rõ:

```text
Hãy tuân thủ RULE.md.
Dự án Flutter dùng MVVM + Provider.
Không dùng BLoC/Riverpod.
Code tách theo feature.
View không gọi trực tiếp Supabase/Firebase.
Repository xử lý query.
ViewModel xử lý state.
UI responsive cho web và mobile.
Trả lời bằng tiếng Việt.
```

Prompt mẫu:

```text
Dựa theo RULE.md, hãy tạo module Product Management.
Yêu cầu:
- Flutter MVVM + Provider
- Có repository, viewmodel, view
- UI responsive web/mobile
- Admin được thêm/sửa/xóa mềm
- Employee chỉ xem
- Search debounce theo tên/barcode
- Pagination 20/trang
- Repository dùng Supabase
- Tránh N+1 query
- Trả lời bằng tiếng Việt
```

---

## 32. Quy tắc kiểm tra trước khi hoàn thành task

Trước khi báo hoàn thành, AI phải tự kiểm tra:

- File đã đúng thư mục chưa?
- Class đã đúng tên chưa?
- Có tách View, ViewModel, Repository chưa?
- View có gọi database trực tiếp không?
- Có xử lý loading/error không?
- Có validate input không?
- Có phân quyền không?
- Có responsive không?
- Có tránh N+1 query không?
- Có debounce search nếu cần không?
- Có transaction/batch cho nghiệp vụ quan trọng không?
- Có trả lời bằng tiếng Việt không?
- Bắt buộc phải chạy lệnh phân tích tĩnh (ví dụ: `flutter analyze`) để tự kiểm tra xem có lỗi cú pháp hoặc kiểu dữ liệu nào không, và sửa đổi triệt để trước khi báo hoàn thành hoặc làm tiếp.

---

## 33. Nguyên tắc ưu tiên

Khi có xung đột, ưu tiên theo thứ tự:

1. Yêu cầu trực tiếp của người dùng.
2. RULE.md này.
3. Schema thật từ Supabase/Firebase MCP.
4. Kiến trúc MVVM + Provider.
5. Code sạch, dễ mở rộng.
6. UI responsive web/mobile.
7. Tối ưu hiệu năng và bảo mật.

---

## 34. Ghi chú quan trọng

- Project này phục vụ phạm vi đề bài, không cần làm quá lớn như hệ thống ERP.
- Tuy nhiên code phải đủ sạch để mở rộng.
- Wallet, thanh toán online, báo cáo nâng cao, notification là ngoài phạm vi nếu chưa được yêu cầu.
- Không thêm module ngoài phạm vi nếu chưa được yêu cầu.
- Nếu thêm tính năng mới, phải đặt đúng vào `features/admin` hoặc `features/user`.
- Luôn ưu tiên hoàn thành module chính trước khi làm nâng cao.

## 35. Quy tắc sử dụng RTK và GitNexus

### 35.1 RTK cho lệnh terminal

- Khi chạy lệnh terminal trong project, bắt buộc prefix lệnh bằng `rtk`.
- Không chạy trực tiếp các lệnh shell khi `rtk` hỗ trợ lệnh tương ứng.
- Áp dụng cho các lệnh đọc file, tìm kiếm, kiểm tra Git, liệt kê thư mục, chạy analyzer, test và build.
- Nếu `rtk` không hỗ trợ một lệnh cần thiết, phải nêu rõ lý do trước khi dùng phương án thay thế.

Ví dụ đúng:

```bash
rtk git status
rtk ls -la
rtk find . -name "*.dart"
rtk rg -n "AppRouter" lib
rtk flutter analyze
rtk flutter test
rtk flutter build web
```

Ví dụ không được chạy trực tiếp:

```bash
git status
ls -la
find . -name "*.dart"
flutter analyze
```

### 35.2 GitNexus cho phân tích codebase

- Ưu tiên dùng GitNexus trước khi phân tích kiến trúc, dependency graph hoặc execution flow của project.
- Khi cần sửa code có phạm vi ảnh hưởng rộng, dùng GitNexus để kiểm tra symbol liên quan và blast radius trước khi chỉnh sửa.
- Khi cần tìm nguyên nhân lỗi qua nhiều module, dùng GitNexus để truy vết flow trước khi kết luận.
- Sau thay đổi lớn, dùng GitNexus để kiểm tra các flow bị ảnh hưởng nếu cần.
- Nếu GitNexus chưa có index hoặc index đã cũ, chạy phân tích lại repository trước khi sử dụng kết quả.

Các lệnh GitNexus thường dùng:

```bash
rtk gitnexus status
rtk gitnexus analyze .
rtk gitnexus query "application startup routing authentication"
rtk gitnexus context AppRouter --file lib/core/router/app_router.dart
rtk gitnexus impact AppRouter
rtk gitnexus detect-changes
```
