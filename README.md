# DuyuScript Roblox Hub — bản nâng cấp độc lập

Đây là website mới, không lấy code, database, Supabase project hay Admin của website DuyuScript cũ. Frontend dùng HTML/CSS/JavaScript; backend dữ liệu và xác thực dùng **một Supabase project mới**. Có thể triển khai frontend trên Netlify.

## Chức năng
- Giao diện responsive, thư viện Script, tìm kiếm, lọc danh mục, sắp xếp, Script nổi bật và mới nhất.
- Trang chi tiết theo Script, mã nguồn, copy, tải `.lua`, liên kết chia sẻ, Discord riêng.
- Thống kê lượt xem/tải, tổng quan trên trang chủ và Admin.
- Bình luận/đánh giá không cần tài khoản thành viên; mọi đánh giá mới ở trạng thái chờ duyệt.
- Admin đăng nhập qua Supabase Auth; chỉ UUID được thêm thủ công vào `admin_users` mới có quyền CRUD/duyệt.
- Quản lý Script, danh mục, duyệt/ẩn/xóa đánh giá, xuất JSON backup.
- RLS policies, RPC tăng lượt xem/tải, security headers.

> Nội dung demo chỉ để xem giao diện, không phải script đã kiểm chứng hoặc bảo đảm hoạt động. Website không xác minh độ an toàn của mã do người dùng cung cấp. Không đăng tải mã đánh cắp thông tin, token/cookie, mã độc, cheat/exploit hoặc nội dung vi phạm điều khoản Roblox. Chỉ chia sẻ tài nguyên bạn có quyền phân phối.

## A. Chạy thử giao diện
1. Giải nén ZIP.
2. Mở thư mục `DuyuScript-Roblox-Complete-2026`.
3. Chạy `py -m http.server 8000` trong Terminal tại thư mục này.
4. Mở `http://localhost:8000`.

Khi chưa cấu hình Supabase, trang dùng dữ liệu demo. Admin sẽ không cho đăng nhập giả lập và không có mật khẩu mặc định.

## B. Tạo backend Supabase hoàn toàn mới
1. Tạo một project Supabase mới tại https://supabase.com/dashboard. Đặt tên riêng, ví dụ `duyuscript-roblox-hub-2026`. Không chọn hoặc dùng lại project cũ.
2. Mở **SQL Editor → New query**, dán toàn bộ `supabase/schema.sql`, chạy.
3. Mở **Project Settings → API** (hoặc API Keys), sao chép Project URL và public anon/publishable key.
4. Sao chép `config.example.js` thành `config.js`, điền Project URL và public anon/publishable key. `index.html` sẽ tự tải `config.js` trước `app.js`. File này chỉ chứa thông tin công khai nên cần được đưa lên bản deploy (có thể commit cùng GitHub); tuyệt đối không đưa `service_role`/secret key vào frontend.
5. Trong Supabase **Authentication → Providers → Email**, bật Email provider. Không tạo form đăng ký công khai trên website.
6. Trong **Authentication → Users**, tạo một user Admin với email của bạn và mật khẩu mạnh.
7. Sao chép UUID của user vừa tạo. Mở SQL Editor và chạy lệnh dưới đây sau khi thay UUID:

```sql
insert into public.admin_users(user_id)
values ('UUID-CUA-ADMIN');
```

8. Quay lại website, đăng nhập qua nút Admin. Nếu user không có trong `admin_users`, hệ thống từ chối quyền quản trị dù đăng nhập Auth thành công.
9. Vào Admin → Quản lý Script để tạo nội dung đầu tiên. Slug phải duy nhất. Đặt trạng thái `Công khai` để xuất hiện ở thư viện.

## C. Triển khai Netlify
1. Đưa toàn bộ thư mục project lên GitHub, bao gồm `config.js`. File này chỉ được chứa Project URL và public anon/publishable key — đây là khóa công khai dùng trong trình duyệt, không phải secret. Không đưa secret/service_role key vào GitHub.
2. Trong Netlify chọn **Add new site → Import an existing project**, kết nối repository.
3. Build command để trống; Publish directory đặt `.`.
4. Deploy. Mở domain Netlify để kiểm tra trang chủ, thư viện, chi tiết, đánh giá và Admin.
5. Nếu đổi domain, cập nhật Authentication → URL Configuration trong Supabase: Site URL và Redirect URLs. Dùng HTTPS.

## D. Kiểm tra bảo mật trước khi công khai
- Xác nhận `config.js` chỉ chứa Project URL và public anon/publishable key; tuyệt đối không có `service_role`/secret key. Mở trang đã deploy và kiểm tra `window.DUYU_CONFIG` đã được nạp (Developer Tools → Console).
- Đăng nhập bằng tài khoản thường (không có UUID trong `admin_users`): không thể tạo/sửa/xóa Script hoặc duyệt review.
- Thử gửi review công khai: review mới phải có `is_visible=false` và chưa xuất hiện ngoài trang; Admin mới duyệt được.
- Kiểm tra bảng `scripts`, `reviews`, `admin_users` đều bật RLS.
- Tạo backup JSON định kỳ từ Admin và backup database trong Supabase.
- Giới hạn quyền truy cập Dashboard Supabase; bật MFA cho tài khoản chủ project.
- Cân nhắc bật CAPTCHA/Turnstile và giới hạn tần suất gửi review trước khi website có lượng truy cập lớn. RLS không tự chống spam nhiều request.

## E. Nhạc nền YouTube
Trình duyệt hiện đại thường chặn autoplay có âm thanh. Nút Nhạc trong bản này có thông báo hướng dẫn thay vì tự phát âm thanh giả. Nếu muốn nhạc, cần thêm YouTube IFrame Player chính thức và chỉ phát sau khi khách chủ động bấm nút; video có thể không phát nếu bị chủ sở hữu chặn nhúng. Link tham khảo: https://www.youtube.com/watch?v=z_6KKh8LEVo

## Lưu ý triển khai
Đây là bản source đầy đủ cho frontend và SQL backend, nhưng vẫn cần bạn tạo project Supabase, điền config và tạo Admin theo hướng dẫn. Không có cách an toàn để website tự cấp quyền Admin từ trình duyệt. Các đánh giá công khai chưa có CAPTCHA/rate limit server-side trong bản này; bật Turnstile hoặc một endpoint có rate limit trước khi mở lượng truy cập lớn.
