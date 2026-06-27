# ĐẶC TẢ TỔNG THỂ HỆ THỐNG THI TRẮC NGHIỆM TRỰC TUYẾN

## 1. Tên dự án tạm thời

**Quizopia – Hệ thống quản lý học tập và thi trắc nghiệm trực tuyến**

Tên sản phẩm có thể đổi sau. Trong mã nguồn có thể sử dụng tên ngắn:

```text
Quizopia
```

---

# 2. Mục tiêu dự án

Xây dựng một nền tảng thi trắc nghiệm trực tuyến phục vụ giáo viên, học sinh và cán bộ quản lý, hỗ trợ toàn bộ quy trình:

```text
Quản lý lớp và môn học
    → Quản lý tài liệu, đề cương
    → Tạo ngân hàng câu hỏi hoặc import Excel
    → Tạo đề và cấu hình ca thi
    → Học sinh làm bài có autosave
    → Giám sát quá trình làm bài real-time
    → Nộp bài an toàn, chống trùng
    → Tự động chấm điểm
    → Công bố kết quả
    → Thống kê và xuất bảng điểm Excel
```

Hệ thống phải bảo đảm:

* Có thể khởi chạy toàn bộ bằng Docker.
* Có xác thực và giới hạn quyền chặt chẽ.
* Không làm lộ đáp án đúng cho học sinh.
* Không mất bài khi học sinh mất kết nối ngắn hạn.
* Không tạo nhiều kết quả khi học sinh gửi lại yêu cầu nộp bài.
* Có khả năng đo tải bằng Apache JMeter.
* Có nhật ký kiểm toán cho các thao tác quan trọng.
* Có thể phát triển dần thành hệ thống quy mô lớn mà không phải viết lại toàn bộ.

---

# 3. Phạm vi người dùng

Hệ thống có năm loại vai trò chính.

## 3.1. System Administrator

Quản trị kỹ thuật và tài khoản hệ thống.

Quyền chính:

* Tạo, khóa, mở khóa tài khoản.
* Gán hoặc thu hồi vai trò.
* Cấu hình OAuth2/OIDC.
* Cấu hình chính sách mật khẩu.
* Cấu hình giới hạn upload, email và hệ thống.
* Xem nhật ký bảo mật.
* Xem trạng thái hoạt động của các dịch vụ.
* Thu hồi phiên đăng nhập.
* Quản lý backup và cấu hình hệ thống.

Giới hạn:

* Không mặc nhiên được chỉnh sửa nội dung câu hỏi.
* Không mặc nhiên được thay đổi điểm thi.
* Không được xem CCCD hoặc số điện thoại dạng rõ nếu không có quyền đặc biệt.
* Mọi thao tác nâng quyền, mở khóa và thay đổi cấu hình đều phải được audit.

## 3.2. Academic Administrator

Quản lý nghiệp vụ đào tạo.

Quyền chính:

* Quản lý năm học, học kỳ, môn học và lớp.
* Tạo học phần hoặc lớp môn học.
* Phân công giáo viên.
* Thêm học sinh vào lớp.
* Cấu hình lịch thi cấp đơn vị.
* Xem báo cáo tổng hợp.
* Import danh sách học sinh, giáo viên và lớp.
* Gán giám thị cho ca thi.

Giới hạn:

* Không sửa ngân hàng câu hỏi của giáo viên nếu không được chia sẻ quyền.
* Không xem đáp án đúng của đề chưa được cấp quyền.
* Không sửa điểm trực tiếp.
* Không dùng quyền quản lý lớp để truy cập bài làm ngoài phạm vi được phân công.

## 3.3. Teacher

Giáo viên bộ môn, người tạo câu hỏi và đề thi.

Quyền chính:

* Quản lý ngân hàng câu hỏi do mình sở hữu.
* Import câu hỏi từ Excel.
* Tạo, sửa, sao chép và lưu phiên bản câu hỏi.
* Chia sẻ ngân hàng câu hỏi cho đồng giáo viên.
* Quản lý đề cương, bài giảng và tài liệu của học phần được phân công.
* Tạo đề thi.
* Cấu hình ca thi.
* Chọn lớp hoặc danh sách học sinh tham gia.
* Công bố đề.
* Theo dõi học sinh trong ca thi.
* Xem kết quả của các ca thi mình phụ trách.
* Xử lý phúc khảo và chấm thủ công nếu có câu tự luận.
* Xuất bảng điểm Excel.
* Công bố hoặc thu hồi kết quả.

Giới hạn:

* Chỉ quản lý học phần được phân công.
* Chỉ truy cập ngân hàng câu hỏi do mình sở hữu hoặc được chia sẻ.
* Không quản lý tài khoản và vai trò người dùng.
* Không sửa một đề đã được công bố; phải tạo phiên bản mới.
* Không thay đổi điểm mà không nhập lý do.
* Không xem dữ liệu nhạy cảm không cần thiết của học sinh.
* Không xem bài thi của học phần khác.

## 3.4. Proctor

Giám thị được phân công theo từng ca thi.

Quyền chính:

* Xem danh sách học sinh của ca thi được giao.
* Theo dõi trạng thái online, offline, đang làm và đã nộp.
* Ghi nhận sự cố.
* Gửi thông báo cho học sinh.
* Cho phép học sinh vào lại ca thi khi có lý do hợp lệ.
* Yêu cầu kết thúc lượt thi trong trường hợp vi phạm.
* Xác nhận sự cố mất điện hoặc mất mạng.

Giới hạn:

* Không tạo hoặc sửa câu hỏi.
* Không xem đáp án đúng.
* Không sửa điểm.
* Không xem các ca thi không được phân công.
* Mọi hành động buộc nộp, mở lại hoặc vô hiệu hóa lượt thi phải có lý do và audit.

## 3.5. Student

Học sinh tham gia học và thi.

Quyền chính:

* Xem môn học và lớp mình tham gia.
* Xem tài liệu, đề cương đã công bố.
* Xem lịch thi được phân công.
* Bắt đầu, tiếp tục và nộp bài của chính mình.
* Xem trạng thái đồng bộ đáp án.
* Xem kết quả khi giáo viên công bố.
* Gửi yêu cầu phúc khảo.
* Quản lý thông tin cá nhân giới hạn.
* Đổi mật khẩu, liên kết hoặc hủy liên kết tài khoản OAuth khi được cho phép.

