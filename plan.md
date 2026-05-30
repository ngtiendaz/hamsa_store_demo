# PLAN.md — Kế hoạch hoàn thành toàn bộ module Flutter + Supabase

## 0. Mục tiêu dự án

Xây dựng app quản lý bán hàng với 3 nhóm người dùng:

- `admin`: quản lý toàn bộ hệ thống.
- `employee`: xem sản phẩm, xử lý đơn hàng, duyệt trả hàng.
- `customer`: xem sản phẩm, giỏ hàng, tạo đơn hàng, quản lý đơn của mình, ví tiền đơn giản.

Công nghệ sử dụng:

- Flutter
- Supabase Auth
- Supabase Database PostgreSQL
- Supabase Storage
- Provider hoặc BLoC
- MVVM architecture

---

## 1. Nguyên tắc phát triển

### 1.1. Kiến trúc code

Dự án nên chia theo module:

```text
lib/
├── core/
│   ├── constants/
│   ├── config/
│   ├── router/
│   ├── theme/
│   ├── utils/
│   ├── widgets/
│   └── services/
│
├── features/
│   ├── auth/
│   ├── profile/
│   ├── users/
│   ├── products/
│   ├── cart/
│   ├── orders/
│   ├── returns/
│   ├── wallet/
│   └── dashboard/
│
└── main.dart
```

Mỗi feature nên có cấu trúc:

```text
features/products/
├── models/
├── repositories/
├── viewmodels/
├── views/
└── widgets/
```

### 1.2. Luồng chuẩn MVVM

```text
View
  -> ViewModel
    -> Repository
      -> Supabase Client
```

Không gọi Supabase trực tiếp trong UI.

### 1.3. Quy tắc code

- Không viết logic nghiệp vụ nặng trong Widget.
- Không hard-code role nhiều nơi.
- Không tự cập nhật tồn kho hoặc ví tiền trong nhiều màn hình khác nhau.
- Những nghiệp vụ quan trọng nên gom vào Repository hoặc Supabase RPC.
- Mọi màn hình phải có loading, error, empty state.
- Mọi form phải validate dữ liệu trước khi gửi.

---

# PHASE 1 — Setup nền tảng dự án

## 1.1. Setup package cần thiết

### Việc cần làm

Cài các package Flutter:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: latest
  provider: latest
  go_router: latest
  intl: latest
  cached_network_image: latest
  image_picker: latest
  uuid: latest
```

Nếu dùng BLoC thì thay Provider bằng:

```yaml
flutter_bloc: latest
equatable: latest
```

### Prompt AI

```text
Tôi đang xây dựng app Flutter + Supabase theo kiến trúc MVVM.
Hãy setup cấu trúc thư mục chuẩn cho dự án gồm core, features, models, repositories, viewmodels, views.
Dùng Provider để quản lý state.
Tạo các file khung ban đầu nhưng chưa cần code nghiệp vụ.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- App chạy được bằng `flutter run`.
- Có cấu trúc thư mục rõ ràng.
- Không có lỗi import.
- Có file cấu hình Supabase.
- Có `main.dart` khởi tạo Supabase thành công.

---

## 1.2. Setup Supabase Client

### Việc cần làm

Tạo file:

```text
lib/core/config/supabase_config.dart
lib/core/services/supabase_service.dart
```

Nội dung cần có:

- Supabase URL
- Supabase anon key
- Getter dùng chung cho Supabase client

Ví dụ:

```dart
final supabase = Supabase.instance.client;
```

### Prompt AI

```text
Tạo service Supabase cho Flutter.
Yêu cầu:
- Có file supabase_config.dart chứa url và anonKey.
- Có SupabaseService trả về SupabaseClient.
- Code sạch, dễ dùng trong repository.
- Không gọi Supabase trực tiếp trong UI.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- App khởi động không lỗi Supabase.
- Có thể gọi thử `Supabase.instance.client.auth.currentUser`.
- Không để URL/key rải rác trong nhiều file.

---

# PHASE 2 — Core Models

## 2.1. Tạo model Profile

### Bảng liên quan

```text
profiles
```

### Trường dữ liệu

```text
id
email
name
phone
avatar_url
role
is_active
created_at
updated_at
```

### Việc cần làm

Tạo:

```text
features/profile/models/profile_model.dart
```

Model cần có:

- fromJson
- toJson
- copyWith
- enum hoặc helper check role

Helper nên có:

```dart
bool get isAdmin;
bool get isEmployee;
bool get isCustomer;
bool get isStaff;
```

### Prompt AI

```text
Dựa vào bảng profiles của Supabase:
id, email, name, phone, avatar_url, role, is_active, created_at, updated_at.
Hãy tạo ProfileModel trong Flutter.
Yêu cầu:
- fromJson
- toJson
- copyWith
- role helper: isAdmin, isEmployee, isCustomer, isStaff
- null safety đầy đủ.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Parse được dữ liệu profile từ Supabase.
- Không lỗi null khi trường phone/avatar_url rỗng.
- Có thể check role bằng model.

---

## 2.2. Tạo model Product

### Bảng liên quan

```text
products
product_images
categories
brands
```

### Trường dữ liệu chính

```text
id
category_id
brand_id
internal_name
trade_name
barcode
description
price
stock
status
is_featured
created_by
updated_by
deleted_at
deleted_by
created_at
updated_at
```

### Việc cần làm

Tạo:

```text
features/products/models/product_model.dart
features/products/models/product_image_model.dart
```

ProductModel nên có thêm joined fields:

```text
category_name
brand_name
image_urls
```

### Prompt AI

```text
Tạo ProductModel cho Flutter dựa trên bảng products Supabase.
Yêu cầu:
- Hỗ trợ các field: id, categoryId, brandId, internalName, tradeName, barcode, description, price, stock, status, isFeatured, createdBy, updatedBy, deletedAt, deletedBy, createdAt, updatedAt.
- Có joined fields: categoryName, brandName, imageUrls.
- fromJson, toJson, copyWith.
- Helper: isActive, displayName.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- List product parse được từ Supabase.
- Hiển thị được tên sản phẩm.
- Hiển thị được giá, tồn kho, trạng thái.
- Không lỗi khi sản phẩm chưa có ảnh.

---

## 2.3. Tạo model Cart

### Bảng liên quan

```text
carts
cart_items
```

### Việc cần làm

Tạo:

```text
features/cart/models/cart_model.dart
features/cart/models/cart_item_model.dart
```

CartItem cần có:

```text
id
cart_id
product_id
quantity
price_snapshot
created_at
updated_at
product_name
product_image
stock
```

### Prompt AI

```text
Tạo CartModel và CartItemModel cho Flutter dựa trên bảng carts và cart_items.
Yêu cầu:
- CartModel có id, userId, status, createdAt, updatedAt, items.
- CartItemModel có id, cartId, productId, quantity, priceSnapshot, productName, productImage, stock.
- Có getter subtotal = quantity * priceSnapshot.
- Có fromJson, toJson, copyWith.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Lấy được giỏ hàng active của user.
- Tính được tổng tiền giỏ hàng.
- Tăng/giảm số lượng không lỗi.

