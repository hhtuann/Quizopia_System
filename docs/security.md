# Quizopia Security Specification

> Trạng thái: **Draft for review before V3**
>
> Phạm vi hiện tại: **Identity, Authentication, Authorization foundation**
>
> Tài liệu nguồn liên quan:
>
> - `docs/database.md` là nguồn sự thật cho database schema và invariant nghiệp vụ.
> - `docs/architecture.md` mô tả kiến trúc Modular Monolith.
> - Tài liệu này là nguồn sự thật cho các quyết định bảo mật đã được chốt.
>
> Cập nhật: 2026-06-29

---

# 1. Mục tiêu

Quizopia phải đảm bảo:

- Xác thực đúng danh tính người dùng.
- Không lưu password hoặc refresh token ở dạng plaintext.
- Phân quyền theo permission rõ ràng, không chỉ dựa vào tên role.
- Kiểm tra thêm ownership, assignment, school scope, participation, trạng thái và thời gian.
- Mặc định từ chối truy cập nếu không có rule cho phép rõ ràng.
- Hỗ trợ access token ngắn hạn và refresh token rotation.
- Phát hiện refresh token reuse và thu hồi toàn bộ token family.
- Không để frontend trở thành security boundary.
- Không làm lộ đáp án, điểm, dữ liệu thi hoặc dữ liệu nhạy cảm cho sai đối tượng.
- Có khả năng test và audit các quyết định bảo mật quan trọng.

---

# 2. Nguyên tắc nền tảng

## 2.1. Deny by default

Mọi endpoint không được khai báo public rõ ràng đều phải yêu cầu authentication.

Mọi hành động nghiệp vụ không có permission hoặc rule cho phép rõ ràng đều bị từ chối.

```text
Không có rule cho phép
→ từ chối
```

Không dùng cách tiếp cận:

```text
Không có rule cấm
→ cho phép
```

## 2.2. Authentication khác Authorization

Authentication trả lời:

```text
Người dùng là ai?
```

Authorization trả lời:

```text
Người dùng đó có được thực hiện hành động này
trên tài nguyên này
trong trạng thái và thời điểm hiện tại hay không?
```

Một access token hợp lệ không có nghĩa là mọi hành động đều được phép.

## 2.3. Frontend không phải security boundary

Frontend có thể:

- Ẩn menu.
- Chặn điều hướng.
- Hiển thị giao diện theo role.
- Cảnh báo thao tác không hợp lệ.

Nhưng backend vẫn phải kiểm tra đầy đủ vì client có thể bị sửa hoặc request có thể được gửi trực tiếp.

## 2.4. Least privilege

Mỗi role chỉ được cấp permission tối thiểu để hoàn thành trách nhiệm.

Không cấp permission rộng chỉ để triển khai nhanh.

## 2.5. Không có role hierarchy ngầm

Quizopia không mặc định dùng hierarchy:

```text
SYSTEM_ADMIN > ACADEMIC_ADMIN > TEACHER > PROCTOR > STUDENT
```

Các role là các nhóm trách nhiệm khác nhau.

Đặc biệt:

```text
SYSTEM_ADMIN không tự động là academic superuser.
```

Nếu một SYSTEM_ADMIN cần thực hiện nghiệp vụ học thuật, tài khoản đó phải được cấp thêm role hoặc permission phù hợp theo chính sách được phê duyệt.

---

# 3. Role model

Các role nền tảng:

```text
SYSTEM_ADMIN
ACADEMIC_ADMIN
TEACHER
PROCTOR
STUDENT
```

## 3.1. SYSTEM_ADMIN

Trách nhiệm dự kiến:

- Quản trị vận hành hệ thống.
- Quản trị account, role và permission theo phạm vi được phép.
- Theo dõi tình trạng kỹ thuật và cấu hình hệ thống.
- Xử lý sự cố bảo mật ở mức nền tảng.

Không mặc định có quyền:

- Tạo hoặc sửa câu hỏi học thuật.
- Tạo hoặc sửa đề thi.
- Chấm bài.
- Xem đáp án hoặc kết quả học tập không thuộc phạm vi quản trị kỹ thuật.

## 3.2. ACADEMIC_ADMIN

Trách nhiệm dự kiến:

- Quản trị dữ liệu trường học và học thuật trong school scope.
- Quản lý khối lớp, môn học, lớp học và phân công.
- Quản lý hoạt động thi ở cấp học thuật theo permission cụ thể.
- Có thể xem báo cáo học thuật trong phạm vi được phép.

Không mặc định có quyền quản trị hệ thống hoặc cấu hình bảo mật nền tảng.

## 3.3. TEACHER

Trách nhiệm dự kiến:

- Quản lý ngân hàng câu hỏi của mình hoặc tài nguyên được chia sẻ.
- Tạo và quản lý đề thi thuộc môn/phạm vi được phân công.
- Tạo ca thi hoặc tham gia vận hành ca thi khi được phép.
- Xem và chấm bài trong phạm vi được phân công.

Permission của TEACHER luôn phải kết hợp ownership hoặc assignment.

## 3.4. PROCTOR

Trách nhiệm dự kiến:

- Theo dõi ca thi được phân công.
- Xem trạng thái thí sinh trong ca thi được phân công.
- Ghi nhận hoặc xử lý sự cố theo permission được cấp.

PROCTOR không mặc định được:

- Sửa nội dung đề.
- Xem đáp án.
- Chấm bài.
- Quản lý toàn bộ ca thi của hệ thống.

## 3.5. STUDENT

Trách nhiệm dự kiến:

- Xem các ca thi mình được phép tham gia.
- Bắt đầu attempt hợp lệ.
- Autosave câu trả lời.
- Submit bài thi.
- Xem kết quả theo chính sách công bố.

STUDENT chỉ được truy cập tài nguyên của chính mình và các exam session mà mình là participant hợp lệ.

---

# 4. Authorization model

Quizopia dùng kết hợp:

```text
RBAC
+ permission
+ ownership
+ assignment
+ school scope
+ participation/enrollment
+ resource state
+ time window
```

## 4.1. RBAC

Role gom nhóm permission.

Quan hệ:

```text
User
→ UserRole
→ Role
→ RolePermission
→ Permission
```

Không nên kiểm tra role trực tiếp cho mọi nghiệp vụ.

Ưu tiên:

```text
hasPermission("EXAM_CREATE")
```

thay vì:

```text
hasRole("TEACHER")
```

Role vẫn có thể dùng cho một số rule tổng quát, nhưng permission phải là đơn vị kiểm soát hành động chính.

## 4.2. Ownership

Ví dụ:

```text
TEACHER có QUESTION_UPDATE
```

chỉ cho phép sửa câu hỏi nếu:

- Teacher sở hữu question bank, hoặc
- Teacher được chia sẻ quyền hợp lệ, hoặc
- Có assignment đặc biệt được hệ thống ghi nhận.

## 4.3. Assignment

Ví dụ:

```text
PROCTOR có EXAM_SESSION_MONITOR
```

chỉ được monitor session nếu được phân công cho session đó.

## 4.4. School scope

Các tài nguyên học thuật phải được giới hạn theo school scope.

Ví dụ:

- ACADEMIC_ADMIN của School A không được sửa dữ liệu School B.
- Teacher của School A không được gán học sinh School B vào lớp School A.
- Permission toàn cục và permission theo school scope phải được phân biệt rõ trong service rule.

## 4.5. Participation

STUDENT chỉ được bắt đầu attempt khi:

- Có `exam_session_participants` hợp lệ.
- Participant không bị thu hồi hoặc vô hiệu hóa.
- Chưa vượt quá `max_attempts`.
- Session và exam version hợp lệ.

## 4.6. Resource state