Giới hạn:

* Không truy cập bài làm của người khác.
* Không truy cập đề trước thời gian mở.
* Không xem đáp án đúng khi chưa được công bố.
* Không tự thêm mình vào lớp hoặc ca thi.
* Không chỉnh sửa câu trả lời sau khi bài đã nộp.
* Không thay đổi thời gian hệ thống hoặc dữ liệu chấm điểm.
* Không truy cập tài liệu của lớp không tham gia.

---

# 4. Mô hình phân quyền

Hệ thống không chỉ dùng RBAC đơn giản mà kết hợp ba lớp kiểm tra.

## 4.1. Role-Based Access Control

Mỗi vai trò có tập quyền cơ bản.

Ví dụ:

```text
QUESTION_CREATE
QUESTION_UPDATE
QUESTION_SHARE
EXAM_CREATE
EXAM_PUBLISH
SESSION_MONITOR
ATTEMPT_SUBMIT
RESULT_VIEW_OWN
RESULT_EXPORT
USER_ROLE_ASSIGN
AUDIT_VIEW
```

## 4.2. Relationship-Based Access Control

Ngoài vai trò, người dùng phải có quan hệ hợp lệ với tài nguyên.

Ví dụ:

* Giáo viên chỉ sửa câu hỏi nếu là chủ sở hữu hoặc đồng biên tập.
* Giáo viên chỉ xem kết quả nếu phụ trách học phần hoặc ca thi.
* Học sinh chỉ tải tài liệu nếu đang được ghi danh trong lớp.
* Giám thị chỉ giám sát ca thi được phân công.
* Học sinh chỉ truy cập `attempt` có `student_id` bằng chính mình.

## 4.3. Attribute-Based Access Control

Quyền còn phụ thuộc trạng thái và thời điểm.

Ví dụ:

* Đề chỉ được sửa khi ở trạng thái `DRAFT`.
* Học sinh chỉ bắt đầu bài khi thời gian máy chủ nằm trong cửa sổ cho phép.
* Kết quả chỉ hiển thị nếu `result_policy` cho phép.
* Tài liệu chỉ hiển thị khi đã `PUBLISHED`.
* Giáo viên chỉ xuất bảng điểm sau khi ca thi kết thúc.
* Tài khoản bị khóa không thể dùng access token cũ.

## 4.4. Nguyên tắc triển khai

* Mặc định từ chối.
* Kiểm tra quyền tại backend cho mọi request.
* Frontend ẩn nút chỉ để cải thiện giao diện, không được coi là biện pháp bảo mật.
* Sử dụng method security như `@PreAuthorize`.
* Service nghiệp vụ phải kiểm tra ownership và assignment.
* Không dùng ID do client gửi làm bằng chứng quyền sở hữu.
* Viết integration test cho từng cặp vai trò–endpoint.

---

# 5. Kiến trúc tổng thể

## 5.1. Kiến trúc lựa chọn

Sử dụng:

```text
Frontend độc lập
+
Backend Modular Monolith
+
PostgreSQL
+
Redis
+
MinIO
+
WebSocket
+
Email service
```

Không sử dụng microservices trong giai đoạn đầu.

Backend vẫn được chia thành các module nghiệp vụ độc lập để có thể tách thành service sau này.

## 5.2. Sơ đồ logic

```text
Browser
   │
   │ HTTPS
   ▼
Nginx / Reverse Proxy
   ├── /                 → Next.js
   ├── /api/*            → Spring Boot
   ├── /ws/*             → Spring WebSocket
   └── /objects/*        → Signed MinIO URLs only
                             
Spring Boot Modular Monolith
   ├── Identity & Access
   ├── Academic Management
   ├── Learning Content
   ├── Question Bank
   ├── Exam Management
   ├── Attempt & Autosave
   ├── Grading
   ├── Monitoring
   ├── Reporting
   ├── Notification
   └── Audit

Infrastructure
   ├── PostgreSQL: dữ liệu chính thức
   ├── Redis: cache, rate limit, presence
   ├── MinIO: file và media
   ├── SMTP: email
   └── Monitoring stack
```

## 5.3. Công nghệ đề xuất

### Backend

```text
Java 21
Spring Boot 3.5.x
Spring Web
Spring Security
Spring OAuth2 Client
Spring OAuth2 Resource Server
Spring Data JPA
Spring Data Redis
Spring WebSocket
Spring Validation
Spring Actuator
Spring Mail
Flyway
Apache POI
MapStruct
Testcontainers
OpenAPI/Swagger
```

### Frontend

```text
Next.js 16.x
TypeScript
Tailwind CSS
TanStack Query
React Hook Form
Zod
Zustand
Axios hoặc Ky
@stomp/stompjs
Recharts
Playwright
```

### Infrastructure

```text
PostgreSQL 18
Redis
MinIO
Nginx
Docker Compose
Mailpit cho môi trường development
Prometheus
Grafana
ClamAV tùy giai đoạn
Apache JMeter
```

---

# 6. Cấu trúc backend

```text
com.quizplatform
├── identity
├── authorization
├── academic
├── content
├── question
├── exam
├── attempt
├── grading
├── monitoring
├── reporting
├── notification
├── audit
├── storage
└── shared
```

Mỗi module có cấu trúc:

```text
module/
├── api
│   ├── controller
│   ├── request
│   └── response
├── application
│   ├── service
│   ├── command
│   └── query
├── domain
│   ├── model
│   ├── repository
│   ├── event
│   └── policy
└── infrastructure
    ├── persistence
    ├── mapper
    └── integration
```

Không để toàn bộ entity của hệ thống trong một package chung.

Các module không được truy cập trực tiếp repository nội bộ của module khác. Giao tiếp qua application service hoặc domain event.

---

# 7. Các module chức năng

## 7.1. Identity and Access Management

Chức năng:

* Đăng nhập bằng username/email và mật khẩu.
* Đăng nhập OAuth2/OIDC bằng Google hoặc Microsoft.
* Đăng xuất một phiên.
* Đăng xuất tất cả thiết bị.
* Refresh phiên đăng nhập.
* Đổi mật khẩu.
* Khôi phục mật khẩu.
* Xác minh email.
* Quản lý tài khoản OAuth đã liên kết.
* Khóa tài khoản.
* Theo dõi phiên đăng nhập.
* Gán role và permission.
* Hỗ trợ MFA cho quản trị viên và giáo viên.

### Quy tắc OAuth2

* Sử dụng Authorization Code flow.
* Không cho người dùng tự chọn vai trò sau khi đăng nhập OAuth.
* Tài khoản mới có thể ở trạng thái `PENDING_APPROVAL`.
* Có thể tự động kích hoạt học sinh nếu email thuộc domain trường và khớp danh sách được import.
* Chỉ liên kết OAuth với tài khoản hiện tại sau khi người dùng đã xác thực.
* Không tự động hợp nhất hai tài khoản chỉ dựa trên email chưa được xác minh.
* Lưu `provider`, `provider_subject`, `email`, thời gian liên kết.
* Không lưu access token của Google/Microsoft nếu không thực sự cần gọi API của nhà cung cấp.

### Chiến lược token

* Access token: JWT, thời hạn khoảng 5–10 phút.
* Access token chỉ giữ trong bộ nhớ frontend.
* Refresh token: chuỗi ngẫu nhiên không phải JWT.
* Refresh token được lưu dạng hash trong database.
* Refresh token gửi bằng cookie `HttpOnly`, `Secure`, `SameSite`.
* Mỗi thiết bị có một refresh session riêng.
* Refresh token rotation sau mỗi lần sử dụng.
* Phát hiện reuse để thu hồi toàn bộ token family.
* Không lưu access token hoặc refresh token trong `localStorage`.

## 7.2. Khôi phục mật khẩu

Luồng:

```text
Người dùng nhập email
    → Hệ thống luôn trả cùng một thông báo
    → Nếu tài khoản tồn tại, tạo token ngẫu nhiên
    → Lưu hash của token
    → Gửi link qua email
    → Người dùng mở link
    → Token được kiểm tra
    → Đặt mật khẩu mới
    → Token bị vô hiệu hóa
    → Thu hồi các phiên đăng nhập cũ
    → Gửi email thông báo thay đổi
```

Quy tắc:

* Token chỉ dùng một lần.
* Hết hạn sau khoảng 15–30 phút.
* Không lưu token dạng rõ trong database.
* Giới hạn số yêu cầu theo IP và tài khoản.
* Không tiết lộ email có tồn tại hay không.
* Không tự động đăng nhập sau khi reset.
* Không gửi mật khẩu qua email.
* Audit các lần yêu cầu và hoàn tất reset.

## 7.3. Academic Management

Quản lý:

* Năm học.
* Học kỳ.
* Môn học.
* Lớp hành chính.
* Lớp học phần.
* Danh sách học sinh.
* Phân công giáo viên.
* Phân công giám thị.
* Ghi danh học sinh.
* Import danh sách người dùng từ Excel.
* Trạng thái đang học, đã hoàn thành hoặc bị đình chỉ.

Đối tượng trung tâm nên là `CourseOffering`, đại diện cho một môn học được mở cho một lớp trong một học kỳ.

## 7.4. Learning Content Management

Hỗ trợ:

* Đề cương môn học.
* Bài giảng.
* Tài liệu tham khảo.
* Video hoặc liên kết ngoài.
* File PDF, DOCX, PPTX, XLSX và ảnh.
* Phân chia tài liệu theo chương hoặc chủ đề.
* Lưu nhiều phiên bản.
* Soạn thảo nháp.
* Công bố hoặc thu hồi.
* Gắn tài liệu với môn, lớp hoặc bài thi.
* Tìm kiếm theo tên, loại, tag và người tạo.

### Trạng thái tài liệu

```text
DRAFT
PROCESSING
QUARANTINED
PUBLISHED
UNPUBLISHED
ARCHIVED
```

### Phân quyền tài liệu

* Giáo viên được phân công: tạo và quản lý.
* Đồng giáo viên có quyền `EDITOR`: cùng chỉnh sửa.
* Học sinh: chỉ đọc tài liệu đã công bố của lớp mình.
* Giám thị: không mặc nhiên có quyền truy cập.
* Academic Admin: quản lý metadata và phân công, không mặc nhiên sửa nội dung.
* System Admin: quản lý hệ thống lưu trữ, không mặc nhiên xem nội dung riêng tư.

## 7.5. Question Bank

Chức năng:

* Tạo câu hỏi thủ công.
* Import từ Excel.
* Sửa câu hỏi.
* Sao chép câu hỏi.
* Lưu phiên bản.
* Gắn môn, chương, chủ đề và độ khó.
* Gắn hình ảnh hoặc tài liệu.
* Chia sẻ ngân hàng câu hỏi.
* Tìm kiếm và lọc.
* Phát hiện mã câu hỏi trùng.
* Lưu lịch sử thay đổi.

### Loại câu hỏi giai đoạn chính

* Một đáp án đúng.
* Nhiều đáp án đúng.
* Đúng/sai.

### Loại mở rộng

* Điền số.
* Trả lời ngắn.
* Ghép cặp.
* Tự luận có chấm thủ công.

### Trạng thái câu hỏi

```text
DRAFT
ACTIVE
RETIRED
```

Không xóa cứng câu hỏi đã được dùng trong đề. Chỉ chuyển sang `RETIRED`.

## 7.6. Import câu hỏi từ Excel

Quy trình hai bước:

```text
Upload
    → Parse
    → Validate
    → Preview
    → Người dùng xác nhận
    → Import transaction
```

Không import ngay khi vừa upload.

### Cột mẫu

```text
code
type
content
option_a
option_b
option_c
option_d
correct_answer
explanation
difficulty
subject_code
chapter
tags
default_score
```

### Kiểm tra