---

## 2.4. Tạo model Order

### Bảng liên quan

```text
orders
order_items
order_status_logs
```

### Việc cần làm

Tạo:

```text
features/orders/models/order_model.dart
features/orders/models/order_item_model.dart
features/orders/models/order_status_log_model.dart
```

OrderModel cần có helper:

```dart
bool get canCustomerEdit;
bool get canCustomerCancel;
bool get canStaffConfirm;
bool get canStaffShip;
bool get canStaffComplete;
bool get canStaffMarkFailed;
bool get canRequestReturn;
```

### Prompt AI

```text
Tạo OrderModel, OrderItemModel, OrderStatusLogModel cho Flutter.
Dựa theo trạng thái:
pending_confirmation, confirmed, shipping, delivered, delivery_failed, cancelled, return_requested, returned.
Yêu cầu:
- fromJson, toJson, copyWith.
- OrderModel có helper kiểm tra hành động được phép:
canCustomerEdit, canCustomerCancel, canStaffConfirm, canStaffShip, canStaffComplete, canStaffMarkFailed, canRequestReturn.
- Có getter statusLabel tiếng Việt.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Hiển thị được danh sách đơn.
- Hiển thị được chi tiết đơn.
- Nút hành động hiện đúng theo trạng thái.

---

## 2.5. Tạo model Wallet

### Bảng liên quan

```text
wallets
wallet_transactions
```

### Việc cần làm

Tạo:

```text
features/wallet/models/wallet_model.dart
features/wallet/models/wallet_transaction_model.dart
```

### Prompt AI

```text
Tạo WalletModel và WalletTransactionModel cho Flutter.
Wallet gồm id, userId, balance, currency, createdAt, updatedAt.
WalletTransaction gồm id, walletId, userId, type, amount, balanceBefore, balanceAfter, relatedOrderId, relatedReturnOrderId, note, createdAt.
Có helper typeLabel tiếng Việt.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Customer xem được số dư ví.
- Xem được lịch sử giao dịch.
- Format tiền VND đúng.

---

## 2.6. Tạo model Return Order

### Bảng liên quan

```text
return_orders
return_order_items
```

### Prompt AI

```text
Tạo ReturnOrderModel và ReturnOrderItemModel cho Flutter.
Status gồm return_pending, return_approved, return_rejected, return_completed.
Yêu cầu:
- fromJson, toJson, copyWith.
- Có statusLabel tiếng Việt.
- Helper canApprove, canReject, canComplete.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Tạo được yêu cầu trả hàng từ đơn delivered.
- Admin/employee xem được yêu cầu trả hàng.
- Trạng thái trả hàng hiển thị đúng.

---

# PHASE 3 — Authentication Module

## 3.1. Màn hình Login

### Module

```text
M1 – Auth & Quản lý user
```

### Việc cần làm

Tạo:

```text
features/auth/views/login_page.dart
features/auth/viewmodels/auth_viewmodel.dart
features/auth/repositories/auth_repository.dart
```

Chức năng:

- Nhập email.
- Nhập password.
- Login bằng Supabase Auth.
- Sau login lấy profile từ bảng `profiles`.
- Nếu `is_active = false` thì logout và báo lỗi.
- Điều hướng theo role.

### Prompt AI

```text
Tạo module Login Flutter + Supabase theo MVVM + Provider.
Yêu cầu:
- Login bằng email/password.
- Sau login lấy profile từ bảng profiles.
- Nếu is_active = false thì signOut và hiển thị lỗi "Tài khoản đã bị vô hiệu hóa".
- Lưu ProfileModel vào AuthViewModel.
- Có loading, error message.
- Không gọi Supabase trực tiếp trong UI.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Login admin thành công.
- Login employee thành công.
- Login customer thành công.
- User inactive không vào được app.
- Sai mật khẩu hiển thị lỗi rõ ràng.

---

## 3.2. Logout

### Việc cần làm

- Gọi Supabase Auth signOut.
- Clear profile trong AuthViewModel.
- Điều hướng về Login.

### Prompt AI

```text
Thêm chức năng logout cho AuthViewModel.
Khi logout:
- gọi supabase.auth.signOut()
- clear currentProfile
- điều hướng về login
- xử lý loading/error.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Bấm logout thoát tài khoản.
- Không còn dữ liệu profile cũ.
- Mở lại app nếu chưa login thì vào Login.

---

## 3.3. Auth Guard

### Việc cần làm

Dùng `go_router` để chặn route.

Route logic:

```text
not logged in -> /login
logged in -> /dashboard
role admin -> vào admin routes
role employee -> vào employee routes
role customer -> vào customer routes
```

### Prompt AI

```text
Tạo GoRouter cho Flutter app có Auth Guard theo Supabase Auth và ProfileModel.
Yêu cầu:
- Nếu chưa login thì redirect về /login.
- Nếu login rồi thì vào /dashboard.
- Chặn route theo role admin, employee, customer.
- Nếu không đủ quyền thì chuyển về /unauthorized.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Chưa login không vào được dashboard.
- Customer không vào được user management.
- Employee không vào được product create/edit.
- Admin vào được tất cả.

---

# PHASE 4 — Main Layout + Role Menu

## 4.1. MainLayout

### Việc cần làm

Tạo layout chính:

```text
features/main/views/main_layout.dart
```

Có:

- Sidebar hoặc bottom navigation.
- AppBar.
- Logout.
- Thông tin user.
- Menu theo role.

### Menu đề xuất

Admin:

```text
Dashboard
Users
Products
Orders
Returns
Wallets
Profile
```

Employee:

```text
Dashboard
Products
Orders
Returns
Profile
```

Customer:

```text
Products
Cart
My Orders
Wallet
Profile
```

### Prompt AI