Một permission không được bỏ qua state machine.

Ví dụ:

- Exam version đã `PUBLISHED` là bất biến.
- Attempt đã `SUBMITTED` không được autosave tiếp.
- Refresh session đã revoked không được sử dụng lại.
- Question version đã được snapshot vào đề published không được sửa.

## 4.7. Time window

Các hành động liên quan thi phải kiểm tra thời gian server:

- Session đã mở chưa.
- Session đã đóng chưa.
- Attempt còn thời gian không.
- Grace period có được cấu hình không.
- Token đã hết hạn chưa.

Không tin thời gian do client gửi lên.

---

# 5. Authentication model

## 5.1. Login identifier

MVP hỗ trợ đăng nhập bằng:

```text
username + password
```

Email có thể được dùng cho tìm kiếm hoặc nghiệp vụ khác, nhưng không tự động coi là login identifier nếu chưa có quyết định mới.

## 5.2. Password hashing

Thuật toán:

```text
Argon2id
```

Yêu cầu:

- Mỗi password có salt riêng.
- Không log raw password.
- Không log password hash.
- Không trả password hash qua API.
- Không tự viết thuật toán hash.
- Tham số Argon2id phải cấu hình được và benchmark trên môi trường triển khai.

Không hard-code tham số production vào tài liệu trước khi benchmark.

## 5.3. Account status

Các status hiện có:

```text
ACTIVE
LOCKED
DISABLED
PENDING
```

Login chỉ thành công khi policy account cho phép.

Gợi ý rule:

- `ACTIVE`: có thể đăng nhập.
- `LOCKED`: từ chối cho đến khi hết `locked_until` hoặc được mở khóa.
- `DISABLED`: từ chối.
- `PENDING`: từ chối hoặc chỉ cho phép flow kích hoạt sau này.

Policy cuối cùng cho `PENDING` phải được chốt trước khi triển khai endpoint tạo account.

## 5.4. Failed login

Database đã có:

```text
failed_login_attempts
locked_until
```

Logic triển khai phải:

- Không tiết lộ username có tồn tại hay không.
- Trả lỗi chung `AUTH_INVALID_CREDENTIALS`.
- Tăng failed attempts theo policy.
- Có lockout threshold và lockout duration cấu hình được.
- Reset failed attempts khi login thành công.
- Kết hợp rate limit theo IP và account identifier.

Các giá trị threshold cụ thể chưa được chốt.

---

# 6. Token model

## 6.1. Quyết định đã chốt

### Access token

- Là JWT.
- Trả trong JSON response.
- Frontend chỉ giữ trong memory.
- Không lưu vào `localStorage`.
- Không lưu vào `sessionStorage`.
- Không lưu trong database.
- Gửi qua header:

```http
Authorization: Bearer <access_token>
```

### Refresh token

- Là opaque random token.
- Gửi bằng HttpOnly cookie.
- JavaScript không được đọc token.
- Database chỉ lưu token hash.
- Không log refresh token plaintext.
- Phải rotate mỗi lần refresh.

## 6.2. Access token claims

Access token nên có tối thiểu:

```text
sub
iat
exp
jti
token_version
```

Có thể thêm:

```text
username
roles
```

Không nên nhét toàn bộ permission vào JWT ngay từ đầu nếu permission có thể thay đổi trong khi token còn hiệu lực.

Quyết định cuối cùng về permission claims cần được benchmark giữa:

- Token nhỏ, query permission server-side.
- Token chứa permission snapshot ngắn hạn.

## 6.3. Access token lifetime

Access token phải có thời hạn ngắn.

Giá trị cụ thể chưa được chốt.

Tài liệu cũ dùng 15 phút chỉ là ví dụ, không phải quyết định chính thức.

## 6.4. Token version

`users.token_version` dùng để vô hiệu hóa access token cũ.

Access token chứa `token_version`.

Khi xác thực:

```text
token.token_version == user.token_version
```