* Định dạng file.
* Dung lượng file.
* Header bắt buộc.
* Dòng trống.
* Mã trùng.
* Loại câu hỏi không hỗ trợ.
* Thiếu nội dung.
* Thiếu đáp án.
* Đáp án đúng không tồn tại.
* Nhiều đáp án đúng sai định dạng.
* Điểm không hợp lệ.
* Môn học không tồn tại.
* Giáo viên không có quyền với môn học.
* Công thức Excel nguy hiểm hoặc nội dung bất thường.

### Kết quả preview

```json
{
  "importId": "uuid",
  "totalRows": 200,
  "validRows": 194,
  "invalidRows": 6,
  "errors": [
    {
      "row": 18,
      "column": "correct_answer",
      "code": "INVALID_CORRECT_OPTION",
      "message": "Đáp án E không tồn tại"
    }
  ]
}
```

Import phải hỗ trợ:

* Chỉ import dòng hợp lệ.
* Hoặc hủy toàn bộ nếu có lỗi.
* Tải file lỗi về để sửa.
* Xem lịch sử import.
* Không tạo dữ liệu trùng khi người dùng gửi lại request xác nhận.

## 7.7. Exam Management

Giáo viên có thể:

* Tạo đề từ ngân hàng câu hỏi.
* Chọn câu thủ công.
* Lấy ngẫu nhiên theo chủ đề và độ khó.
* Cấu hình điểm.
* Cấu hình thứ tự.
* Cấu hình chính sách kết quả.
* Xem trước đề.
* Sao chép đề.
* Tạo phiên bản mới.
* Công bố đề.
* Thu hồi đề nếu chưa có ca thi bắt đầu.

### Vòng đời đề thi

```text
DRAFT
READY
PUBLISHED
RETIRED
```

Khi chuyển sang `PUBLISHED`, hệ thống tạo snapshot:

* Nội dung câu hỏi.
* Danh sách lựa chọn.
* Đáp án đúng.
* Điểm.
* Giải thích.
* Version câu hỏi.

Việc giáo viên sửa ngân hàng câu hỏi sau đó không được làm thay đổi đề đã công bố.

## 7.8. Exam Session

Ca thi chứa:

* Đề thi.
* Lớp hoặc danh sách học sinh.
* Thời gian mở.
* Thời gian đóng.
* Thời lượng.
* Số lần được phép làm.
* Thời gian vào muộn.
* Chính sách tự động nộp.
* Chính sách đảo câu và đáp án.
* Chính sách xem điểm.
* Giáo viên phụ trách.
* Giám thị.
* Mật khẩu hoặc mã ca thi tùy chọn.
* Giới hạn thiết bị hoặc phiên đăng nhập.
* Quy tắc xử lý mất kết nối.

### Vòng đời ca thi

```text
DRAFT
SCHEDULED
OPEN
CLOSED
RESULTS_RELEASED
ARCHIVED
CANCELLED
```

Sau khi ca thi bắt đầu:

* Không được đổi đề.
* Không được rút ngắn thời lượng của học sinh đang làm.
* Mọi thay đổi đặc biệt phải có audit.
* Thời gian máy chủ là nguồn chính thức.

## 7.9. Student Attempt

Một học sinh có một hoặc nhiều lượt thi tùy cấu hình.

### Trạng thái

```text
CREATED
IN_PROGRESS
SUBMITTED
AUTO_SUBMITTED
GRADED
INVALIDATED
```

### Luồng

```text
Học sinh mở ca thi
    → Backend kiểm tra quyền và thời gian
    → Tạo hoặc tiếp tục attempt
    → Sinh thứ tự câu hỏi riêng
    → Trả đề không chứa đáp án
    → Học sinh làm bài
    → Autosave phần thay đổi
    → Nộp bài
    → Chấm điểm trong transaction
    → Commit
    → Gửi sự kiện real-time cho giáo viên
```

### Quy tắc quan trọng

* Mỗi attempt có seed đảo câu và đáp án riêng.
* Thứ tự sinh ra được lưu để lần tải lại không thay đổi.
* API học sinh không bao giờ trả `correctAnswer`.
* Học sinh không thể cập nhật attempt của người khác.
* Không cho sửa đáp án sau `SUBMITTED`.
* Hết giờ sẽ tự động nộp theo thời gian máy chủ.
* Client countdown chỉ là giao diện; backend vẫn xác nhận deadline.

## 7.10. Autosave và phục hồi mất mạng

Frontend lưu:

* Câu trả lời hiện tại.
* Phiên bản cập nhật.
* Thời điểm đồng bộ gần nhất.
* Danh sách thay đổi chưa gửi.

Cơ chế:

* Autosave sau khi người dùng dừng thao tác.
* Gửi batch các câu thay đổi mỗi 10–15 giây.
* Thêm jitter để tránh toàn bộ học sinh cùng gửi một thời điểm.
* Khi mất mạng, giữ thay đổi cục bộ.
* Khi kết nối lại, đồng bộ theo version.
* Hiển thị rõ `Đã lưu`, `Đang lưu`, `Chưa đồng bộ`.
* Không lưu đáp án đúng hoặc dữ liệu nhạy cảm ở client.
* Dữ liệu local của attempt phải được xóa sau khi nộp thành công.

Backend sử dụng optimistic version hoặc sequence number để tránh ghi đè thay đổi mới bằng request cũ.

## 7.11. Nộp bài an toàn

Endpoint nộp bài phải hỗ trợ idempotency:

```http
POST /api/v1/attempts/{attemptId}/submit
Idempotency-Key: <uuid>
```

Transaction:

1. Kiểm tra người gửi là chủ attempt.
2. Khóa hoặc kiểm tra version của attempt.
3. Kiểm tra attempt đang `IN_PROGRESS`.
4. Kiểm tra deadline.
5. Ghi các câu trả lời cuối.
6. Chấm điểm.
7. Tạo kết quả.
8. Chuyển trạng thái sang `SUBMITTED`.
9. Lưu `submitted_at`.
10. Lưu idempotency result.
11. Commit.
12. Sau commit mới phát WebSocket và notification.

Nếu client gửi lại cùng key, backend trả kết quả cũ.

Không sử dụng Redis Pub/Sub hoặc `@Async` làm nơi lưu bài chính thức.

## 7.12. Grading

Chấm tự động hỗ trợ:

* Một đáp án đúng.
* Nhiều đáp án đúng.
* Đúng/sai.
* Trả lời số với khoảng sai số.
* Trả lời ngắn với tập đáp án cho phép.

Có thể cấu hình:

* Chấm đúng hoàn toàn.
* Chấm điểm một phần cho câu nhiều đáp án.
* Điểm âm hoặc không điểm âm.
* Làm tròn điểm.
* Thang điểm.
* Trọng số câu hỏi.

Mọi lần thay đổi điểm thủ công phải lưu:

* Điểm cũ.
* Điểm mới.
* Người sửa.
* Lý do.
* Thời gian.
* Loại thay đổi.
* Bằng chứng hoặc ghi chú.

## 7.13. Real-time Monitoring

WebSocket dùng cho:

* Heartbeat.
* Trạng thái online/offline.
* Học sinh bắt đầu bài.
* Học sinh nộp bài.
* Thông báo ca thi.
* Cảnh báo còn ít thời gian.
* Giáo viên gửi thông báo.
* Dashboard giám sát.

Không dùng WebSocket để lưu đáp án chính thức.

### Thông tin giáo viên có thể xem

```text
Họ tên
Mã học sinh
Trạng thái
Thời điểm bắt đầu
Số câu đã trả lời
Thời điểm heartbeat gần nhất
Tình trạng kết nối
Thời điểm nộp
Sự cố được ghi nhận
```

Không hiển thị chi tiết đáp án đang chọn trong thời gian thi trừ khi có yêu cầu nghiệp vụ đặc biệt và được phê duyệt.

Presence có thể lưu trong Redis với TTL.

Không broadcast countdown mỗi giây. Backend chỉ gửi `serverTime` và `endTime`; frontend tự đếm.

## 7.14. Statistics and Reports

Dashboard theo ca thi:

* Tổng số học sinh.
* Chưa bắt đầu.
* Đang làm.
* Mất kết nối.
* Đã nộp.
* Tự động nộp.
* Bài bị vô hiệu hóa.
* Điểm trung bình.
* Trung vị.
* Điểm cao nhất và thấp nhất.
* Độ lệch chuẩn.
* Phân bố điểm.
* Tỷ lệ đạt.
* Thời gian làm bài trung bình.
* Tỷ lệ đúng từng câu.
* Câu khó nhất.
* Câu dễ nhất.
* Câu có độ phân hóa thấp.
* Danh sách học sinh cần xem xét.

Thống kê theo:

* Học sinh.
* Lớp.
* Môn học.
* Đề thi.
* Ca thi.
* Học kỳ.
* Giáo viên.

### Xuất Excel

File kết quả gồm các sheet:

```text
1. Bang diem
2. Chi tiet bai lam
3. Thong ke cau hoi
4. Tong quan ca thi
5. Nhat ky su co
```

Yêu cầu:

* Header rõ ràng.
* Freeze pane.
* Auto filter.
* Định dạng điểm và thời gian.
* Có mã đề, ca thi và ngày xuất.
* Không xuất CCCD hoặc số điện thoại nếu không cần.
* Kiểm soát quyền trước khi tạo file.
* Chống formula injection đối với nội dung bắt đầu bằng `=`, `+`, `-`, `@`.
* Lưu audit người xuất và phạm vi dữ liệu.
* File lớn có thể tạo bất đồng bộ và gửi thông báo khi hoàn tất.

## 7.15. Notification

Kênh:

* Thông báo trong ứng dụng.
* WebSocket.
* Email.

Sự kiện:

* Tài khoản được tạo.
* Xác minh email.
* Khôi phục mật khẩu.
* Được thêm vào lớp.
* Có tài liệu mới.
* Ca thi được công bố.
* Ca thi thay đổi lịch.
* Sắp đến giờ thi.
* Kết quả được công bố.
* Có phản hồi phúc khảo.
* Phát hiện đăng nhập bất thường.

---

# 8. Mô hình dữ liệu chính

## 8.1. Identity

```text
users
roles
permissions
user_roles
role_permissions
oauth_accounts
refresh_sessions
password_reset_tokens
email_verification_tokens
mfa_credentials
login_attempts
```

## 8.2. Academic

```text
academic_years
semesters
subjects
classes
course_offerings
course_teachers
enrollments
proctor_assignments
```

## 8.3. Content

```text
syllabi
syllabus_versions
course_sections
learning_resources
resource_versions
stored_objects
resource_access_rules
```

## 8.4. Question Bank

```text
question_banks
question_bank_members
questions
question_versions
question_options
question_tags
tags
question_import_jobs
question_import_rows
```

## 8.5. Exam

```text
exams
exam_versions
exam_questions
exam_sessions
exam_participants
session_announcements
```

## 8.6. Attempt and Grading

```text
attempts
attempt_question_orders
attempt_answers
attempt_events
grades
grade_items
grade_adjustments
review_requests
idempotency_records
```

## 8.7. Platform

```text
notifications
audit_logs
security_events
outbox_events
system_settings
```

---

# 9. Constraint dữ liệu bắt buộc

Ví dụ:

```text
UNIQUE(oauth_provider, provider_subject)
UNIQUE(exam_session_id, student_id, attempt_number)
UNIQUE(attempt_id, exam_question_id)
UNIQUE(idempotency_key, user_id, operation)
UNIQUE(course_offering_id, student_id)
UNIQUE(question_bank_id, question_code)
```

Các bảng phải có:

```text
id
created_at
created_by
updated_at
updated_by
version
```

Các entity có lịch sử quan trọng không được xóa cứng.

Sử dụng:

* Foreign key.
* Unique constraint.
* Check constraint.
* Optimistic locking.
* Transaction.
* Index theo query thực tế.

---

# 10. Bảo mật dữ liệu

## 10.1. Mật khẩu

* Dùng Argon2id.
* Mỗi mật khẩu có salt riêng.
* Có thể thêm pepper lấy từ secret.
* Không dùng SHA-256 đơn thuần.
* Không dùng AES cho mật khẩu.
* Không log mật khẩu.
* Không gửi mật khẩu qua email.
* Kiểm tra mật khẩu phổ biến hoặc bị lộ nếu có điều kiện tích hợp.