```text
Tạo MainLayout Flutter theo role.
Dùng ProfileModel.role để render menu.
Admin thấy Dashboard, Users, Products, Orders, Returns, Wallets, Profile.
Employee thấy Dashboard, Products, Orders, Returns, Profile.
Customer thấy Products, Cart, My Orders, Wallet, Profile.
Yêu cầu UI responsive desktop/web/mobile cơ bản.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Menu admin đầy đủ.
- Menu employee không có Users, không có Product edit.
- Menu customer không thấy chức năng quản trị.
- Logout hoạt động.

---

# PHASE 5 — User Management Module

## 5.1. Danh sách user

### Module

```text
M1 – Auth & Quản lý user
```

### Quyền

Chỉ admin.

### Việc cần làm

Tạo:

```text
features/users/views/user_list_page.dart
features/users/viewmodels/user_viewmodel.dart
features/users/repositories/user_repository.dart
```

Chức năng:

- Load danh sách user từ `profiles`.
- Search theo tên/email.
- Filter theo role.
- Filter theo active/inactive.
- Hiển thị dạng table.

### Prompt AI

```text
Tạo User Management module Flutter + Supabase theo MVVM.
Chỉ admin được truy cập.
Màn user list gồm:
- table danh sách profiles
- search theo name/email
- filter role
- filter is_active
- hiển thị name, email, phone, role, is_active, created_at
- nút edit.
Không gọi Supabase trực tiếp trong UI.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Admin xem được danh sách user.
- Search hoạt động.
- Filter role hoạt động.
- Employee/customer không vào được màn này.

---

## 5.2. Sửa user

### Việc cần làm

Admin sửa được:

```text
name
phone
role
is_active
```

Không sửa trực tiếp password ở đây.

### Prompt AI

```text
Tạo màn Edit User cho admin.
Dữ liệu từ profiles.
Cho sửa:
- name
- phone
- role
- is_active
Không cho sửa email.
Sau khi lưu update bảng profiles.
Có validate name bắt buộc.
Có loading/error/success.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Admin đổi role được.
- Admin khóa user bằng `is_active = false`.
- User bị khóa login không vào được.
- Không sửa nhầm email.

---

## 5.3. Thêm user

### Việc cần làm

Có 2 hướng:

#### Hướng demo nhanh

Tạo user trong Supabase Authentication Console, sau đó insert profile.

#### Hướng app hoàn chỉnh

Dùng Edge Function hoặc Admin API để tạo Auth user.

Vì Supabase client thường không nên tạo user admin trực tiếp từ app bằng service role key, nên trong app demo có thể ghi chú:

```text
Thêm user dùng script seed hoặc Supabase Console.
```

### Prompt AI

```text
Tạo màn hướng dẫn thêm user demo.
Vì app Flutter không dùng service_role key, màn này chỉ cho admin nhập thông tin profile sau khi user đã được tạo trong Supabase Auth.
Hiển thị hướng dẫn:
1. Tạo user trong Supabase Authentication.
2. Copy user id.
3. Tạo profile tương ứng.
Form gồm id, email, name, phone, role, is_active.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Admin tạo profile được cho user Auth đã có.
- Không bị lỗi foreign key `profiles.id references auth.users.id`.
- Có hướng dẫn rõ ràng trên UI.

---

# PHASE 6 — Product Management Module

## 6.1. Product Repository

### Module

```text
M3 – Quản lý sản phẩm
```

### Việc cần làm

Tạo:

```text
features/products/repositories/product_repository.dart
features/products/viewmodels/product_viewmodel.dart
```

Repository cần có:

```text
getProducts()
searchProducts(keyword)
getProductDetail(id)
createProduct()
updateProduct()
softDeleteProduct()
getCategories()
getBrands()
```

### Query cần hỗ trợ

- Pagination 20/trang.
- Search theo `internal_name`, `trade_name`, `barcode`.
- Filter status.
- Filter category/brand.

### Prompt AI

```text
Tạo ProductRepository Flutter dùng Supabase.
Yêu cầu:
- getProducts có pagination 20/trang
- search theo internal_name, trade_name, barcode
- filter status, category_id, brand_id
- getProductDetail join categories, brands, product_images
- createProduct
- updateProduct
- softDeleteProduct bằng status = inactive, deleted_at = now()
Không gọi Supabase trong UI.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Load được danh sách sản phẩm.
- Search barcode/tên hoạt động.
- Pagination hoạt động.
- Soft delete chuyển status inactive.

---

## 6.2. Product List Page

### Quyền

```text
admin: xem, thêm, sửa, inactive
employee: chỉ xem
customer: chỉ xem sản phẩm active
```

### Việc cần làm

Tạo:

```text
features/products/views/product_list_page.dart
```

UI cần có:

- Search box.
- Filter category.
- Filter brand.
- Filter status cho admin/employee.
- Product card/table.
- Pagination.
- Nút add/edit/delete chỉ hiện với admin.

### Prompt AI

```text
Tạo ProductListPage Flutter.
Yêu cầu:
- Dùng ProductViewModel.
- Có search theo tên/barcode.
- Có filter category, brand, status.
- Có pagination 20 sản phẩm/trang.
- Nếu role admin: hiện nút thêm/sửa/inactive.
- Nếu employee: chỉ xem, không hiện nút sửa/xóa.
- Nếu customer: chỉ xem product active và có nút thêm vào giỏ.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Admin thấy nút thêm/sửa/xóa mềm.
- Employee chỉ xem.
- Customer thấy nút thêm vào giỏ.
- Product inactive không hiện cho customer.

---

## 6.3. Product Form

### Việc cần làm

Form thêm/sửa gồm:

```text
internal_name
trade_name
barcode
description
price
stock
category_id
brand_id
status
is_featured
image_url
```

Validate:

```text
internal_name bắt buộc
price >= 0
stock >= 0
barcode không trùng
```

### Prompt AI

```text
Tạo ProductFormPage dùng cho thêm/sửa sản phẩm.
Chỉ admin được dùng.
Field:
internalName, tradeName, barcode, description, price, stock, categoryId, brandId, status, isFeatured, imageUrl.
Validate:
- internalName bắt buộc
- price >= 0
- stock >= 0
Sau khi submit gọi ProductViewModel create/update.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Thêm sản phẩm mới được.
- Sửa sản phẩm được.
- Validate hoạt động.
- Employee/customer không vào được.

---

## 6.4. Product Detail

### Việc cần làm

Hiển thị:

```text
ảnh
tên
barcode
category
brand
giá
tồn kho
mô tả
status
```

Customer có nút:

```text
Thêm vào giỏ
```

### Prompt AI

```text
Tạo ProductDetailPage Flutter.
Hiển thị đầy đủ thông tin sản phẩm, ảnh, category, brand, giá, tồn kho, mô tả, status.
Nếu role customer và product active thì hiện nút Thêm vào giỏ.
Nếu role admin thì hiện nút Sửa.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Xem chi tiết sản phẩm được.
- Customer thêm vào giỏ được.
- Admin chuyển sang form sửa được.