Nếu không bằng nhau thì từ chối.

Các hành động có thể tăng token version:

- Logout all sessions.
- Phát hiện compromise nghiêm trọng.
- Reset password theo policy.
- Admin security action.

## 6.5. Refresh token generation

Refresh token phải:

- Được sinh từ CSPRNG.
- Có entropy đủ mạnh.
- Không chứa user ID hoặc dữ liệu suy đoán được.
- Được encode theo định dạng an toàn cho cookie.
- Chỉ tồn tại plaintext ở client và trong request hiện tại.

## 6.6. Refresh token hash

Database lưu:

```text
token_hash
```

Quy trình:

1. Client gửi refresh token qua cookie.
2. Backend hash token nhận được.
3. Tìm session theo hash.
4. Không persist raw token.

Schema hiện dùng `VARCHAR(64)` lowercase hex, phù hợp với SHA-256 hex nếu implementation giữ đúng convention.

Không dùng password hashing chậm cho refresh token ngẫu nhiên entropy cao nếu không có lý do cụ thể; hash mật mã cố định như SHA-256 là phù hợp để lookup.

---

# 7. Refresh session model

Bảng:

```text
refresh_sessions
```

Các trường quan trọng:

```text
id
user_id
family_id
token_hash
parent_session_id
replaced_by_session_id
user_agent
created_ip
last_used_ip
created_at
expires_at
last_used_at
revoked_at
revoke_reason
```

## 7.1. Token family

Mỗi chuỗi rotation có một `family_id`.

Ví dụ:

```text
Token A
→ Token B
→ Token C
```

Cả A, B, C cùng `family_id`.

## 7.2. Rotation flow

Khi refresh thành công:

1. Hash token nhận được.
2. Tìm refresh session.
3. Kiểm tra session tồn tại.
4. Kiểm tra chưa hết hạn.
5. Kiểm tra chưa revoked.
6. Kiểm tra user còn hợp lệ.
7. Tạo refresh token mới.
8. Tạo refresh session mới cùng family.
9. Session mới trỏ `parent_session_id` tới session cũ.
10. Session cũ đặt `replaced_by_session_id` tới session mới.
11. Revoke session cũ với reason phù hợp.
12. Trả access token mới.
13. Set refresh cookie mới.

Toàn bộ bước cập nhật rotation phải nằm trong cùng transaction.

## 7.3. Reuse detection

Nếu một token đã rotate bị dùng lại:

```text
session đã revoked
và có replaced_by_session_id
```

thì coi là nghi ngờ token bị đánh cắp.

Hành động:

1. Revoke toàn bộ session trong `family_id`.
2. Ghi reason rõ ràng, ví dụ `TOKEN_REUSE_DETECTED`.
3. Từ chối refresh.
4. Có thể tăng `token_version` theo policy.
5. Ghi security event nhưng không log token plaintext.

## 7.4. Logout current session

Logout hiện tại:

- Đọc refresh token từ cookie.
- Hash và tìm session.
- Revoke session đó.
- Xóa refresh cookie.
- Không cần lưu access token blacklist trong MVP.
- Access token hiện tại có thể còn hiệu lực đến khi hết hạn.

Vì vậy access token lifetime phải ngắn.

## 7.5. Logout all sessions

Logout all:

1. Revoke toàn bộ refresh session của user.
2. Tăng `users.token_version`.
3. Xóa refresh cookie hiện tại.
4. Access token cũ bị từ chối do token version mismatch.

---

# 8. Cookie policy

Refresh cookie phải dùng:

```text
HttpOnly
Secure
SameSite
Path
Max-Age hoặc Expires
```

## 8.1. HttpOnly

Bắt buộc để JavaScript không thể đọc refresh token.

## 8.2. Secure

- Bắt buộc trong production HTTPS.
- Development local HTTP cần cấu hình riêng.
- Không được vô tình deploy production với `Secure=false`.