## 10.2. CCCD và số điện thoại

Dùng AES-256-GCM.

Mỗi giá trị lưu:

```text
ciphertext
iv
authentication_tag
key_version
lookup_hmac
```

Quy tắc:

* IV ngẫu nhiên cho từng lần mã hóa.
* Key không nằm trong database.
* Key không commit vào Git.
* Key được inject bằng secret.
* Chỉ service được cấp quyền mới giải mã.
* UI mặc định chỉ hiển thị dạng che.
* Audit mỗi lần xem dữ liệu dạng rõ.
* Dùng HMAC riêng cho nhu cầu tìm kiếm chính xác.
* Không hỗ trợ tìm kiếm `LIKE` trên ciphertext.

## 10.3. File upload

* Bucket MinIO là private.
* Không cung cấp URL public vĩnh viễn.
* Download qua URL ký thời hạn ngắn.
* Kiểm tra quyền trước khi tạo signed URL.
* Giới hạn dung lượng.
* Kiểm tra extension, MIME type và magic bytes.
* Đổi tên object bằng UUID.
* Không dùng trực tiếp tên file do người dùng gửi làm đường dẫn.
* Loại bỏ path traversal.
* File mới được đưa vào vùng quarantine.
* Có thể quét ClamAV trước khi publish.
* Chặn file thực thi và định dạng nguy hiểm.
* Log upload nhưng không log nội dung file.

## 10.4. API Security

* HTTPS bắt buộc ở production.
* CORS allowlist cụ thể.
* Không dùng `*` với credentials.
* CSRF protection cho endpoint dùng cookie.
* Rate limit cho login, refresh, reset password, upload và submit.
* Input validation ở request boundary.
* Giới hạn kích thước request.
* Không trả stack trace.
* Error response không tiết lộ cấu trúc database.
* Security headers và Content Security Policy.
* Correlation ID cho request.
* Log masking.
* Dependency scanning.
* Container chạy non-root nếu có thể.

## 10.5. Audit

Audit tối thiểu:

* Đăng nhập thành công và thất bại.
* Refresh token reuse.
* Đổi và reset mật khẩu.
* Gán hoặc thu hồi role.
* Tạo, sửa, công bố đề.
* Thay đổi ca thi.
* Mở lại hoặc vô hiệu hóa attempt.
* Thay đổi điểm.
* Xuất bảng điểm.
* Xem dữ liệu nhạy cảm.
* Xóa hoặc archive tài liệu.
* Thay đổi cấu hình bảo mật.

Audit log gồm:

```text
actor_id
action
target_type
target_id
timestamp
ip_address
user_agent
result
reason
correlation_id
metadata đã lọc
```

Audit log không chứa:

* Mật khẩu.
* Refresh token.
* Access token.
* Đáp án đúng dạng rõ nếu không cần.
* Toàn bộ CCCD hoặc số điện thoại.

---

# 11. Redis Usage

Redis chỉ dùng cho dữ liệu có thể tái tạo hoặc dữ liệu ngắn hạn.

## Nên dùng

* Cache đề thi đã công bố.
* Cache cấu hình ca thi.
* Rate limiting.
* Presence và heartbeat.
* Short-lived verification state.
* Distributed lock cho một số tác vụ phụ.
* Cache thống kê.
* Pub/Sub cho cập nhật giao diện không quan trọng.

## Không dùng làm nguồn dữ liệu chính cho

* Bài làm.
* Điểm.
* Đáp án.
* Danh sách học sinh.
* Quyền người dùng.
* Trạng thái nộp chính thức.
* Audit log bắt buộc.

Nếu cần xử lý sự kiện bền vững, dùng database outbox hoặc Redis Streams/RabbitMQ ở giai đoạn mở rộng.

---

# 12. Hiệu năng và khả năng mở rộng

## 12.1. Tối ưu application

* HikariCP.
* Query projection thay vì luôn tải toàn entity.
* Pagination.
* Batch insert khi import.
* Tránh N+1 query.
* Cache dữ liệu chỉ đọc.
* Không broadcast WebSocket thừa.
* Autosave batch.
* Idempotent submit.
* Nén response hợp lý.
* Dùng CDN hoặc cache cho static asset.
* Upload file trực tiếp đến object storage bằng signed request khi phù hợp.

## 12.2. Index cơ bản

```text
users(email)
users(username)
questions(question_bank_id, status)
exam_sessions(start_time, end_time, status)
exam_participants(exam_session_id, student_id)
attempts(exam_session_id, student_id)
attempts(status, submitted_at)
attempt_answers(attempt_id, exam_question_id)
audit_logs(actor_id, created_at)
notifications(user_id, read_at)
```

Index phải được xác nhận bằng query plan, không tạo tràn lan.

## 12.3. Scale-out sau này

Backend nên stateless ngoài:

* PostgreSQL.
* Redis.
* MinIO.

Khi chạy nhiều backend replica:

* Token phải xác thực độc lập.
* Rate limit dùng Redis.
* Presence dùng Redis.
* WebSocket cần broker relay hoặc backplane.
* Scheduled task cần leader lock.
* File không lưu trong filesystem của container.

---

# 13. Docker và môi trường triển khai

## 13.1. Development Compose

```text
nginx
frontend
backend
postgres
redis
minio
mailpit
```

## 13.2. Optional profile

```text
prometheus
grafana
clamav
```

## 13.3. Yêu cầu

* Health check cho PostgreSQL, Redis, MinIO và backend.
* Backend chỉ khởi động sau dependency healthy.
* Volume cho PostgreSQL và MinIO.
* Không hard-code secret.
* Có `.env.example`, không commit `.env`.
* Secret production được mount qua file hoặc secret manager.
* Flyway chạy khi backend khởi động hoặc bằng migration job riêng.
* `ddl-auto=validate`, không dùng `update` ở production.
* Có script backup và restore.
* Có seed development riêng.

---

# 14. API Convention

Base path:

```text
/api/v1
```

Nhóm endpoint:

```text
/auth
/users
/roles
/academic-years
/semesters
/subjects
/classes
/courses
/resources
/question-banks
/questions
/question-imports
/exams
/exam-sessions
/attempts
/results
/reports
/notifications
/audit-logs
/files
```