---

# PHASE 7 — Cart Module

## 7.1. Cart Repository

### Module

```text
Customer cart
```

### Việc cần làm

Tạo:

```text
features/cart/repositories/cart_repository.dart
features/cart/viewmodels/cart_viewmodel.dart
```

Repository cần có:

```text
getActiveCart()
createActiveCartIfNotExists()
getCartItems()
addToCart(product, quantity)
updateQuantity(cartItemId, quantity)
removeItem(cartItemId)
clearCart()
```

Khi addToCart:

- Nếu chưa có active cart thì tạo.
- Nếu product đã có trong cart thì tăng quantity.
- Lưu `price_snapshot`.
- Không cho quantity vượt quá stock.

### Prompt AI

```text
Tạo CartRepository và CartViewModel Flutter + Supabase.
Yêu cầu:
- Mỗi customer có một active cart.
- Nếu chưa có cart thì tự tạo.
- addToCart: nếu product đã tồn tại thì tăng quantity.
- Lưu price_snapshot từ products.price.
- Không cho quantity vượt quá products.stock.
- updateQuantity, removeItem, clearCart.
- Tính totalAmount.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Customer thêm sản phẩm vào giỏ được.
- Thêm cùng sản phẩm thì tăng số lượng.
- Không vượt quá tồn kho.
- Xóa item khỏi giỏ được.

---

## 7.2. Cart Page

### Việc cần làm

Màn giỏ hàng có:

- Danh sách item.
- Tăng/giảm số lượng.
- Xóa item.
- Tổng tiền.
- Nút tạo đơn hàng.

### Prompt AI

```text
Tạo CartPage Flutter.
Yêu cầu:
- Hiển thị cart_items kèm thông tin product.
- Có nút tăng/giảm quantity.
- Có nút xóa sản phẩm.
- Hiển thị tổng tiền.
- Có nút "Tạo đơn hàng".
- Nếu giỏ trống hiển thị empty state.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Giỏ hàng hiển thị đúng.
- Tổng tiền đúng.
- Tăng/giảm cập nhật DB.
- Nút tạo đơn chuyển sang màn checkout.

---

# PHASE 8 — Order Module

## 8.1. Checkout / Create Order

### Module

```text
M4 – Quản lý đơn hàng
```

### Việc cần làm

Tạo:

```text
features/orders/views/checkout_page.dart
features/orders/repositories/order_repository.dart
features/orders/viewmodels/order_viewmodel.dart
```

Checkout form:

```text
customer_name
customer_phone
customer_address
note
payment_method = wallet
```

Luồng tạo đơn:

```text
1. Lấy cart active.
2. Lấy cart_items.
3. Kiểm tra tồn kho.
4. Kiểm tra ví đủ tiền.
5. Tạo orders status = pending_confirmation.
6. Tạo order_items snapshot.
7. Trừ ví hoặc set payment_status.
8. Ghi wallet_transactions type = payment.
9. Set cart status = checked_out.
10. Tạo cart active mới nếu cần.
```

Để đơn giản cho demo:

```text
Khi tạo đơn:
- trừ ví ngay
- payment_status = paid
- chưa trừ kho
```

### Prompt AI

```text
Tạo chức năng Checkout từ cart sang order trong Flutter + Supabase.
Yêu cầu:
- Customer nhập tên, phone, địa chỉ, ghi chú.
- Lấy active cart và cart_items.
- Kiểm tra sản phẩm còn active và stock đủ.
- Kiểm tra wallet.balance >= tổng tiền.
- Tạo orders với status pending_confirmation, payment_method wallet, payment_status paid.
- Tạo order_items với snapshot tên sản phẩm, barcode, giá, số lượng.
- Trừ wallets.balance.
- Tạo wallet_transactions type payment.
- Đổi cart.status = checked_out.
- Xử lý transaction an toàn nhất có thể.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Customer tạo đơn từ giỏ được.
- Ví bị trừ tiền.
- Order có order_items.
- Cart cũ thành checked_out.
- Stock chưa bị trừ ở bước này.

---

## 8.2. My Orders cho Customer

### Việc cần làm

Tạo:

```text
features/orders/views/my_orders_page.dart
```

Customer xem:

- Danh sách đơn của mình.
- Filter status.
- Search order_code.
- Xem chi tiết.
- Hủy đơn nếu `pending_confirmation`.
- Cập nhật thông tin đơn nếu `pending_confirmation`.

### Prompt AI

```text
Tạo MyOrdersPage cho customer.
Yêu cầu:
- Chỉ load orders có customer_id = current user id.
- Có filter status.
- Có search order_code.
- Hiển thị order_code, statusLabel, totalAmount, createdAt.
- Nếu status pending_confirmation thì hiện nút hủy và sửa thông tin giao hàng.
- Không cho sửa/hủy khi confirmed/shipping/delivered.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Customer chỉ thấy đơn của mình.
- Hủy đơn pending được.
- Không hủy được đơn shipping.
- Sửa thông tin giao hàng khi pending được.

---

## 8.3. Order Management cho Admin/Employee

### Quyền

```text
admin: quản lý tất cả đơn
employee: quản lý tất cả đơn
customer: không vào được
```

### Việc cần làm

Tạo:

```text
features/orders/views/order_management_page.dart
```

Chức năng:

- Xem tất cả đơn.
- Filter status.
- Filter thời gian.
- Search order_code / customer_name / customer_phone.
- Vào chi tiết đơn.
- Cập nhật trạng thái hợp lệ.

### Prompt AI

```text
Tạo OrderManagementPage cho admin/employee.
Yêu cầu:
- Load tất cả orders.
- Có filter status.
- Có filter khoảng thời gian.
- Search order_code, customer_name, customer_phone.
- Table hiển thị order_code, customer, totalAmount, status, paymentStatus, createdAt.
- Có nút xem chi tiết.
- Customer không truy cập được.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Admin/employee xem tất cả đơn.
- Search/filter hoạt động.
- Customer bị chặn.
- Click đơn mở chi tiết.

---

## 8.4. Order Detail + Status Actions

### Việc cần làm

Tạo:

```text
features/orders/views/order_detail_page.dart
```

Hiển thị:

- Thông tin khách.
- Danh sách sản phẩm.
- Tổng tiền.
- Trạng thái đơn.
- Lịch sử trạng thái.
- Nút hành động theo status.

Luồng hành động:

```text
pending_confirmation -> confirmed
confirmed -> shipping
shipping -> delivered
shipping -> delivery_failed
pending_confirmation -> cancelled
delivered -> return_requested
```

### Prompt AI

```text
Tạo OrderDetailPage cho Flutter.
Yêu cầu:
- Hiển thị thông tin order, order_items, order_status_logs.
- Admin/employee thấy nút:
  pending_confirmation: Xác nhận đơn
  confirmed: Chuyển sang đang giao
  shipping: Giao thành công, Giao thất bại
