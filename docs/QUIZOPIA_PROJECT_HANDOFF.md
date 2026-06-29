# Quizopia System — Project Handoff & Continuity Guide

> Mục đích của tài liệu này là giúp một phiên ChatGPT khác, một tài khoản khác, hoặc một thành viên mới có thể tiếp tục dự án Quizopia đúng luồng, không làm sai kiến trúc, không sửa nhầm migration đã áp dụng, và không phá vỡ cấu trúc Git submodule.
>
> Cập nhật lần cuối: 2026-06-28  
> Trạng thái hiện tại: Hoàn tất checkpoint trước V3

---

# 1. Tóm tắt dự án

Quizopia là một hệ thống thi/trắc nghiệm trực tuyến đang được xây dựng theo hướng học từng bước, ưu tiên nền tảng kiến trúc, bảo mật và khả năng bảo trì trước khi triển khai nhiều chức năng.

Dự án hiện sử dụng:

- Backend: Spring Boot, Java 21
- Frontend: Next.js, TypeScript, Tailwind CSS
- Database: PostgreSQL
- Cache/session support: Redis
- Object storage: MinIO
- Development mail server: Mailpit
- Database migration: Flyway
- ORM: Spring Data JPA / Hibernate
- Deployment local development: 100% Docker / Docker Compose
- Version control: Git với backend và frontend là Git submodule

Mục tiêu xác thực và phân quyền:

- Đăng nhập bằng username/password
- Mật khẩu băm bằng Argon2id
- Access token JWT có thời hạn ngắn
- Refresh token dạng opaque token
- Chỉ lưu hash của refresh token trong database
- Refresh token rotation
- Phát hiện refresh token reuse theo token family
- Logout phiên hiện tại
- Logout toàn bộ phiên
- Endpoint `/users/me`
- RBAC kết hợp ownership, assignment, enrollment, trạng thái tài nguyên và thời gian
- Mặc định từ chối truy cập nếu không có quyền rõ ràng

---

# 2. Nguyên tắc làm việc với người dùng

## 2.1. Tiến độ từng bước rất nhỏ

Người dùng muốn làm cực kỳ chậm và tuần tự.

Quy tắc:

1. Chỉ đưa một bước tại một thời điểm.
2. Sau mỗi lệnh hoặc nhóm lệnh nhỏ, phải chờ người dùng gửi kết quả.
3. Không tự động nhảy sang bước tiếp theo.
4. Người dùng sẽ nói `chuyển bước` khi muốn tiếp tục phần mới.
5. Không dump toàn bộ roadmap kỹ thuật thành một khối lệnh dài.
6. Luôn giải thích ngắn gọn mục đích của bước hiện tại.

## 2.2. Ngôn ngữ

- Giao tiếp bằng tiếng Việt.
- Có thể giữ nguyên thuật ngữ kỹ thuật tiếng Anh khi cần.
- Giải thích dễ hiểu, tránh quá nhiều jargon.

## 2.3. Coding agent

Người dùng có dùng coding agent hỗ trợ tag file bằng cú pháp `@File.java`.

Khi viết prompt để người dùng gửi cho coding agent:

- Dùng `@User.java`, `@Role.java`, v.v.
- Không cần ghi đường dẫn package quá dài trong prompt.
- Nói rõ người dùng cần tag/chọn những file nào.
- Prompt phải giới hạn phạm vi thay đổi.
- Không để agent tự ý refactor ngoài phạm vi.

Ví dụ:

```text
Hãy kiểm tra equals/hashCode trong các file:
@UserRole.java
@RolePermission.java

Yêu cầu:
- Không sửa schema.
- Không thêm Lombok.
- Không đổi package.
- Chỉ sửa logic equality cho embedded ID.
```

## 2.4. Không tự ý thay đổi phần chưa được yêu cầu

Đặc biệt:

- Không sửa frontend khi đang làm backend.
- Không stage hoặc commit `.claude/` và `.vscode/` nếu chưa được yêu cầu.
- Không sửa migration đã được Flyway áp dụng.
- Không chuyển khỏi mô hình Git submodule.
- Không thay thế Docker bằng cách chạy Maven trực tiếp trên máy host.