Quy tắc:

* JSON dùng `camelCase`.
* Timestamp trả về ISO-8601 UTC.
* Phân trang thống nhất.
* Có filter và sort allowlist.
* Dùng request/response DTO.
* Không trả trực tiếp JPA entity.
* Có error code ổn định.
* Có OpenAPI.
* Có `Idempotency-Key` cho thao tác nhạy cảm.
* Có correlation ID.

Error mẫu:

```json
{
  "timestamp": "2026-06-27T12:00:00Z",
  "status": 403,
  "code": "EXAM_ACCESS_DENIED",
  "message": "Bạn không có quyền truy cập kỳ thi này",
  "path": "/api/v1/exams/...",
  "correlationId": "..."
}
```

---

# 15. Yêu cầu phi chức năng

## 15.1. Hiệu năng mục tiêu

Trên môi trường tham chiếu 4 vCPU, 8 GB RAM:

* 300 học sinh hoạt động đồng thời.
* 300 học sinh tải đề trong thời gian ngắn.
* 300 học sinh autosave.
* 300 yêu cầu submit gần đồng thời.
* Không mất bài.
* Không tạo kết quả trùng.
* Error rate dưới 1% trong test hợp lệ.
* Submit P95 mục tiêu dưới 3 giây.
* API đọc thông thường P95 mục tiêu dưới 1 giây.
* Cập nhật monitoring P95 mục tiêu dưới 2 giây.

Đây là mục tiêu cần đo bằng JMeter, không được tuyên bố nếu chưa test.

## 15.2. Tính tin cậy

* Submit phải atomic.
* Retry không tạo dữ liệu trùng.
* Kết quả chính thức luôn nằm trong PostgreSQL.
* Sau khi commit mới gửi thông báo thành công.
* Có backup PostgreSQL và object storage.
* Có tài liệu khôi phục.

## 15.3. Khả năng sử dụng

* Responsive cho desktop và mobile.
* Giao diện thi không bị mất dữ liệu khi reload.
* Hiển thị rõ trạng thái lưu.
* Có cảnh báo trước khi nộp.
* Có xác nhận khi rời trang.
* Điều hướng bằng bàn phím ở mức cơ bản.
* Màu sắc có độ tương phản phù hợp.

---

# 16. Kiểm thử

## 16.1. Unit test

Tập trung vào:

* Score calculator.
* Exam state transition.
* Permission policy.
* Token rotation.
* Password reset.
* Excel validation.
* Encryption converter.
* Idempotency.

## 16.2. Integration test

Dùng PostgreSQL, Redis và MinIO thật qua Testcontainers.

Kiểm thử:

* Repository.
* Transaction submit.
* Unique constraint.
* Flyway migration.
* OAuth account linking.
* Authorization theo ownership.
* File access.
* WebSocket event sau commit.

## 16.3. Security test

* Học sinh truy cập attempt người khác.
* Giáo viên truy cập đề của giáo viên khác.
* Giám thị truy cập ca thi không được giao.
* ID enumeration.
* Token hết hạn.
* Refresh token reuse.
* CSRF.
* CORS.
* Upload file giả MIME.
* Formula injection trong Excel.
* SQL injection.
* XSS trong nội dung câu hỏi.
* Mass assignment.
* Lộ đáp án trong API.
* Lộ dữ liệu trong log.

## 16.4. E2E

Dùng Playwright:

```text
Teacher login
→ Import questions
→ Create exam
→ Schedule session
→ Assign students
→ Student login
→ Start exam
→ Autosave
→ Submit
→ Teacher views statistics
→ Export Excel
```

## 16.5. JMeter

Các test plan:

```text
01-login-spike.jmx
02-load-exam.jmx
03-autosave-load.jmx
04-concurrent-submit.jmx
05-submit-retry.jmx
06-teacher-monitoring.jmx
```

Concurrent submit:

* Dùng CSV cho tài khoản.
* Login và lấy token.
* Tạo hoặc dùng sẵn attempt.
* Gửi answer batch.
* Dùng Synchronizing Timer.
* Gửi submit gần cùng lúc.
* Assert status.
* Đối chiếu số record trong database.
* Kiểm tra không có duplicate.
* Xuất HTML report.

---

# 17. Đầu ra bắt buộc của dự án

Dự án chỉ được coi là hoàn thành khi có đủ:

## 17.1. Source code

* Frontend.
* Backend.
* Migration.
* Test.
* JMeter.
* Docker.
* Infrastructure config.

## 17.2. Docker

Một lệnh có thể chạy hệ thống:

```bash
docker compose up --build
```

## 17.3. Tài liệu

```text
README.md
docs/requirements.md
docs/architecture.md
docs/database.md
docs/security.md
docs/authorization-matrix.md
docs/api.md
docs/excel-import-format.md
docs/deployment.md
docs/backup-restore.md
docs/performance-test.md
docs/demo-script.md
```

## 17.4. File hỗ trợ

* Mẫu Excel import câu hỏi.
* Mẫu Excel import người dùng.
* Seed dữ liệu demo.
* Postman collection hoặc OpenAPI.
* JMeter test plans.
* Báo cáo JMeter.
* Sơ đồ kiến trúc.
* ERD.
* Danh sách tài khoản demo.
* Script backup và restore.

---

# 18. Tiêu chí nghiệm thu nghiệp vụ

## AC-01: Import câu hỏi

* Giáo viên tải file `.xlsx`.
* Hệ thống báo lỗi đúng dòng và cột.
* Giáo viên xác nhận import.
* Câu hỏi hợp lệ xuất hiện trong ngân hàng.
* Giáo viên khác không truy cập được nếu chưa chia sẻ.

## AC-02: Cấu hình ca thi

* Giáo viên tạo đề.
* Công bố snapshot.
* Tạo ca thi.
* Gán lớp hoặc học sinh.
* Học sinh ngoài danh sách không vào được.

## AC-03: Làm bài real-time

* Học sinh vào đúng thời gian.
* Làm bài và autosave.
* Reload không mất câu trả lời đã đồng bộ.
* Mất mạng ngắn hạn vẫn giữ thay đổi cục bộ.
* Giáo viên thấy trạng thái online/offline.