- Customer thấy nút:
  pending_confirmation: Hủy đơn, Sửa thông tin giao hàng
  delivered: Yêu cầu trả hàng
- Mỗi action gọi OrderViewModel.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Nút hiện đúng theo trạng thái.
- Cập nhật trạng thái đúng.
- Ghi được order_status_logs.
- Không cho chuyển trạng thái sai.

---

## 8.5. Business Logic cập nhật trạng thái

### Nghiệp vụ cần xử lý

#### Xác nhận đơn

```text
pending_confirmation -> confirmed
```

Việc cần làm:

- Update `orders.status = confirmed`.
- Set `confirmed_by`.
- Set `confirmed_at`.
- Ghi `order_status_logs`.

#### Chuyển sang đang giao

```text
confirmed -> shipping
```

Việc cần làm:

- Kiểm tra stock đủ.
- Trừ `products.stock`.
- Ghi `inventory_transactions` type `sale_deduct`.
- Update `orders.status = shipping`.
- Set `shipped_by`.
- Set `shipping_at`.
- Ghi `order_status_logs`.

#### Giao thành công

```text
shipping -> delivered
```

Việc cần làm:

- Update `orders.status = delivered`.
- Set `completed_by`.
- Set `completed_at`.
- Ghi `order_status_logs`.
- Ghi `revenue_transactions` type `sale`.

#### Giao thất bại

```text
shipping -> delivery_failed
```

Việc cần làm:

- Cộng lại `products.stock`.
- Ghi `inventory_transactions` type `delivery_failed_restore`.
- Hoàn tiền vào ví nếu payment_status = paid.
- Ghi `wallet_transactions` type `refund`.
- Update `payment_status = refunded`.
- Update `orders.status = delivery_failed`.
- Ghi `order_status_logs`.

#### Hủy đơn

```text
pending_confirmation -> cancelled
```

Việc cần làm:

- Chỉ cho customer/admin/employee hủy khi pending.
- Nếu đã paid thì hoàn tiền.
- Update status cancelled.
- Set cancelled_by, cancelled_at, cancelled_reason.
- Ghi order_status_logs.

### Prompt AI

```text
Viết OrderRepository xử lý các action:
confirmOrder, shipOrder, completeDelivery, failDelivery, cancelOrder.
Dựa vào Supabase schema:
orders, order_items, products, inventory_transactions, wallets, wallet_transactions, revenue_transactions, order_status_logs.
Yêu cầu:
- Chỉ cho chuyển trạng thái hợp lệ.
- Khi shipOrder thì trừ kho và ghi inventory_transactions sale_deduct.
- Khi completeDelivery thì ghi revenue_transactions sale.
- Khi failDelivery thì cộng lại kho, hoàn tiền ví, ghi wallet_transactions refund.
- Khi cancelOrder từ pending_confirmation thì hoàn tiền nếu đã paid.
- Mỗi lần đổi status đều ghi order_status_logs.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- confirmed không trừ kho.
- shipping có trừ kho.
- delivered ghi doanh thu.
- delivery_failed cộng lại kho và hoàn tiền.
- cancelled hoàn tiền nếu đã paid.
- Log trạng thái đầy đủ.

---

# PHASE 9 — Return Order Module

## 9.1. Customer tạo yêu cầu trả hàng

### Module

```text
Return order
```

### Điều kiện

Chỉ cho trả hàng khi:

```text
orders.status = delivered
```

### Việc cần làm

Tạo:

```text
features/returns/views/create_return_page.dart
features/returns/repositories/return_repository.dart
features/returns/viewmodels/return_viewmodel.dart
```

Form:

```text
reason
chọn sản phẩm muốn trả
quantity
```

Luồng:

```text
1. Customer chọn đơn delivered.
2. Nhập lý do.
3. Chọn item muốn trả.
4. Tạo return_orders status return_pending.
5. Tạo return_order_items.
6. Update orders.status = return_requested.
```

### Prompt AI

```text
Tạo chức năng customer yêu cầu trả hàng.
Điều kiện:
- Chỉ order status delivered mới được trả.
Yêu cầu:
- Tạo return_orders status return_pending.
- Tạo return_order_items từ order_items được chọn.
- Tính total_refund_amount.
- Update orders.status = return_requested.
- Ghi log nếu cần.
- UI cho chọn sản phẩm và quantity trả.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Customer tạo return request từ order delivered.
- Không tạo được return từ order chưa delivered.
- Return có item và tổng tiền hoàn.
- Order chuyển `return_requested`.

---

## 9.2. Admin/Employee quản lý trả hàng

### Việc cần làm

Tạo:

```text
features/returns/views/return_management_page.dart
features/returns/views/return_detail_page.dart
```

Chức năng:

- Xem danh sách yêu cầu trả hàng.
- Filter status.
- Xem chi tiết.
- Duyệt.
- Từ chối.
- Hoàn tất trả hàng.

### Prompt AI

```text
Tạo ReturnManagementPage và ReturnDetailPage cho admin/employee.
Yêu cầu:
- Load return_orders join orders/profiles.
- Filter theo status.
- Xem return_order_items.
- Có nút Approve, Reject, Complete tùy status.
- Customer không truy cập được.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Admin/employee thấy danh sách trả hàng.
- Xem chi tiết được.
- Customer không vào được.
- Nút hiện đúng theo status.

---

## 9.3. Xử lý duyệt trả hàng

### Luồng

#### Approve

```text
return_pending -> return_approved
```

Việc cần làm:

- Set approved_by.
- Set approved_at.

#### Reject

```text
return_pending -> return_rejected
```

Việc cần làm:

- Set rejected_by.
- Set rejected_at.
- Có note lý do.
- Có thể đưa order về `delivered`.

#### Complete

```text
return_approved -> return_completed
```

Việc cần làm:

- Cộng lại `products.stock`.
- Ghi `inventory_transactions` type `return_restore`.
- Hoàn tiền vào ví.
- Ghi `wallet_transactions` type `refund`.
- Ghi `revenue_transactions` type `refund`.
- Update order status `returned`.
- Update payment_status `refunded` hoặc `partially_refunded`.

### Prompt AI

```text
Viết ReturnRepository xử lý:
approveReturn, rejectReturn, completeReturn.
Yêu cầu:
- approve: update return_orders status return_approved, approved_by, approved_at.
- reject: update status return_rejected, rejected_by, rejected_at, note, đưa order về delivered.
- complete: cộng lại products.stock, ghi inventory_transactions return_restore, hoàn tiền ví, ghi wallet_transactions refund, ghi revenue_transactions refund, update order status returned.
- Chỉ admin/employee được xử lý.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Approve đổi status đúng.
- Reject không hoàn tiền/không cộng kho.
- Complete cộng kho đúng.
- Complete hoàn tiền vào ví.
- Complete ghi doanh thu refund.
- Order chuyển returned.