## 8.3. SameSite

Giá trị cuối cùng phụ thuộc deployment topology:

- Frontend và backend same-site: có thể dùng `Lax` hoặc `Strict` tùy flow.
- Cross-site deployment: có thể cần `None; Secure`.

Không hard-code trước khi xác định domain production.

## 8.4. Path

Refresh cookie nên giới hạn path hẹp, ví dụ:

```text
/api/v1/auth
```

hoặc cụ thể hơn nếu logout và refresh cùng cần cookie.

## 8.5. Cookie clearing

Khi logout phải xóa cookie với đúng:

- name
- path
- domain
- same-site context

Nếu thuộc tính khác lúc set cookie, trình duyệt có thể không xóa đúng cookie.

---

# 9. CSRF policy

Vì refresh token nằm trong cookie và trình duyệt tự gửi cookie, các endpoint dùng refresh cookie phải được xem xét CSRF.

Không được miễn toàn bộ:

```text
/api/v1/auth/**
```

một cách máy móc.

## 9.1. Access-token endpoints

Các endpoint dùng:

```http
Authorization: Bearer ...
```

và không phụ thuộc cookie authentication thường ít chịu rủi ro CSRF truyền thống vì trình duyệt không tự thêm bearer token.

## 9.2. Refresh và logout endpoints

Các endpoint dùng refresh cookie cần một trong các chiến lược:

- SameSite phù hợp và origin validation.
- CSRF token.
- Double-submit cookie.
- Custom request header kết hợp CORS chặt.
- Combination của các cơ chế trên.

Quyết định triển khai cuối cùng chưa được chốt.

Tối thiểu phải có:

- Chỉ chấp nhận method phù hợp, không dùng GET.
- Kiểm tra `Origin` hoặc `Referer` theo allowlist.
- CORS không dùng wildcard khi `allowCredentials=true`.
- SameSite và Secure đúng môi trường.

---

# 10. CORS policy

CORS phải cấu hình bằng allowlist.

Development có thể cho phép:

```text
http://localhost:3000
```

Không dùng:

```text
*
```

khi cho phép credentials.

Cần kiểm soát:

- allowed origins
- allowed methods
- allowed headers
- exposed headers
- allow credentials
- preflight cache

Production origin phải lấy từ cấu hình môi trường.

---

# 11. API security

## 11.1. Public endpoints

Chỉ các endpoint được khai báo rõ ràng mới public.

Dự kiến MVP:

```text
POST /api/v1/auth/login
POST /api/v1/auth/refresh
```

Logout có thể không cần access token nếu dựa vào refresh cookie, nhưng vẫn cần CSRF/origin protection.

Health endpoint public hay restricted phải được quyết định theo môi trường.

## 11.2. Current user

Endpoint:

```text
GET /api/v1/users/me
```

Trả thông tin cần thiết:

- id
- username
- email nếu policy cho phép
- display name
- roles
- permission hoặc capability cần cho UI

Không trả:

- password hash
- token version nếu không cần
- failed login attempts
- refresh session hash
- internal security metadata

## 11.3. DTO boundary

Không trả JPA entity trực tiếp từ controller.

Luôn dùng request/response DTO để:

- Kiểm soát field.
- Tránh lazy-loading ngoài ý muốn.
- Tránh lộ hash hoặc association nhạy cảm.
- Giữ API ổn định khi entity thay đổi.

## 11.4. Error responses

Không tiết lộ chi tiết nội bộ.

Login sai dùng lỗi chung:

```text
AUTH_INVALID_CREDENTIALS
```

Không phân biệt:

```text
username không tồn tại
password sai
```

Các mã lỗi dự kiến:

```text
AUTH_INVALID_CREDENTIALS
AUTH_ACCOUNT_LOCKED
AUTH_ACCOUNT_DISABLED
AUTH_ACCESS_TOKEN_INVALID
AUTH_ACCESS_TOKEN_EXPIRED
AUTH_REFRESH_TOKEN_INVALID
AUTH_REFRESH_TOKEN_EXPIRED
AUTH_REFRESH_TOKEN_REVOKED
AUTH_REFRESH_TOKEN_REUSE_DETECTED
ACCESS_DENIED
RESOURCE_NOT_FOUND
VALIDATION_ERROR
CONFLICT
```

Không trả stack trace hoặc SQL error production.

---

# 12. Permission strategy cho V3

V3 sẽ seed:

- Role catalog.
- Permission catalog.
- Role-permission mapping mặc định.

Permission code phải:

- Ổn định.
- Uppercase.
- Mô tả một hành động.
- Không chứa ownership trong tên nếu ownership được kiểm tra ở service.
- Không quá rộng.
- Không quá nhỏ đến mức mỗi field là một permission.

Convention đề xuất:

```text
RESOURCE_ACTION
```

Ví dụ:

```text
USER_CREATE
USER_READ
USER_UPDATE
USER_DISABLE

ROLE_ASSIGN

SCHOOL_CREATE
SCHOOL_READ
SCHOOL_UPDATE

QUESTION_BANK_CREATE
QUESTION_BANK_READ
QUESTION_BANK_UPDATE
QUESTION_BANK_DELETE

QUESTION_CREATE
QUESTION_READ
QUESTION_UPDATE
QUESTION_ARCHIVE

EXAM_CREATE
EXAM_READ
EXAM_UPDATE
EXAM_PUBLISH

EXAM_SESSION_CREATE
EXAM_SESSION_READ
EXAM_SESSION_UPDATE
EXAM_SESSION_MONITOR

ATTEMPT_START
ATTEMPT_READ_OWN
ATTEMPT_ANSWER_OWN
ATTEMPT_SUBMIT_OWN

GRADE_READ
GRADE_UPDATE

REPORT_READ
```

Danh sách trên chỉ là convention minh họa, chưa phải catalog V3 cuối cùng.

Catalog cuối cùng phải được chốt từ phạm vi 32 bảng và use case MVP.

---

# 13. Method and service authorization

Có thể dùng method security:

```java
@PreAuthorize(...)
```

nhưng không nhét toàn bộ business rule phức tạp vào SpEL.

Cách tiếp cận đề xuất:

1. Method-level check permission tổng quát.
2. Service/domain policy kiểm tra resource scope.
3. Repository query giới hạn dữ liệu theo actor khi phù hợp.

Ví dụ:

```java
@PreAuthorize("hasAuthority('EXAM_UPDATE')")
public void updateExam(Long examId, UpdateExamCommand command) {
    authorizationPolicy.requireCanUpdateExam(currentUser, examId);
    ...
}
```

Policy tiếp tục kiểm tra:

- owner teacher
- school scope
- exam status
- published state
- assignment

---

# 14. Data protection

## 14.1. Password và token

Không log:

- Password.
- Password hash.
- Access token.
- Refresh token.
- Refresh token hash đầy đủ nếu log có thể bị truy cập rộng.

## 14.2. Sensitive profile data

Tài liệu database dự kiến phone được mã hóa AES-256-GCM khi field này được triển khai.

Yêu cầu:

- Key nằm ngoài database.
- Có key version.
- Không log plaintext.
- Có rotation strategy trước production.

## 14.3. Exam answer protection

Student-facing API không được trả:

- `answer_key`
- `is_correct`
- explanation nếu policy chưa cho phép
- score trước thời điểm công bố
- đáp án của thí sinh khác

Snapshot exam vẫn chứa answer key trong database phục vụ grading, nhưng DTO cho student phải loại bỏ tuyệt đối.

---

# 15. Exam security invariants

Backend phải kiểm tra:

- Student là participant của session.
- Session đang trong time window.
- Exam version đã published.
- Attempt thuộc đúng student.
- Attempt ở đúng trạng thái.
- Không vượt max attempts.
- Autosave chỉ cập nhật khi sequence number mới hơn.
- Submit có idempotency key.
- Submit chính thức xử lý trong PostgreSQL transaction.
- Attempt đã submit không được sửa.
- Random order ổn định trong toàn attempt.
- Student chỉ nhận snapshot question, không đọc trực tiếp question bank.
- Kết quả và đáp án chỉ hiển thị theo show-result/show-answer policy.

Frontend anti-cheating chỉ là tín hiệu hỗ trợ, không phải kiểm soát bảo mật tuyệt đối.

Các hành động như chặn copy hoặc phát hiện đổi tab có thể bị vô hiệu hóa phía client.

---

# 16. Rate limiting

Rate limiting cần áp dụng tối thiểu cho:

- Login.
- Refresh.
- Password-related endpoints sau này.
- Autosave.
- Start attempt.
- Submit.
- Export/report nặng.

Không hard-code limit trong tài liệu trước benchmark.

Nên kết hợp:

- IP-based key.
- Account identifier.
- Authenticated user ID.
- Endpoint category.

Redis có thể dùng làm storage cho distributed rate limit trong deployment nhiều instance.

Rate limit không thay thế account lockout.

---

# 17. Input and output safety

## 17.1. Validation

Backend luôn validate:

- Required fields.
- Length.
- Format.
- Enum values.
- Numeric range.
- Cross-field invariants.
- Ownership references.
- Foreign-key scope.

Frontend validation chỉ để cải thiện UX.

## 17.2. SQL injection

Dùng:

- Spring Data JPA parameter binding.
- Named parameters.
- Criteria API khi cần query động.

Không nối chuỗi input trực tiếp vào SQL/JPQL.

## 17.3. XSS

Không tự escape HTML bằng chuỗi replace thủ công như một giải pháp tổng quát.

Cần quyết định rõ:

- Nội dung nào chỉ là plain text.
- Nội dung nào cho phép rich text.
- Nếu rich text, sanitize bằng thư viện có allowlist.
- Render bằng cơ chế an toàn.
- Áp dụng Content Security Policy ở deployment phù hợp.

---

# 18. Logging and security events

Log phải hỗ trợ điều tra nhưng không làm lộ secret.

Các event nên ghi:

- Login success/failure.
- Account lock.
- Refresh success.
- Refresh reuse detection.
- Logout current/all.
- Role assignment/removal.
- Permission mapping change.
- Exam publish.
- Attempt start.
- Attempt submit.
- Administrative access denial.

Log nên có:

- timestamp
- actor ID nếu có
- event code
- result
- resource type/ID
- request/trace ID
- IP đã chuẩn hóa theo proxy policy

Không log raw password/token.

Audit table chưa nằm trong MVP database hiện tại; trước khi có audit module, dùng structured application logs và retention phù hợp.

---

# 19. Reverse proxy and client IP

Không tin trực tiếp mọi giá trị:

```text
X-Forwarded-For
Forwarded
```

Chỉ đọc proxy headers khi request đi qua trusted proxy được cấu hình.

Nếu không, attacker có thể giả mạo IP để phá rate limit hoặc audit trail.

---

# 20. Security headers

Production nên cấu hình tối thiểu:

```text
Content-Security-Policy
X-Content-Type-Options
Referrer-Policy
Permissions-Policy
Strict-Transport-Security
```

`X-Frame-Options` hoặc `frame-ancestors` trong CSP dùng để chống clickjacking tùy nhu cầu embedding.

HSTS chỉ bật khi production HTTPS đã đúng.

---

# 21. Secrets management

Không commit production secrets vào Git.

Các secret bao gồm:

- JWT signing key hoặc private key.
- Database password production.
- Redis password production.
- MinIO credentials production.
- Encryption keys.
- SMTP credentials.

Development credentials trong Docker Compose phải được nhận diện rõ là development-only.