## AC-04: Nộp và chấm điểm

* Học sinh nộp bài.
* Request retry không tạo bài trùng.
* Backend tự chấm điểm.
* Hết giờ tự động nộp.
* Giáo viên nhận cập nhật sau commit.

## AC-05: Thống kê và Excel

* Giáo viên xem dashboard.
* Thống kê đúng với dữ liệu bài làm.
* Xuất được file Excel nhiều sheet.
* Người không có quyền không tải được file.

## AC-06: OAuth2

* Đăng nhập Google/Microsoft thành công.
* Không tự nâng thành Teacher/Admin.
* Account linking an toàn.
* Có thể thu hồi phiên.

## AC-07: Khôi phục mật khẩu

* Không tiết lộ tài khoản tồn tại.
* Token hết hạn và chỉ dùng một lần.
* Sau reset, phiên cũ bị thu hồi.
* Có email thông báo.

## AC-08: Tài liệu và đề cương

* Giáo viên đăng tài liệu cho lớp được phân công.
* Học sinh lớp đó tải được.
* Học sinh lớp khác bị từ chối.
* File private, URL ký có thời hạn.

## AC-09: Bảo mật dữ liệu

* Mật khẩu không lưu dạng rõ.
* CCCD và số điện thoại được mã hóa.
* Key không nằm trong database hoặc repository.
* Log không chứa secret.

## AC-10: Tải đồng thời

* Chạy được kịch bản submit đồng thời.
* Không mất submission.
* Không có duplicate.
* Có báo cáo P50, P95, P99, throughput và error rate.

---

# 19. Lộ trình ưu tiên

## Phase 0 – Foundation

* Repository.
* Docker Compose.
* Migration.
* CI.
* Coding conventions.
* Error handling.
* Logging.
* OpenAPI.

## Phase 1 – Core Exam Flow

* Local authentication.
* Role cơ bản.
* Question bank.
* Excel import.
* Exam.
* Exam session.
* Attempt.
* Autosave.
* Submit.
* Auto grading.
* Statistics.
* Excel export.

Đây là phần cần hoàn thành đầu tiên để có luồng end-to-end.

## Phase 2 – Extended Platform

* OAuth2/OIDC.
* Password reset.
* Email verification.
* Academic structure.
* Learning resources.
* Syllabus.
* MinIO.
* Notifications.
* Proctor workflow.

## Phase 3 – Security Hardening

* Argon2id tuning.
* AES-256-GCM.
* Refresh rotation.
* MFA.
* Audit.
* File quarantine.
* ClamAV.
* CSP.
* Security tests.

## Phase 4 – Performance and Operations

* Redis caching.
* Rate limiting.
* JMeter.
* Query tuning.
* Metrics.
* Prometheus.
* Grafana.
* Backup/restore test.
* Multiple backend replicas nếu cần.

---

# 20. Nguyên tắc bắt buộc khi dùng Claude hoặc Codex

Mỗi task giao cho AI phải:

* Chỉ sửa module được chỉ định.
* Liệt kê file sẽ tạo hoặc sửa.
* Không tự thêm dependency.
* Không sửa migration cũ đã áp dụng.
* Tạo migration mới.
* Viết unit test và integration test.
* Giải thích transaction boundary.
* Giải thích authorization rule.
* Không trả đáp án đúng trong student DTO.
* Không lưu token trong localStorage.
* Không ghi secret vào source code.
* Không trả thành công trước khi dữ liệu quan trọng commit.
* Không bỏ qua lỗi bằng `try/catch` rỗng.
* Không dùng `ddl-auto=update`.
* Không vô hiệu hóa CSRF/CORS chỉ để sửa lỗi.
* Không dùng role từ request body làm cơ sở cấp quyền.
* Chạy formatter, lint và test trước khi kết thúc task.

Prompt mẫu:

```text
Implement the Question Import Preview use case.

Architecture:
- Java 21 and Spring Boot modular monolith.
- Module: com.quizplatform.question.
- PostgreSQL with Flyway.
- Apache POI for .xlsx.
- Authorization: TEACHER with access to the selected question bank.

Requirements:
1. Accept .xlsx only, maximum 10 MB.
2. Validate headers and every row.
3. Preview without saving questions.
4. Store an import job and validation results.
5. Do not expose internal exceptions.
6. Add unit tests and Testcontainers integration tests.
7. Do not modify unrelated modules.
8. Do not use ddl-auto=update.

Before coding:
- List files to be changed.
- Describe authorization checks.
- Describe transaction boundaries.
- List edge cases.
```

---

# 21. Quyết định kiến trúc cuối cùng

Dự án sử dụng:

```text
Next.js frontend
+
Spring Boot modular monolith
+
PostgreSQL source of truth
+
Redis cho cache và trạng thái ngắn hạn
+
MinIO cho tài liệu
+
REST cho nghiệp vụ quan trọng
+
WebSocket cho cập nhật real-time
+
OAuth2/OIDC và local authentication
+
JWT access token ngắn hạn
+
Opaque rotating refresh token
+
RBAC + ownership + assignment + state policies
+
Docker Compose
+
JMeter
```

Giá trị nổi bật của sản phẩm:

> Một nền tảng thi và học tập có phân quyền theo vai trò lẫn phạm vi phụ trách, hỗ trợ OAuth2, tài liệu và đề cương, autosave khi mất mạng, snapshot đề thi, nộp bài idempotent, chấm điểm tự động, giám sát real-time, bảo vệ dữ liệu nhạy cảm và có kết quả kiểm thử tải bằng JMeter.

# 22. Definition of Done

Một tính năng chỉ được coi là hoàn thành khi:

* Đúng nghiệp vụ.
* Kiểm tra quyền ở backend.
* Có validation.
* Có migration nếu thay đổi dữ liệu.
* Có test.
* Không làm lộ dữ liệu nhạy cảm.
* Có audit nếu là thao tác quan trọng.
* Có tài liệu API.
* Chạy được trong Docker.
* Đã được kiểm tra với cả trường hợp thành công và thất bại.