---

# PHASE 10 — Wallet Module

## 10.1. Customer Wallet Page

### Việc cần làm

Tạo:

```text
features/wallet/views/wallet_page.dart
features/wallet/repositories/wallet_repository.dart
features/wallet/viewmodels/wallet_viewmodel.dart
```

Hiển thị:

- Số dư ví.
- Lịch sử giao dịch.
- Loại giao dịch.
- Số tiền.
- Ghi chú.
- Ngày tạo.

### Prompt AI

```text
Tạo WalletPage cho customer.
Yêu cầu:
- Load wallets theo current user.
- Load wallet_transactions theo wallet_id.
- Hiển thị balance format VND.
- Hiển thị lịch sử deposit/payment/refund/manual_adjustment.
- Có empty state nếu chưa có giao dịch.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Customer xem được ví của mình.
- Không xem được ví người khác.
- Lịch sử giao dịch đúng.
- Format tiền VND đúng.

---

## 10.2. Admin cộng tiền ví demo

### Việc cần làm

Để dễ demo, admin có thể cộng tiền ví cho customer.

Chức năng:

- Chọn customer.
- Nhập số tiền.
- Update `wallets.balance`.
- Ghi `wallet_transactions` type `deposit`.

### Prompt AI

```text
Tạo chức năng admin nạp tiền ví demo cho customer.
Yêu cầu:
- Chỉ admin được dùng.
- Chọn customer.
- Nhập amount > 0.
- Update wallets.balance.
- Ghi wallet_transactions type deposit, balance_before, balance_after.
- Hiển thị success/error.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Admin cộng tiền được.
- Customer thấy balance tăng.
- Có lịch sử deposit.
- Employee/customer không dùng được.

---

# PHASE 11 — Profile Module

## 11.1. Profile Page

### Module

```text
M5 – Trang cá nhân
```

### Việc cần làm

Tạo:

```text
features/profile/views/profile_page.dart
features/profile/repositories/profile_repository.dart
features/profile/viewmodels/profile_viewmodel.dart
```

Hiển thị:

```text
email readonly
role readonly
name editable
phone editable
avatar_url editable
```

### Prompt AI

```text
Tạo ProfilePage Flutter.
Yêu cầu:
- Hiển thị email readonly.
- Hiển thị role readonly.
- Cho sửa name, phone, avatar_url.
- Update bảng profiles.
- Sau khi update đồng bộ lại AuthViewModel.currentProfile.
- Có loading/error/success.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- User sửa name/phone/avatar được.
- Email không sửa được.
- Role không sửa được.
- MainLayout cập nhật tên mới.

---

## 11.2. Đổi mật khẩu

### Việc cần làm

Sử dụng Supabase:

```dart
supabase.auth.updateUser(
  UserAttributes(password: newPassword),
);
```

Form:

```text
new_password
confirm_password
```

Có thể thêm re-auth nếu cần.

### Prompt AI

```text
Tạo chức năng đổi mật khẩu trong ProfilePage.
Yêu cầu:
- Nhập newPassword và confirmPassword.
- Validate password >= 6 ký tự.
- Confirm phải trùng.
- Gọi supabase.auth.updateUser(UserAttributes(password: newPassword)).
- Hiển thị success/error.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Đổi mật khẩu thành công.
- Password ngắn báo lỗi.
- Confirm sai báo lỗi.
- Login lại bằng mật khẩu mới được.

---

# PHASE 12 — Dashboard Module

## 12.1. Dashboard Admin/Employee

### Việc cần làm

Tạo:

```text
features/dashboard/views/dashboard_page.dart
features/dashboard/repositories/dashboard_repository.dart
features/dashboard/viewmodels/dashboard_viewmodel.dart
```

Hiển thị:

- Tổng số đơn.
- Đơn chờ xác nhận.
- Đơn đang giao.
- Đơn giao thành công.
- Doanh thu.
- Số sản phẩm active.
- Sản phẩm sắp hết hàng.

### Prompt AI

```text
Tạo Dashboard cho admin/employee.
Yêu cầu:
- Hiển thị tổng đơn hàng.
- Số đơn pending_confirmation.
- Số đơn shipping.
- Số đơn delivered.
- Doanh thu từ revenue_transactions type sale trừ refund.
- Số sản phẩm active.
- Danh sách sản phẩm stock thấp hơn 5.
- UI dạng card.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Dashboard load số liệu đúng.
- Doanh thu đúng sau delivered.
- Refund làm giảm doanh thu.
- Stock thấp hiển thị đúng.

---

## 12.2. Dashboard Customer

### Việc cần làm

Customer dashboard có thể đơn giản:

- Số dư ví.
- Số đơn của tôi.
- Đơn đang chờ.
- Đơn đang giao.
- Sản phẩm nổi bật.

### Prompt AI

```text
Tạo CustomerDashboardPage.
Yêu cầu:
- Hiển thị số dư ví.
- Số đơn của user.
- Số đơn pending_confirmation.
- Số đơn shipping.
- Danh sách sản phẩm is_featured và active.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Customer thấy dashboard riêng.
- Không thấy dữ liệu của người khác.
- Product featured hiển thị đúng.

---

# PHASE 13 — Storage Module

## 13.1. Upload avatar

### Việc cần làm

Supabase Storage bucket:

```text
avatars
```

Luồng:

```text
1. User chọn ảnh.
2. Upload vào bucket avatars.
3. Lấy public URL.
4. Update profiles.avatar_url.
```

### Prompt AI

```text
Tạo chức năng upload avatar bằng Supabase Storage.
Yêu cầu:
- Dùng image_picker.
- Upload ảnh vào bucket avatars.
- File path theo userId/timestamp.
- Lấy public URL.
- Update profiles.avatar_url.
- Hiển thị ảnh mới trên ProfilePage.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Chọn ảnh được.
- Upload thành công.
- Avatar hiển thị lại sau reload app.

---

## 13.2. Upload product image

### Quyền

Chỉ admin.

### Bucket

```text
product-images
```

### Prompt AI

```text
Tạo chức năng upload ảnh sản phẩm cho admin.
Yêu cầu:
- Upload ảnh vào bucket product-images.
- Lấy public URL.
- Insert vào product_images gồm product_id, image_url, sort_order.
- ProductDetail hiển thị ảnh.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Admin upload ảnh sản phẩm được.
- Product list/detail hiển thị ảnh.
- Employee/customer chỉ xem ảnh, không upload.