Production dùng environment secrets hoặc secret manager.

JWT signing algorithm và key strategy chưa được chốt trong tài liệu này.

---

# 22. Testing requirements

## 22.1. Authentication tests

Bắt buộc có:

- Login thành công.
- Sai password.
- Username không tồn tại.
- Account locked.
- Account disabled.
- Access token hết hạn.
- Access token token-version mismatch.
- Refresh token hợp lệ.
- Refresh token hết hạn.
- Refresh token revoked.
- Refresh rotation.
- Reuse token cũ.
- Logout current session.
- Logout all sessions.

## 22.2. Authorization tests

Bắt buộc có:

- Không token → 401.
- Token hợp lệ nhưng thiếu permission → 403.
- Có permission nhưng sai ownership → 403.
- Có permission nhưng sai school scope → 403.
- Teacher truy cập tài nguyên teacher khác → 403.
- Proctor truy cập session không được phân công → 403.
- Student truy cập attempt người khác → 403.
- Student bắt đầu session không phải participant → 403.
- Resource state không cho phép → 409 hoặc 422 theo API convention.
- Ngoài time window → từ chối.

## 22.3. Persistence assertions

Bắt buộc xác nhận:

- Password plaintext không tồn tại trong DB.
- Refresh token plaintext không tồn tại trong DB.
- Token cũ bị revoke sau rotation.
- Session mới giữ đúng family ID.
- Parent/replacement links đúng.
- Reuse revoke toàn family.
- Logout all tăng token version.
- Published exam snapshot không thay đổi khi question bank thay đổi.

## 22.4. Integration environment

Ưu tiên PostgreSQL Testcontainers để test đúng:

- UUID.
- INET.
- TIMESTAMPTZ.
- PostgreSQL constraints.
- Flyway migrations.

Không dùng H2 để kết luận schema PostgreSQL hoạt động đúng nếu các kiểu dữ liệu và constraint khác biệt.

---

# 23. Các quyết định chưa chốt

Các mục sau phải được quyết định trước khi triển khai tương ứng:

- Access token lifetime.
- Refresh token lifetime.
- JWT signing algorithm.
- JWT key rotation.
- Argon2id parameters.
- Failed login threshold.
- Lockout duration.
- SameSite cookie value production.
- CSRF strategy cụ thể cho refresh/logout.
- Permission claims có nằm trong JWT hay không.
- Role-permission catalog cuối cùng.
- Health endpoint exposure production.
- Password complexity policy.
- Password reset flow.
- MFA.
- OAuth/SSO.

Không được coi ví dụ trong tài liệu cũ là quyết định chính thức.

---

# 24. Acceptance criteria cho Security foundation

Security foundation được xem là đạt khi:

```text
[ ] Role và permission catalog được chốt
[ ] V3 seed chạy thành công
[ ] Password dùng Argon2id
[ ] Access JWT ngắn hạn
[ ] Access token chỉ giữ trong frontend memory
[ ] Refresh token là opaque HttpOnly cookie
[ ] Database chỉ lưu refresh token hash
[ ] Rotation hoạt động transactionally
[ ] Reuse detection revoke toàn family
[ ] Logout current hoạt động
[ ] Logout all tăng token version
[ ] /users/me không lộ field nhạy cảm
[ ] 401 và 403 được phân biệt
[ ] Ownership/scope/state/time được test
[ ] Không endpoint mới public ngoài ý muốn
```

---

# 25. Bước tiếp theo

Trước khi tạo:

```text
V3__seed_roles_and_permissions.sql
```

cần thực hiện:

1. Liệt kê use case MVP theo từng role.
2. Chuyển use case thành permission catalog.
3. Chốt role-permission matrix.
4. Review các permission quá rộng hoặc bị trùng.
5. Chỉ sau khi được phê duyệt mới viết migration V3.

Không viết V3 dựa trên role hierarchy hoặc permission matrix cũ.