---

# 3. Cấu trúc repository

Thư mục gốc trên máy người dùng:

```text
D:\ViettelDigitalTalent\quizopia-system
```

Repository cha:

```text
Quizopia-System
```

Remote:

```text
https://github.com/hhtuann/Quizopia-System.git
```

Backend là Git submodule:

```text
quizopia-system/backend
```

Remote backend:

```text
https://github.com/hhtuann/quizopia_backend.git
```

Frontend là Git submodule:

```text
quizopia-system/frontend
```

Không được chuyển backend/frontend thành thư mục Git bình thường.

## 3.1. Quy tắc commit với submodule

Khi backend có thay đổi:

1. Commit trong repository `backend`.
2. Push backend trước.
3. Quay lại repository cha.
4. Stage con trỏ submodule `backend`.
5. Commit repository cha.
6. Push repository cha sau.

Lý do: repository cha trỏ đến một commit cụ thể của backend. Nếu push cha trước nhưng commit backend chưa có trên remote, người khác clone sẽ không tải được đúng commit submodule.

---

# 4. Docker Compose

Người dùng yêu cầu dự án chạy 100% bằng Docker.

Các service chính:

```text
minio
postgres-db
redis-cache
backend
frontend
mailpit
```

Container names đã dùng:

```text
quizopia_backend
quizopia_postgres
quizopia_redis
```

Backend dùng các biến môi trường trong Docker Compose:

```text
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-db:5432/quizopia_db
SPRING_DATASOURCE_USERNAME=quiz_user
SPRING_DATASOURCE_PASSWORD=quiz_password

SPRING_DATA_REDIS_HOST=redis-cache
SPRING_DATA_REDIS_PORT=6379
SPRING_DATA_REDIS_PASSWORD=redis_password
```

Các mật khẩu trên là development credentials trong Docker Compose, không phải production secrets.

## 4.1. Backend Dockerfile

Backend đang dùng multi-stage build:

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring

COPY --from=builder /app/target/*.jar app.jar
RUN chown -R spring:spring /app

USER spring

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

Yêu cầu quan trọng:

- Không chạy backend trực tiếp bằng `mvn spring-boot:run` trên host như luồng chính.
- Sau thay đổi Java hoặc dependency, build lại image backend.
- Dùng Docker logs để xác nhận Flyway và Hibernate.

---

# 5. Backend

Base package:

```text
com.hhtuann.backend
```

Công nghệ:

- Java 21
- Spring Boot 4.1.0
- Hibernate 7.4.1
- Jakarta Persistence
- PostgreSQL
- Flyway

Cấu hình hiện dùng:

```text
src/main/resources/application.properties
```

Không dùng YAML ở thời điểm hiện tại.

Một cấu hình quan trọng:

```properties
spring.jpa.hibernate.ddl-auto=validate
```

Ý nghĩa:

- Hibernate không tự tạo/sửa schema.
- Flyway là nguồn sự thật duy nhất cho database schema.
- Hibernate chỉ kiểm tra entity mapping có khớp schema hay không.

Flyway location:

```properties
spring.flyway.locations=classpath:db/migration
```

---

# 6. Lịch sử triển khai từ ngày đầu

## Day 1 — Nền tảng Docker, PostgreSQL, Redis, Flyway

### 6.1. Mục tiêu

- Backend chạy được trong Docker.
- Kết nối PostgreSQL.
- Kết nối Redis.
- Kích hoạt Flyway.
- Kích hoạt Actuator health check.
- Hibernate dùng `ddl-auto=validate`.
- Tạo migration nền tảng đầu tiên.

### 6.2. Flyway dependency cho Spring Boot 4

Dependency đã được chỉnh thành:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-flyway</artifactId>
</dependency>

<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-database-postgresql</artifactId>
</dependency>
```

### 6.3. Migration V1

File:

```text
backend/src/main/resources/db/migration/V1__initialize_database.sql
```

V1 tạo bảng:

```text
platform_metadata
```

Và insert các metadata nền tảng như:

```text
application_name
database_type
schema_stage
```

### 6.4. Sự cố đã xảy ra

Từng có các file migration rỗng:

```text
V2
V3
V4
V5
V6
V7
```

Flyway đã ghi nhận các migration rỗng đó là đã chạy.

Cách xử lý đã thực hiện:

1. Dừng backend.
2. Xóa các migration rỗng V2–V7.
3. Drop:
   - `platform_metadata`
   - `flyway_schema_history`
4. Build lại backend với no-cache.
5. Khởi động lại.
6. Flyway chạy lại đúng V1.

Trạng thái sau sửa:

- V1 áp dụng thành công.
- Không còn migration rỗng giả.
- Từ thời điểm này không được sửa V1.

### 6.5. Health check

Actuator endpoint đã trả về `UP`.

Các component đã xác nhận:

```text
db
redis
livenessState
readinessState
```

---

## Day 2 — Identity schema và JPA domain model

### 6.6. Migration V2

File:

```text
backend/src/main/resources/db/migration/V2__create_identity_schema.sql
```

V2 đã được Flyway áp dụng thành công.

Không được sửa V2 nữa.

V2 tạo 6 bảng:

```text
users
roles
permissions
user_roles
role_permissions
refresh_sessions
```

Tổng số bảng sau V2 gồm cả bảng hệ thống và metadata là 8.

---

# 7. Chi tiết schema Identity V2

## 7.1. `users`

Các cột chính:

```text
id
username
email
password_hash
display_name
status
token_version
failed_login_attempts
locked_until
last_login_at
password_changed_at
created_at
updated_at
```

Đặc điểm:

- `id`: BIGINT identity
- `username`: VARCHAR(50)
- `email`: VARCHAR(254)
- `password_hash`: VARCHAR(255)
- `display_name`: VARCHAR(150)
- `status`: mặc định `ACTIVE`
- `token_version`: mặc định 0, không âm
- `failed_login_attempts`: mặc định 0, không âm
- `locked_until`: nullable TIMESTAMPTZ
- `last_login_at`: nullable TIMESTAMPTZ
- `password_changed_at`: NOT NULL, mặc định CURRENT_TIMESTAMP
- Có `created_at`, `updated_at`

Giá trị status hợp lệ:

```text
ACTIVE
LOCKED
DISABLED
PENDING
```

Unique index theo kiểu không phân biệt hoa thường:

```sql
lower(username)
lower(email)
```

Có index theo `status`.

## 7.2. `roles`

Các cột chính:

```text
id
code
name
description
created_at
updated_at
```

Đặc điểm:

- `code` unique
- `code` phải theo định dạng uppercase
- Dùng cho các role hệ thống

Role mục tiêu:

```text
SYSTEM_ADMIN
ACADEMIC_ADMIN
TEACHER
PROCTOR
STUDENT
```

Lưu ý quan trọng:

```text
SYSTEM_ADMIN không tự động là academic superuser.
```

Mọi quyền học thuật vẫn phải được cấp rõ ràng.

## 7.3. `permissions`

Các cột chính:

```text
id
code
name
description
created_at
updated_at
```

Đặc điểm:

- `code` unique
- `code` dùng uppercase convention
- Permission catalog sẽ được seed ở V3 hoặc migration tiếp theo

## 7.4. `user_roles`

Bảng liên kết user-role.

Khóa chính tổng hợp:

```text
user_id
role_id
```

Các cột bổ sung:

```text
assigned_by
assigned_at
expires_at
```

Đặc điểm:

- `assigned_by` nullable FK tới user
- Có thể hỗ trợ role hết hạn
- Có check constraint cho thời gian hết hạn
- Có index cần thiết
- Không dùng JPA `ManyToMany`

## 7.5. `role_permissions`

Bảng liên kết role-permission.

Khóa chính tổng hợp:

```text
role_id
permission_id
```

Các cột bổ sung:

```text
granted_by
granted_at
```

Đặc điểm:

- `granted_by` nullable
- Không dùng JPA `ManyToMany`
- Có index hỗ trợ truy vấn

## 7.6. `refresh_sessions`

Các cột chính:

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

Đặc điểm quan trọng:

- `id`: UUID
- `family_id`: UUID
- `token_hash`: VARCHAR(64), unique
- Chỉ lưu hash token, không lưu refresh token plaintext
- `parent_session_id`: self reference
- `replaced_by_session_id`: self reference
- `created_ip`: PostgreSQL INET
- `last_used_ip`: PostgreSQL INET
- Có constraint ngăn self-reference
- Có logic consistency giữa replacement và revoked state
- Có index cho user, family, expiration và trạng thái phiên

Mục tiêu thiết kế:

- Rotation mỗi lần refresh
- Mỗi token mới có thể trỏ tới token cha
- Token cũ trỏ tới token thay thế
- Nếu token đã dùng lại, revoke toàn bộ family

---

# 8. JPA entities đã hoàn thành

Thư mục:

```text
backend/src/main/java/com/hhtuann/backend/identity/domain/model
```

Có 9 file:

```text
Permission.java
RefreshSession.java
Role.java
RolePermission.java
RolePermissionId.java
User.java
UserRole.java
UserRoleId.java
UserStatus.java
```

## 8.1. Mapping rules

Các quyết định đã dùng:

- Jakarta Persistence
- Field access
- Tất cả association là `LAZY`
- Không dùng `ManyToMany`
- Không dùng `CascadeType.ALL`
- Dùng `Instant` cho TIMESTAMPTZ
- Dùng `UUID` cho UUID database
- Dùng `InetAddress` cho PostgreSQL INET
- Mapping INET bằng:

```java
@JdbcTypeCode(SqlTypes.INET)
```

- `UserStatus` là enum
- Join entity dùng embedded ID
- Không để hash nhạy cảm xuất hiện trong `toString()`

## 8.2. Equality cho entity có ID sinh tự động

Áp dụng cho:

```text
User
Role
Permission
RefreshSession
```

Mẫu logic:

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof User other)) return false;
    return getId() != null && getId().equals(other.getId());
}

@Override
public int hashCode() {
    return User.class.hashCode();
}
```

Mỗi entity dùng class tương ứng trong `hashCode()`.

Mục đích:

- Hai entity chưa persist, ID null, không bị coi là giống nhau.
- Hash code ổn định trước và sau persist.
- Tránh lỗi khi entity nằm trong `HashSet`.

## 8.3. Equality cho join entity

Áp dụng cho:

```text
UserRole
RolePermission
```

Hai entity này dùng embedded ID.

Đã thêm logic kiểm tra embedded ID đầy đủ trước khi so sánh.

Required associations dùng:

```java
optional = false
```

`hashCode()` dùng class constant.

## 8.4. Embedded ID

Áp dụng cho:

```text
UserRoleId
RolePermissionId
```

`equals()` và `hashCode()` dùng đầy đủ tất cả field với `Objects.equals()` và `Objects.hash()`.

## 8.5. Kết quả validate

Backend đã khởi động thành công sau khi tạo entities.

Log xác nhận:

- Flyway validate thành công 2 migration
- Hibernate EntityManagerFactory khởi tạo thành công
- `ddl-auto=validate` không báo mismatch
- Backend started

Điều này chứng minh entity mapping hiện tại khớp với V2 schema.

---

# 9. Test configuration

Các file liên quan đã có:

```text
src/test/java/com/hhtuann/backend/QuizopiaBackendApplicationTests.java
src/test/resources/application-test.properties
```

Mục đích:

- Tách test configuration khỏi runtime configuration
- Tránh test vô tình phụ thuộc vào môi trường Docker runtime không phù hợp
- Chuẩn bị cho integration test sau này

Cần kiểm tra nội dung thực tế trong repository trước khi mở rộng test.

---

# 10. Git checkpoint hiện tại

## 10.1. Backend commit

```text
c59e411 feat(identity): add Flyway schema and JPA models
```

Remote state:

```text
backend/main == origin/main
```

## 10.2. Root commit

```text
8e13c57 docs: establish Quizopia foundation and architecture
```

Remote state:

```text
main == origin/main
```

## 10.3. Local changes chưa commit

Tại repository cha vẫn còn:

```text
 m frontend
?? .claude/
?? .vscode/
```

Ý nghĩa:

- `frontend` có thay đổi bên trong submodule nhưng chưa commit.
- `.claude/` chưa tracked.
- `.vscode/` chưa tracked.

Không được tự ý stage hoặc commit ba mục này khi đang tiếp tục backend V3.

---

# 11. Sự cố encoding đã xảy ra

Một PowerShell script dùng `Get-Content` và `Set-Content -Encoding utf8` đã làm hỏng hiển thị tiếng Việt trong một số file Markdown.

Các file bị tác động tạm thời:

```text
README.md
docs/adr/001-use-modular-monolith.md
docs/architecture.md
docs/database.md
docs/security.md
```

Do các file đã được stage trước đó, đã khôi phục working tree từ staging area bằng:

```powershell
git restore --worktree -- `
  README.md `
  docs/adr/001-use-modular-monolith.md `
  docs/architecture.md `
  docs/database.md `
  docs/security.md
```

Kết quả đã khôi phục thành công.

Bài học:

- Không chạy script rewrite toàn bộ Markdown nếu chưa chắc encoding gốc.
- `git diff --cached --check` chỉ cảnh báo trailing whitespace.
- Trailing whitespace trong Markdown đôi khi được formatter tạo ra để ép line break.
- Không cần sửa các warning đó nếu không ảnh hưởng chức năng.
- Tránh dùng `git reset --hard`.

---

# 12. Trạng thái hiện tại trước V3

Đã hoàn thành:

- Docker Compose foundation
- Backend Dockerfile
- PostgreSQL connection
- Redis connection
- Actuator health
- Flyway integration
- V1 metadata migration
- V2 identity schema
- Identity JPA entities
- Hibernate schema validation
- Backend Git commit và push
- Root documentation commit và push

Chưa bắt đầu:

```text
V3__seed_roles_and_permissions.sql
```

Đây là bước tiếp theo.

---

# 13. Kế hoạch chi tiết từ V3 trở đi

Phần dưới là kế hoạch đề xuất để tiếp tục theo đúng kiến trúc hiện tại. Các bước phải được thực hiện tuần tự và kiểm chứng sau mỗi phần.

## Phase 3 — Seed roles và permissions

### Mục tiêu

Tạo migration:

```text
V3__seed_roles_and_permissions.sql
```

### Nội dung dự kiến

Seed 5 role:

```text
SYSTEM_ADMIN
ACADEMIC_ADMIN
TEACHER
PROCTOR
STUDENT
```

Tạo permission catalog theo domain.

Các nhóm permission nên xem xét:

```text
USER_*
ROLE_*
COURSE_*
CLASS_*
QUESTION_*
QUESTION_BANK_*
EXAM_*
EXAM_SESSION_*
PROCTORING_*
SUBMISSION_*
RESULT_*
REPORT_*
SYSTEM_*
```

Không nên tự bịa permission code ngay lập tức.

Trước khi viết V3 cần đọc:

```text
docs/security.md
docs/api.md
docs/architecture.md
docs/database.md
```

Yêu cầu V3:

- Dữ liệu seed phải deterministic.
- Không hard-code numeric ID nếu có thể tránh.
- Dùng role/permission code làm natural key.
- Phân quyền phải explicit.
- Không cấp mọi academic permission cho SYSTEM_ADMIN chỉ vì tên role.
- Migration phải có comment rõ ràng.
- Sau khi áp dụng V3, không sửa lại V3.

### Kiểm chứng

- Flyway database version tăng lên 3.
- Các role tồn tại đúng 5 bản ghi.
- Permission không bị duplicate.
- Role-permission mapping đúng thiết kế.
- Backend vẫn start và Hibernate validate thành công.

## Phase 4 — Repository layer cho Identity

Tạo repository:

```text
UserRepository
RoleRepository
PermissionRepository
UserRoleRepository
RolePermissionRepository
RefreshSessionRepository
```

Nguyên tắc:

- Repository interface nhỏ, đúng nhu cầu.
- Không viết query thừa.
- Query username/email phải hỗ trợ case-insensitive theo schema.
- Tránh N+1 khi load user cùng role/permission.
- Dùng projection hoặc entity graph có chủ đích.
- Không đổi entity relationship thành eager.

Các query cần dần có:

```text
find user by username
find user by email
check username exists
check email exists
load active roles for user
load effective permissions for user
find refresh session by token hash
find active sessions by user
find family sessions
```

## Phase 5 — Security primitives

### Password hashing

- Dùng Argon2id.
- Không log password.
- Không log password hash.

Nên có abstraction:

```text
PasswordHasher
Argon2PasswordHasher
```

### Access token JWT

JWT nên chứa tối thiểu:

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

Cần cân nhắc không nhét quá nhiều permission vào token nếu permission có thể thay đổi thường xuyên.

Access token:

- Thời hạn ngắn.
- Verify signature.
- Verify expiration.
- Verify token version với user.
- Không dùng refresh token như JWT access token.

### Refresh token

- Sinh random đủ mạnh.
- Token gửi cho client là opaque.
- Database chỉ lưu hash của token.
- Không log refresh token plaintext.

## Phase 6 — Authentication use cases

Các use case chính:

```text
Login
RefreshToken
LogoutCurrentSession
LogoutAllSessions
GetCurrentUser
```

### Login

1. Nhận username/email và password.
2. Tìm user không phân biệt hoa thường.
3. Kiểm tra status.
4. Kiểm tra locked state.
5. Verify Argon2id password hash.
6. Nếu sai, tăng failed login attempts và áp dụng lock policy.
7. Nếu đúng:
   - reset failed attempts
   - cập nhật last login
   - tạo access JWT
   - tạo refresh token
   - hash refresh token
   - lưu refresh session
8. Trả token pair.

### Refresh

1. Nhận opaque refresh token.
2. Hash token.
3. Tìm refresh session.
4. Kiểm tra expiration.
5. Kiểm tra revoked.
6. Kiểm tra user status.
7. Nếu hợp lệ:
   - revoke token cũ
   - tạo token mới cùng family
   - link parent/replacement
   - tạo access JWT mới
8. Nếu phát hiện token cũ đã rotate nhưng bị dùng lại:
   - revoke toàn bộ family
   - từ chối request

### Logout current session

- Revoke refresh session hiện tại.
- Access JWT có thể còn hiệu lực đến khi hết hạn do access token có thời hạn ngắn.

### Logout all sessions

- Revoke tất cả refresh session của user.
- Tăng `token_version` để vô hiệu hóa access JWT cũ.

### `/users/me`

Trả thông tin user hiện tại cùng role/permission cần thiết.

Không trả:

```text
password_hash
refresh token hash
internal security fields không cần thiết
```

## Phase 7 — Spring Security integration

Cần cấu hình:

- Stateless security
- JWT authentication filter
- AuthenticationEntryPoint cho 401
- AccessDeniedHandler cho 403
- CORS rõ ràng
- CSRF policy phù hợp với token-based API
- Method security

Authorization phải kết hợp:

- Role
- Permission
- Ownership
- Assignment
- Enrollment
- Resource state
- Exam time window
- Organization/course/class context

Ví dụ:

- TEACHER không được sửa exam của teacher khác nếu không có assignment.
- PROCTOR chỉ được truy cập session được phân công.
- STUDENT chỉ được thi exam mà mình được enroll và trong thời gian cho phép.
- SYSTEM_ADMIN không tự động được sửa nội dung học thuật nếu không có permission tương ứng.

## Phase 8 — API error model

Nên tạo error response thống nhất:

```json
{
  "timestamp": "...",
  "status": 401,
  "code": "AUTH_INVALID_CREDENTIALS",
  "message": "Invalid username or password",
  "path": "/api/auth/login",
  "traceId": "..."
}
```

Không tiết lộ:

- Username có tồn tại hay không
- Password đúng/sai cụ thể
- Token nội bộ
- Stack trace production
- SQL error chi tiết

## Phase 9 — Tests bắt buộc

Cần test ít nhất:

```text
successful login
wrong password
unknown username
disabled user
locked user
expired access token
expired refresh token
revoked refresh token
refresh token rotation
reuse old refresh token
logout current session
logout all sessions
/users/me
cross-role access denied
ownership denied
plaintext token not stored
plaintext password not stored
```

Database assertions:

- `password_hash` không chứa password plaintext.
- `refresh_sessions.token_hash` không chứa refresh token plaintext.
- Token cũ bị revoked sau refresh.
- Family bị revoke sau reuse.
- `token_version` tăng sau logout-all.

## Phase 10 — Frontend authentication integration

Chỉ bắt đầu khi backend auth API ổn định.

Frontend cần:

- Login page
- Access token lifecycle
- Refresh handling
- Logout
- Route protection
- Role-aware navigation

Frontend route guard không phải security boundary. Backend mới là nơi bắt buộc kiểm tra quyền.

Không commit thay đổi frontend hiện tại cho đến khi xác định rõ chúng là gì.

---

# 14. Lệnh kiểm tra thường dùng

## 14.1. Git backend

```powershell
git -C .\backend status --short
git -C .\backend log -1 --oneline
git -C .\backend branch -vv
```

## 14.2. Git root

```powershell
git status --short
git log -1 --oneline
git branch -vv
```

## 14.3. Docker Compose

```powershell
docker compose ps
docker compose logs backend
docker compose logs postgres-db
docker compose logs redis-cache
```

Build backend:

```powershell
docker compose build backend
```

Build no-cache khi thật sự cần:

```powershell
docker compose build --no-cache backend
```

Khởi động:

```powershell
docker compose up -d
```

Restart backend:

```powershell
docker compose up -d --force-recreate backend
```

## 14.4. Kiểm tra Flyway qua logs

Tìm các dòng:

```text
Successfully validated
Current version of schema
Migrating schema
Successfully applied
```

## 14.5. Kiểm tra staged changes

```powershell
git diff --cached --stat
git diff --cached
```

`git diff --cached --check` chỉ là kiểm tra whitespace, không phải điều kiện bắt buộc để commit.

Nếu Git mở pager, nhấn:

```text
q
```

Nếu không thoát được:

```text
Ctrl + C
```

---

# 15. Quy tắc migration tuyệt đối

1. Mỗi thay đổi schema là một migration mới.
2. Không sửa migration đã được áp dụng.
3. Không đổi tên migration đã áp dụng.
4. Không xóa migration đã áp dụng.
5. Không tạo file migration rỗng để giữ chỗ.
6. Không dùng Hibernate để tự sửa schema.
7. Migration phải được test trên database sạch và database hiện tại.
8. Sau mỗi migration:
   - kiểm tra Flyway logs
   - kiểm tra schema
   - kiểm tra backend start
   - kiểm tra Hibernate validate

Đã khóa:

```text
V1__initialize_database.sql
V2__create_identity_schema.sql
```

Bước tiếp theo phải là:

```text
V3__seed_roles_and_permissions.sql
```

---

# 16. Quy tắc bảo mật tuyệt đối

- Không lưu password plaintext.
- Không lưu refresh token plaintext.
- Không log access token.
- Không log refresh token.
- Không trả hash ra API.
- Không cấp quyền chỉ dựa vào frontend.
- Không dùng role như shortcut thay thế toàn bộ permission.
- Không mặc định SYSTEM_ADMIN có mọi quyền học thuật.
- Không dùng token không có expiration.
- Không dùng refresh token rotation mà thiếu reuse detection.
- Không để endpoint mới public ngoài ý muốn.
- Không dùng `permitAll()` quá rộng.
- Không dùng `CascadeType.ALL` tùy tiện trong identity model.

---

# 17. Checklist trước mỗi commit

## Backend submodule

```text
[ ] Chỉ thay đổi đúng phạm vi
[ ] Backend build thành công
[ ] Flyway thành công
[ ] Hibernate validate thành công
[ ] Test cần thiết chạy thành công
[ ] Không có secret production
[ ] Không sửa migration cũ
[ ] git diff đã được đọc
[ ] Commit trong backend trước
[ ] Push backend trước
```

## Root repository

```text
[ ] Con trỏ backend trỏ tới commit đã push
[ ] Không stage frontend ngoài ý muốn
[ ] Không stage .claude/
[ ] Không stage .vscode/
[ ] Docs và Docker Compose đúng phạm vi
[ ] Commit root
[ ] Push root sau backend
```

---

# 18. Trạng thái cần xác nhận khi bắt đầu phiên mới

Một ChatGPT mới nên yêu cầu người dùng chạy:

```powershell
git status --short
git branch -vv
git -C .\backend status --short
git -C .\backend branch -vv
docker compose ps
```

Sau đó kiểm tra:

- Root đang ở commit `8e13c57` hoặc commit mới hơn hợp lệ.
- Backend đang ở `c59e411` hoặc commit mới hơn hợp lệ.
- Không có thay đổi backend chưa rõ nguồn gốc.
- Frontend vẫn có thể hiện `m frontend`.
- `.claude/` và `.vscode/` vẫn có thể untracked.
- Docker services ở trạng thái hợp lý.
- Flyway database hiện ở version 2 trước khi chạy V3.

Không nên giả định repository vẫn đúng trạng thái nếu chưa kiểm tra các lệnh trên.

---

# 19. Prompt dùng để bàn giao cho một ChatGPT khác

Có thể gửi nguyên văn phần dưới cùng với file này:

```text
Tôi đang tiếp tục dự án Quizopia.

Hãy đọc toàn bộ file QUIZOPIA_PROJECT_HANDOFF.md trước khi hướng dẫn.

Yêu cầu làm việc:
- Hướng dẫn bằng tiếng Việt.
- Chỉ đưa một bước nhỏ mỗi lần.
- Sau mỗi bước phải chờ tôi gửi kết quả.
- Không tự ý sửa frontend.
- Không tự ý stage .claude hoặc .vscode.
- Backend và frontend là Git submodule.
- Dự án chạy 100% Docker.
- Flyway là nguồn sự thật cho schema.
- Không sửa V1 hoặc V2.
- Bước tiếp theo hiện tại là V3__seed_roles_and_permissions.sql.
- Khi viết prompt cho coding agent, dùng @File.java để tôi tag file.
- Trước khi bắt đầu, hãy yêu cầu tôi kiểm tra Git status, branch và Docker state.
```

---

# 20. Điểm tiếp tục chính xác

Điểm tiếp tục hiện tại:

```text
Bắt đầu thiết kế V3__seed_roles_and_permissions.sql
```

Nhưng chưa được viết migration ngay lập tức.

Trình tự đúng:

1. Kiểm tra Git và Docker state.
2. Đọc `docs/security.md`.
3. Đọc `docs/api.md`.
4. Xác định permission catalog MVP.
5. Xác định role-permission matrix.
6. Review với người dùng.
7. Sau khi chốt mới tạo V3.
8. Build Docker backend.
9. Chạy Flyway.
10. Kiểm tra dữ liệu seed.
11. Commit backend.
12. Push backend.
13. Commit root submodule pointer nếu cần.
14. Push root.

---

# 21. Những điều chưa được xác nhận

Không được tự giả định các nội dung sau nếu chưa đọc repository hiện tại:

- Danh sách permission code cuối cùng
- API endpoint path cuối cùng
- JWT library cuối cùng
- Thời gian sống access token
- Thời gian sống refresh token
- Lockout threshold
- Lockout duration
- Cookie hay Authorization header cho refresh token
- CORS origins production
- Production secret management
- Frontend local changes hiện có là gì

Các quyết định này phải được thảo luận hoặc kiểm tra trong code/docs trước khi triển khai.

---

# 22. Kết luận

Dự án đã hoàn thành nền tảng quan trọng nhất:

- Hạ tầng Docker
- PostgreSQL và Redis
- Flyway
- Identity schema
- JPA model
- Validation giữa code và database
- Git checkpoint rõ ràng

Ưu tiên tiếp theo không phải viết nhanh nhiều endpoint, mà là chốt permission model đúng ngay từ V3. Sai permission catalog ở giai đoạn này sẽ khiến toàn bộ authentication và authorization về sau phải sửa lại.

Do đó, bước tiếp theo phải bắt đầu bằng review tài liệu bảo mật và tạo role-permission matrix, không bắt đầu bằng việc code controller.