---

# PHASE 14 — Seed Data / Mock Data

## 14.1. Tạo dữ liệu demo

### Dữ liệu cần có

User:

```text
admin@gmail.com
employee@gmail.com
customer@gmail.com
```

Data:

```text
3 categories
4 brands
10 products
wallet cho customer
1 cart demo optional
2 orders demo optional
```

### Prompt AI

```text
Viết file seed_data.sql cho Supabase dựa trên schema hiện tại.
Yêu cầu:
- Không tạo auth.users trực tiếp.
- Giả sử tôi đã có UUID của admin, employee, customer.
- Insert profiles, wallets, categories, brands, products, product_images.
- Có comment rõ chỗ cần thay UUID.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Chạy seed không lỗi.
- App có sản phẩm để hiển thị.
- Customer có ví tiền.
- Admin/employee/customer login test được.

---

# PHASE 15 — Testing theo luồng demo

## 15.1. Test Auth

### Checklist

- [ ] Login admin thành công.
- [ ] Login employee thành công.
- [ ] Login customer thành công.
- [ ] Sai mật khẩu báo lỗi.
- [ ] User inactive không vào được.
- [ ] Logout thành công.

### Hoàn thành khi

Tất cả checklist pass.

---

## 15.2. Test phân quyền

### Checklist

Admin:

- [ ] Vào được User Management.
- [ ] Vào được Product Management.
- [ ] Vào được Order Management.
- [ ] Vào được Return Management.
- [ ] Vào được Wallet Management.

Employee:

- [ ] Không thấy User Management.
- [ ] Không thấy Product Create/Edit.
- [ ] Vào được Orders.
- [ ] Vào được Returns.
- [ ] Xem được Products.

Customer:

- [ ] Không thấy module admin.
- [ ] Xem được Products.
- [ ] Vào được Cart.
- [ ] Vào được My Orders.
- [ ] Vào được Wallet.

### Hoàn thành khi

Không role nào truy cập được sai quyền.

---

## 15.3. Test Product

### Checklist

- [ ] Admin thêm sản phẩm được.
- [ ] Admin sửa sản phẩm được.
- [ ] Admin inactive sản phẩm được.
- [ ] Employee chỉ xem.
- [ ] Customer chỉ thấy sản phẩm active.
- [ ] Search tên hoạt động.
- [ ] Search barcode hoạt động.
- [ ] Pagination hoạt động.

### Hoàn thành khi

Product module hoạt động đúng theo role.

---

## 15.4. Test Cart

### Checklist

- [ ] Customer thêm sản phẩm vào giỏ.
- [ ] Thêm cùng sản phẩm thì tăng số lượng.
- [ ] Không cho số lượng vượt stock.
- [ ] Tăng/giảm quantity được.
- [ ] Xóa item được.
- [ ] Tổng tiền đúng.

### Hoàn thành khi

Cart không lỗi và tổng tiền chính xác.

---

## 15.5. Test Order Flow chính

### Luồng chuẩn

```text
customer tạo đơn
-> pending_confirmation
admin/employee xác nhận
-> confirmed
admin/employee chuyển đang giao
-> shipping
admin/employee giao thành công
-> delivered
```

### Checklist

- [ ] Customer tạo đơn từ cart được.
- [ ] Ví customer bị trừ tiền.
- [ ] Stock chưa trừ khi pending.
- [ ] Confirm không trừ stock.
- [ ] Shipping trừ stock.
- [ ] Delivered ghi revenue.
- [ ] Order status log có đủ lịch sử.

### Hoàn thành khi

Luồng mua hàng chuẩn chạy không sai tiền, không sai kho.

---

## 15.6. Test Cancel Order

### Checklist

- [ ] Customer hủy được đơn pending_confirmation.
- [ ] Customer không hủy được đơn confirmed.
- [ ] Customer không hủy được đơn shipping.
- [ ] Khi hủy pending, nếu đã paid thì hoàn tiền.
- [ ] Ghi wallet_transactions refund.
- [ ] Ghi order_status_logs.

### Hoàn thành khi

Hủy đơn đúng trạng thái và hoàn tiền đúng.

---

## 15.7. Test Delivery Failed

### Checklist

- [ ] Shipping chuyển được sang delivery_failed.
- [ ] Stock được cộng lại.
- [ ] Ví customer được hoàn tiền.
- [ ] payment_status chuyển refunded.
- [ ] Không ghi revenue sale.
- [ ] Có inventory transaction restore.
- [ ] Có wallet transaction refund.

### Hoàn thành khi

Giao thất bại khôi phục kho và tiền đúng.

---

## 15.8. Test Return Order

### Checklist

- [ ] Chỉ order delivered mới tạo return.
- [ ] Customer tạo return request được.
- [ ] Order chuyển return_requested.
- [ ] Admin/employee approve được.
- [ ] Admin/employee reject được.
- [ ] Complete return cộng lại kho.
- [ ] Complete return hoàn tiền ví.
- [ ] Complete return ghi revenue refund.
- [ ] Order chuyển returned.

### Hoàn thành khi

Trả hàng chạy đúng từ request đến hoàn tất.

---

## 15.9. Test Wallet

### Checklist

- [ ] Customer xem được ví của mình.
- [ ] Customer không xem ví người khác.
- [ ] Admin nạp tiền demo được.
- [ ] Payment khi tạo order trừ tiền.
- [ ] Cancel hoàn tiền.
- [ ] Delivery failed hoàn tiền.
- [ ] Return completed hoàn tiền.
- [ ] Transaction history đúng.

### Hoàn thành khi

Số dư ví luôn đúng với lịch sử giao dịch.

---

# PHASE 16 — UI Polish

## 16.1. Chuẩn hóa trạng thái loading/error/empty

### Việc cần làm

Tạo widget dùng chung:

```text
LoadingWidget
ErrorStateWidget
EmptyStateWidget
AppButton
AppTextField
StatusBadge
PriceText
```

### Prompt AI

```text
Tạo bộ widget dùng chung cho Flutter:
- LoadingWidget
- ErrorStateWidget
- EmptyStateWidget
- AppButton
- AppTextField
- StatusBadge
- PriceText format VND
Yêu cầu UI đồng bộ, dễ tái sử dụng.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Các màn hình không còn loading/error/empty rời rạc.
- UI nhất quán.

---

## 16.2. Status badge tiếng Việt

### Mapping order status

```text
pending_confirmation = Chờ xác nhận
confirmed = Đã xác nhận
shipping = Đang giao hàng
delivered = Giao thành công
delivery_failed = Giao thất bại
cancelled = Đã hủy
return_requested = Yêu cầu trả hàng
returned = Đã trả hàng
```

### Mapping return status

```text
return_pending = Chờ duyệt
return_approved = Đã duyệt
return_rejected = Từ chối
return_completed = Hoàn tất
```

### Prompt AI

```text
Tạo StatusBadge widget cho order status và return status.
Input là status string.
Output là label tiếng Việt.
Có màu khác nhau cho từng trạng thái.
```

### Đánh giá hoàn thành

Hoàn thành khi:

- Tất cả trạng thái hiển thị tiếng Việt.
- Người dùng dễ hiểu trạng thái.

---

# PHASE 17 — Final Review

## 17.1. Review code

### Checklist

- [ ] Không gọi Supabase trực tiếp trong View.
- [ ] Repository xử lý data.
- [ ] ViewModel xử lý state.
- [ ] Model đầy đủ fromJson/toJson.
- [ ] Không hard-code role lung tung.
- [ ] Có loading/error.
- [ ] Có validate form.
- [ ] Không để service_role key trong Flutter app.
- [ ] Không cho customer truy cập dữ liệu người khác.

---

## 17.2. Review database

### Checklist

- [ ] RLS đã bật.
- [ ] Policy cơ bản hoạt động.
- [ ] Profiles liên kết đúng auth.users.
- [ ] Products có active/inactive.
- [ ] Orders có status đúng.
- [ ] Order items có snapshot.
- [ ] Wallet transaction ghi đủ.
- [ ] Inventory transaction ghi đủ.
- [ ] Revenue transaction ghi đủ.
- [ ] Return order hoạt động.

---

## 17.3. Review demo script

### Kịch bản demo đề xuất

#### Bước 1: Admin login

```text
admin@gmail.com
```

Demo:

- Xem dashboard.
- Xem user.
- Thêm/sửa sản phẩm.
- Xem đơn hàng.

#### Bước 2: Customer login

```text
customer@gmail.com
```

Demo:

- Xem sản phẩm.
- Thêm vào giỏ.
- Checkout.
- Xem ví bị trừ.
- Xem đơn chờ xác nhận.

#### Bước 3: Employee login

```text
employee@gmail.com
```

Demo:

- Xem đơn.
- Xác nhận đơn.
- Chuyển đang giao.
- Giao thành công.

#### Bước 4: Customer return

Demo:

- Customer yêu cầu trả hàng.
- Employee duyệt trả hàng.
- Hoàn tiền.
- Cộng lại kho.

### Hoàn thành khi

Có thể demo trọn vẹn trong 5–10 phút không lỗi.

---

# PHASE 18 — Thứ tự làm thực tế khuyến nghị

Làm theo thứ tự này để ít lỗi nhất:

```text
1. Setup Supabase + project structure
2. Models
3. Auth login/logout
4. Auth guard + MainLayout
5. Profile page
6. Product list
7. Product CRUD admin
8. Cart
9. Checkout tạo order
10. My Orders customer
11. Order management admin/employee
12. Order status actions
13. Wallet page
14. Return order
15. Dashboard
16. Storage image
17. Seed data
18. Full testing
19. UI polish
20. Demo script
```

---

# PHASE 19 — Definition of Done toàn dự án

Dự án được xem là hoàn thành khi:

- [ ] Admin quản lý được user.
- [ ] Admin quản lý được sản phẩm.
- [ ] Employee xem được sản phẩm nhưng không sửa được.
- [ ] Employee xử lý được đơn hàng.
- [ ] Customer xem sản phẩm, thêm giỏ, tạo đơn.
- [ ] Customer hủy/sửa đơn khi chờ xác nhận.
- [ ] Customer không sửa/hủy khi đang giao.
- [ ] Khi shipping thì kho bị trừ.
- [ ] Khi delivered thì doanh thu tăng.
- [ ] Khi delivery_failed thì kho được cộng lại và tiền hoàn ví.
- [ ] Khi return_completed thì kho được cộng lại và tiền hoàn ví.
- [ ] Role-based menu hoạt động.
- [ ] Route guard hoạt động.
- [ ] RLS không để lộ dữ liệu nhạy cảm.
- [ ] UI có loading/error/empty.
- [ ] Demo chạy được từ đầu đến cuối.

---

# PHASE 20 — Prompt tổng để đưa AI code từng phần

Khi làm từng module, dùng format prompt này:

```text
Tôi đang xây dựng app Flutter + Supabase theo MVVM + Provider.

Database đã có các bảng:
profiles, wallets, wallet_transactions, categories, brands, products, product_images, carts, cart_items, orders, order_items, order_status_logs, inventory_transactions, return_orders, return_order_items, revenue_transactions.

Role:
- admin: full quyền
- employee: xem sản phẩm, xử lý đơn hàng, xử lý trả hàng
- customer: xem sản phẩm, giỏ hàng, đơn hàng cá nhân, ví

Hãy code module [TÊN MODULE].
Yêu cầu:
1. Không gọi Supabase trực tiếp trong UI.
2. Có Model, Repository, ViewModel, View.
3. Có loading/error/empty state.
4. Có validate form nếu có input.
5. Có phân quyền theo role.
6. Code sạch, null safety, dễ mở rộng.
7. Giải thích ngắn cách tích hợp vào router/main layout.

Schema liên quan:
[DÁN TÊN BẢNG + FIELD Ở ĐÂY]

Nghiệp vụ:
[MÔ TẢ NGHIỆP VỤ Ở ĐÂY]

Sau khi code xong, đưa checklist test module đó.
```

---

# Ghi chú quan trọng

## Không nên làm

- Không lưu service_role key trong Flutter app.
- Không để customer update trực tiếp stock.
- Không để customer tự update order status ngoài cancel pending.
- Không xóa cứng sản phẩm/user/order.
- Không tính doanh thu từ đơn chưa delivered.
- Không trừ kho khi mới tạo đơn.
- Không trừ kho lần hai khi delivered.

## Nên làm

- Snapshot giá/tên sản phẩm vào order_items.
- Ghi log trạng thái đơn hàng.
- Ghi transaction ví.
- Ghi transaction kho.
- Dùng status rõ ràng.
- Dùng RLS + route guard + UI guard cùng lúc.
