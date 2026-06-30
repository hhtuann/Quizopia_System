# Quizopia System — Project Handoff & Continuity Guide

> Mục đích của tài liệu này là giúp một phiên ChatGPT khác, một tài khoản khác, hoặc một thành viên mới có thể tiếp tục dự án Quizopia đúng luồng, không làm sai kiến trúc, không sửa nhầm migration đã áp dụng, và không phá vỡ cấu trúc Git submodule.
>
> Cập nhật lần cuối: 2026-06-30  
> Trạng thái hiện tại: Hoàn tất Day 4 — Authentication Backend (Database đang ở Flyway version 5)

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

Người dùng đã cài AgentKit và GitNexus skills cho Claude, nên coding agent có thể được điều khiển bằng lệnh slash và skill ngoài việc tag file.

Khi viết prompt để người dùng gửi cho coding agent:

- Có thể gọi một hoặc hai skill phù hợp ở đầu prompt (ví dụ `/ak:databases`, `/ak:fix`, skill GitNexus). Không gọi quá nhiều skill không liên quan đến nhiệm vụ.
- Dùng `@User.java`, `@Role.java`, v.v. để tag file.
- Mỗi file cần tag phải nằm trên một dòng riêng.
- Không có dấu chấm, dấu phẩy hoặc ký tự khác ngay sau tên file được tag (viết `@UserRole.java` trên một dòng, không phải `@UserRole.java,` hay `@UserRole.java.`).
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
https://github.com/hhtuann/Quizopia_System.git
```

Backend là Git submodule:

```text
quizopia-system/backend
```

Remote backend:

```text
https://github.com/hhtuann/Quizopia_Backend.git
```

`.gitmodules` đã được cập nhật sang backend remote mới (`Quizopia_Backend.git`). Backend và frontend vẫn là Git submodule.

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

## Day 2 — Identity schema, JPA domain model, permission catalog và V3 seed

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

### 6.7. JPA domain model và Hibernate validation

9 file entity đã được tạo trong:

```text
backend/src/main/java/com/hhtuann/backend/identity/domain/model
```

Chi tiết mapping và equality rules nằm ở mục 8.

Hibernate `ddl-auto=validate` đã pass: entity mapping khớp đúng V2 schema.

### 6.8. Permission catalog và role-permission matrix đã chốt

`docs/security.md` đã được phê duyệt làm nguồn sự thật cho authorization model:

- Đúng 4 role: `SYSTEM_ADMIN`, `ACADEMIC_ADMIN`, `TEACHER`, `STUDENT`.
- Đúng 84 permission theo nhóm Identity & System, Academic, Question Bank, Exam, Attempt, Grading, Reporting.
- Không còn role `PROCTOR` và không có permission `ATTEMPT_CANCEL`.
- Role-permission matrix:
  - `SYSTEM_ADMIN`: 13
  - `ACADEMIC_ADMIN`: 51
  - `TEACHER`: 46
  - `STUDENT`: 9
- Tổng 119 role-permission mapping.
- `TEACHER` tự giám sát ca thi bằng `EXAM_SESSION_MONITOR`.

### 6.9. Migration V3

File:

```text
backend/src/main/resources/db/migration/V3__seed_roles_and_permissions.sql
```

V3 đã được Flyway áp dụng thành công và kiểm chứng trực tiếp trong PostgreSQL.

Kết quả thực tế:

- Flyway database version sau V3 là 3 (sau Day 3, V4 nâng lên version 4).
- 4 role.
- 84 permission.
- 119 role-permission mapping.
- Mapping count theo role đúng 13 / 51 / 46 / 9.
- Không có `PROCTOR`, không có `ATTEMPT_CANCEL`.

Migration V3 chứa khối validation `DO $$ ... $$` kiểm tra các bất biến trên bằng `code`, không dùng numeric ID. Nếu lệch bất kỳ con số nào, migration sẽ fail.

Không được sửa V3 nữa.

### 6.10. Test configuration

`src/test/resources/application-test.yaml` đã được chuyển thành `application-test.properties` để nhất quán với runtime config (chi tiết ở mục 9).

---

## Day 3 — Identity Repository Layer, V4 username constraint, integration tests

### 6.11. Migration V4

File:

```text
backend/src/main/resources/db/migration/V4__add_username_format_constraint.sql
```

V4 thêm check constraint không cho username chứa ký tự `@`:

```sql
ALTER TABLE users
    ADD CONSTRAINT chk_users_username_no_at_sign
        CHECK (POSITION('@' IN username) = 0);
```

Sau V4, Flyway database version hiện là 4. Không được sửa V4 nữa.

### 6.12. Quyết định login identifier

Quyết định đã chốt:

- Nếu identifier chứa `@` → tra cứu theo email.
- Nếu identifier không chứa `@` → tra cứu theo username.

Vì username không bao giờ chứa `@`, hai identifier không bao giờ nhập nhằng tại lúc login. Application validation và database constraint (V4) cùng bảo vệ quy tắc username không chứa `@`.

### 6.13. Repository Layer

Sáu repository đã được tạo trong:

```text
backend/src/main/java/com/hhtuann/backend/identity/repository
```

```text
UserRepository
RoleRepository
PermissionRepository
UserRoleRepository
RolePermissionRepository
RefreshSessionRepository
```

Các query đã triển khai:

- `UserRepository`: tra cứu username không phân biệt hoa thường; tra cứu email không phân biệt hoa thường; kiểm tra username tồn tại không phân biệt hoa thường; kiểm tra email tồn tại không phân biệt hoa thường.
- `RoleRepository`: tra cứu role bằng `code`, phân biệt hoa thường.
- `PermissionRepository`: tra cứu permission bằng `code`, phân biệt hoa thường.
- `UserRoleRepository`: trả trực tiếp code của các role còn hiệu lực tại thời điểm `now` do application truyền vào.
  - Role có `expiresAt` null được coi là hiệu lực vô thời hạn.
  - Role có `expiresAt` lớn hơn `now` được coi là còn hiệu lực.
  - Role có `expiresAt` nhỏ hơn hoặc bằng `now` bị coi là hết hiệu lực.
- `RolePermissionRepository`: trả trực tiếp các permission code hiệu lực của user. Query permission dùng `distinct` để loại permission trùng giữa nhiều role.
- `RefreshSessionRepository`:
  - Tìm session theo token hash và fetch luôn user (`join fetch`).
  - Lookup refresh session không loại session đã revoke hoặc hết hạn, vì service phải tự đánh giá reuse và validity.
  - Bulk revoke các session chưa revoke theo user ID (dùng cho logout all).
  - Bulk revoke các session chưa revoke theo family ID (dùng cho token reuse detection).
  - Bulk revoke không lọc `expiresAt`.
  - Bulk revoke cập nhật `revokedAt` và `revokeReason` cùng lúc.

Lưu ý: chưa có query danh sách active refresh session. Query đó chưa được tạo trong Day 3.

Trong Day 4, `RefreshSessionRepository` được mở rộng thêm method `findForUpdateByTokenHashWithUser(hash)` (`@Lock(PESSIMISTIC_WRITE)`, `@QueryHint lock.timeout=5000`, `join fetch user`) phục vụ refresh rotation an toàn dưới concurrency. Các method cũ của Day 3 được giữ nguyên.

---

## Day 4 — Authentication Backend (security primitives + authentication application & API)

### 6.14. Migration V5

File:

```text
backend/src/main/resources/db/migration/V5__add_encrypted_personal_data.sql
```

V5 thêm hai cột lưu dữ liệu cá nhân nhạy cảm dưới dạng AES-256-GCM ciphertext:

```sql
ALTER TABLE users
    ADD COLUMN phone_encrypted TEXT,
    ADD COLUMN national_id_encrypted TEXT,
    ADD CONSTRAINT chk_users_phone_encrypted_format
        CHECK (phone_encrypted IS NULL OR phone_encrypted LIKE 'v1:%'),
    ADD CONSTRAINT chk_users_national_id_encrypted_format
        CHECK (national_id_encrypted IS NULL OR national_id_encrypted LIKE 'v1:%');
```

Đặc điểm:

- Hai cột `phone_encrypted`, `national_id_encrypted` đều nullable (TEXT).
- Chỉ lưu ciphertext có prefix version `v1:`, không có cột plaintext.
- Không tạo index trên ciphertext (không thể tìm kiếm).
- Không có giá trị mặc định.
- CHECK constraint bắt buộc ciphertext phải đúng prefix `v1:` (cho phép NULL).
- Không sửa dữ liệu và migration V1–V4.

V5 đã được Flyway áp dụng thành công. Sau V5, Flyway database version hiện là 5. Không được sửa V5 nữa.

### 6.15. Security primitives (Batch 1)

Lớp nguyên thủy bảo mật làm nền cho authentication đã triển khai:

- Password hashing: Argon2id (không log password, không log hash).
- Mã hóa dữ liệu cá nhân nhạy cảm: AES-256-GCM cho `phone` và `nationalId`, chỉ lưu ciphertext có prefix `v1:` (12-byte nonce + 16-byte tag, min payload 28 byte).
- Access token JWT HS256, lifetime 15 phút, claims `sub, username, roles, token_version, jti, iss, aud, iat, exp`.
- Refresh token dạng opaque, 256-bit entropy, chỉ lưu SHA-256 hash (64 hex) trong database.
- Clock abstraction để test thời gian (`MutableClock`, `TestClockConfig` trong test).

### 6.16. Authentication application & API (Batch 2)

Đã triển khai đầy đủ năm endpoint authentication, chạy trên PostgreSQL 17 Testcontainers qua Docker.

Năm endpoint:

```text
POST /api/auth/register   — public — đăng ký STUDENT (mặc định) hoặc TEACHER (cần invite code)
POST /api/auth/login      — public — login theo username/email, set refresh cookie
POST /api/auth/refresh    — public (cookie) — refresh rotation + reuse detection
POST /api/auth/logout     — public (cookie) — revoke session hiện tại, idempotent, clear cookie
GET  /api/auth/me         — Bearer JWT — trả thông tin user hiện tại + roles + permissions
```

Các chức năng authentication đã hoàn thành:

- Đăng ký STUDENT (mặc định khi `accountType` null).
- Đăng ký TEACHER bằng invite code (so sánh constant-time bằng `MessageDigest.isEqual`).
- Login theo username hoặc email (dựa vào có/không có `@`, không phân biệt hoa thường), dummy Argon2 verify khi user thiếu để cân bằng timing.
- Mật khẩu băm bằng Argon2id.
- Dữ liệu cá nhân `phone` và `nationalId` mã hóa AES-256-GCM (chỉ lưu ciphertext).
- Account lockout 5 lần sai liên tiếp trong 15 phút (dùng `failed_login_attempts` + `locked_until`, không đổi `UserStatus`).
- JWT access token lifetime 15 phút (HS256).
- Refresh token dạng opaque, gửi qua HttpOnly cookie `quizopia_refresh` (SameSite=Lax, Path `/api/auth`).
- Refresh token rotation mỗi lần refresh, giữ `familyId` + `expiresAt` (không kéo dài family).
- Phát hiện refresh token reuse → revoke toàn bộ token family (`revokeUnrevokedByFamilyId`, reason `TOKEN_REUSE_DETECTED`).
- Logout phiên hiện tại (idempotent, luôn clear cookie).
- `GET /api/auth/me` trả roles + permissions (decrypt dữ liệu cá nhân chỉ cho chính chủ).
- JWT converter kiểm `token_version` và trạng thái ACTIVE mỗi request, build authorities `ROLE_<CODE>` + permission code nguyên bản.
- CORS allowlist (reject wildcard) + `OriginCheckFilter` cho refresh/logout (chạy trước `CorsFilter`).
- Error response thống nhất `ApiError` (timestamp, status, code, message, path, traceId) cho cả 4xx auth và fallback 500.
- Integration test trên PostgreSQL 17 Testcontainers.

SecurityFilterChain rules:

```text
permitAll    : POST /api/auth/{register,login,refresh,logout}; GET /actuator/health/**
authenticated: GET /api/auth/me
denyAll      : mọi request khác
```

Stateless; form-login, HTTP-Basic, OAuth-client tắt; CSRF tắt (stateless Bearer + HttpOnly+SameSite-Lax+Origin check bảo vệ cookie endpoints); resource-server JWT với converter tùy chỉnh.

### 6.17. Environment variables bắt buộc

Backend yêu cầu các biến môi trường sau. Giá trị secret thật KHÔNG được commit vào git và KHÔNG được ghi trong tài liệu này:

```text
QUIZOPIA_JWT_SECRET_BASE64            — base64 secret ký JWT HS256
QUIZOPIA_DATA_ENCRYPTION_KEY_BASE64   — base64 key AES-256-GCM mã hóa phone/nationalId
QUIZOPIA_TEACHER_INVITE_CODE          — invite code đăng ký TEACHER (docker-compose mặc định blank → fail-fast)
QUIZOPIA_ALLOWED_ORIGINS              — danh sách origin CORS allowlist
QUIZOPIA_COOKIE_SECURE                — cờ Secure cho refresh cookie (false ở dev, true ở production)
```

Không dùng `permitAll()` ngoài bốn endpoint auth public + health. Không để endpoint mới public ngoài ý muốn.

### 6.18. Kết quả kiểm thử cuối Day 4

```text
Tests run: 107, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

Phân bổ test (tích lũy Day 3 + Day 4):

```text
Day 3 repository (14)
Batch 1 security primitives (Argon2, SecureRefresh, Sha256, JwtAccessToken, AesGcm)
Batch 2 authentication (Register, Login, AccessTokenAndMe, Refresh, RefreshConcurrency,
                        Logout, OriginCors, ErrorContract, JwtAuthorities, CorsConfig)
+ context load + UserEncryptedPersonalData
```

Không xóa, không bỏ qua test cũ. Toàn bộ chạy qua `docker compose --profile test run --rm backend-test`.

### 6.19. Technical debt đã ghi nhận (KHÔNG phải blocker Day 4)

Các mục dưới đây đã được review và tài liệu hóa, KHÔNG chặn việc hoàn tất Day 4, sẽ xử lý theo thứ tự ưu tiên ở module sau:

- Frontend BẮT BUỘC dùng single-flight refresh (queue các refresh đồng thời, dùng kết quả của request đầu) để tránh nhiều refresh song song cùng cookie gây false-positive reuse → revoke toàn family.
- Lockout counter có lost-update khi nhiều login sai đồng thời (mỗi "batch" C request song song chỉ tăng 1). Cần atomic `UPDATE ... = failed_login_attempts + 1` hoặc pessimistic lock. Phải sửa trước khi tin dùng lockout làm biện pháp brute-force chính.
- Register duplicate race (2 request cùng username/email đồng thời) có thể trả 500 thay vì 409 do chưa catch `DataIntegrityViolationException`. Happy path vẫn trả 409 đúng.
- `@Transactional(noRollbackFor = AuthenticationException.class)` trên `RefreshService.refresh` đang rộng (áp cả method, không chỉ nhánh reuse). Đúng ở code hiện tại, nên thu hẹp (exception con riêng / `REQUIRES_NEW` / ném ngoài tx).
- `User-Agent` dài hơn giới hạn `user_agent VARCHAR(500)` không được truncate → có thể gây lỗi persistence 500 ở login và refresh. Cần truncate trong `ClientContext`.

Các mục trên KHÔNG được ghi là blocker Day 4.

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
phone_encrypted
national_id_encrypted
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
- `phone_encrypted`, `national_id_encrypted`: nullable TEXT, chỉ lưu AES-256-GCM ciphertext có prefix `v1:` (thêm ở V5), có CHECK constraint bắt buộc prefix `v1:` cho mọi giá trị không NULL

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

Role đã được seed tại V3, đúng 4 role:

```text
SYSTEM_ADMIN
ACADEMIC_ADMIN
TEACHER
STUDENT
```

Không còn role `PROCTOR`. Giáo viên tự giám sát ca thi bằng permission `EXAM_SESSION_MONITOR`.

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
- Permission catalog đã được seed tại V3: đúng 84 permission, không có `ATTEMPT_CANCEL`

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

Log xác nhận (sau Day 2 / V3):

- Flyway validate thành công 3 migration (V1, V2, V3)
- Hibernate EntityManagerFactory khởi tạo thành công
- `ddl-auto=validate` không báo mismatch
- Backend started

Điều này chứng minh entity mapping hiện tại khớp với V2 schema.

---

# 9. Test configuration

Các file liên quan:

```text
src/test/java/com/hhtuann/backend/QuizopiaBackendApplicationTests.java
src/test/resources/application-test.properties
src/test/java/com/hhtuann/backend/testsupport/PostgresTestContainerConfiguration.java
```

Lưu ý: file test config trước đây là `application-test.yaml`, đã được chuyển thành `application-test.properties` (commit `58950e9`).

## 9.1. Chuyển từ H2 sang PostgreSQL Testcontainers

Trong Day 3, H2 đã bị loại khỏi test configuration. Integration test giờ chạy trên PostgreSQL 17 thật thông qua Testcontainers:

- H2 đã bị loại khỏi test configuration.
- Test dùng PostgreSQL 17 thông qua Testcontainers.
- Spring Boot dùng `@ServiceConnection` để cung cấp JDBC và Flyway connection details.
- Flyway được bật trong test (`spring.flyway.enabled=true`).
- Hibernate dùng `ddl-auto=validate` trong test.
- Không sử dụng datasource URL tĩnh trong test.
- Flyway V1–V4 tạo schema thật trong container PostgreSQL test.

`PostgresTestContainerConfiguration` đăng ký container `postgres:17` làm bean; Spring quản lý lifecycle (start/stop). Không dùng `@DynamicPropertySource`, không tự set datasource URL.

## 9.2. Logging trong test

```text
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.orm.jdbc.bind=OFF
```

- SQL statement vẫn được log ở DEBUG.
- Bind parameter logging là OFF để không lộ token hash (RefreshSessionRepository test thao tác với `tokenHash`).

## 9.3. Dependency test

```text
Spring Boot 4.1.0 (spring-boot-starter-parent)
spring-boot-testcontainers (scope test)
testcontainers-postgresql (scope test)
commons-lang3 (scope test)
```

- Dự án dùng Spring Boot 4.1.0.
- Testcontainers được resolve ở version 2.0.5 qua Spring Boot parent (không khai báo version).
- `commons-lang3` được khai báo trực tiếp với scope test vì Testcontainers cần `org.apache.commons.lang3.exception.ExceptionUtils` tại runtime nhưng dependency tree ban đầu không cung cấp class này.

## 9.4. Chạy test qua Docker Compose

Docker Compose có service `backend-test` thuộc profile `test`. Service chạy Maven trong container và sử dụng Docker socket để Testcontainers tạo PostgreSQL container.

Lệnh chạy toàn bộ test:

```text
docker compose --profile test run --rm backend-test
```

## 9.5. Kết quả kiểm thử cuối Day 3

```text
Tests run: 14, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

Phân bổ test:

```text
1 application context test
2 UserRepository integration test
2 RoleRepository integration test
2 PermissionRepository integration test
2 UserRoleRepository integration test
2 RolePermissionRepository integration test
3 RefreshSessionRepository integration test
```

Toàn bộ integration test chạy trên PostgreSQL Testcontainers thật, dùng dữ liệu role/permission do Flyway V3 seed.

## 9.6. Kết quả kiểm thử cuối Day 4 (tích lũy authentication)

Sau Day 4, toàn bộ test suite vẫn chạy trên PostgreSQL 17 Testcontainers:

```text
Tests run: 107, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

Test Day 4 bổ sung các lớp: Argon2 password hashing, secure refresh token generation, SHA-256 refresh token hashing, JWT access token, AES-256-GCM encryption, register, login, access token + `/me`, refresh rotation + reuse detection, refresh concurrency, logout, origin/CORS, error contract, JWT authorities, CORS config. Không xóa và không bỏ qua test Day 3.

---

# 10. Git checkpoint hiện tại

## 10.1. Backend commit

Day 4 backend checkpoint (HEAD):

```text
d4b7fb5 feat(auth): complete authentication application and API
```

Các commit trước trong lịch sử backend:

```text
0f83e2f feat(identity): add repository layer and integration tests   (Day 3)
173bac6 feat(identity): seed roles and permissions                  (Day 2 / V3)
```

Remote state:

```text
backend/main == origin/main
```

Backend commit `d4b7fb5` đã được push lên remote `https://github.com/hhtuann/Quizopia_Backend.git`. Backend branch `main` đồng bộ với `origin/main` tại checkpoint kết thúc Day 4 (working tree sạch sau checkpoint).

## 10.2. Root commit

Day 4 implementation checkpoint:

```text
ab0c195 chore(auth): finalize authentication backend checkpoint
```

Root commit `ab0c195` đã commit các thay đổi Day 4 sau:

```text
backend submodule pointer (trỏ tới backend commit d4b7fb5)
docker-compose.yml (invite code blank → fail-fast)
```

Checkpoint trước (Day 3):

```text
7d2b663 chore(project): finalize day 3 repository layer
```

Remote state tại thời điểm checkpoint Day 4:

```text
main == origin/main
```

Backend `d4b7fb5` và root `ab0c195` đều đã push và đồng bộ `origin/main`. Lưu ý: tài liệu Day 4 handoff này được cập nhật ở commit riêng nằm *sau* `ab0c195`, nên root HEAD hiện tại có thể mới hơn `ab0c195`. `ab0c195` vẫn là mốc implementation Day 4 cố định.

## 10.3. Local changes chưa commit

Sau checkpoint Day 4 (`ab0c195`), `backend` submodule pointer và `docker-compose.yml` đã được commit. Backend working tree sạch. Các mục sau có thể vẫn tồn tại local ở root và nằm ngoài phạm vi Day 4:

```text
 M .gitignore
 m frontend
?? .vscode/
?? agent-engineer-main/
```

Ý nghĩa:

- `.gitignore` có thay đổi local chưa commit (bảo vệ `.env`).
- `frontend` (submodule) có thay đổi local chưa commit.
- `.vscode/` chưa tracked.
- `agent-engineer-main/` chưa tracked.
- `.claude/` bị `.gitignore` loại trừ nên không xuất hiện trong `git status`.

Không được stage hoặc commit các mục ngoài phạm vi sau nếu chưa có yêu cầu riêng:

```text
.claude
.gitignore
.vscode
agent-engineer-main
frontend local changes
```

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

# 12. Trạng thái hiện tại (Day 4 hoàn tất)

Đã hoàn thành (tích lũy Day 1 → Day 4):

- Docker Compose foundation
- Backend Dockerfile
- PostgreSQL connection
- Redis connection
- Actuator health
- Flyway integration
- V1 metadata migration
- V2 identity schema
- Identity JPA entities (9 file)
- Hibernate schema validation
- Permission catalog và role-permission matrix đã chốt tại `docs/security.md`
- V3 seed roles & permissions đã áp dụng và kiểm chứng trực tiếp trong PostgreSQL
- V4 thêm username no-`@` constraint
- Identity Repository Layer (6 repository) đã hoàn thành
- V5 thêm cột mã hóa AES-256-GCM cho phone/nationalId
- Security primitives: Argon2id, AES-256-GCM, JWT HS256, opaque refresh token, Clock
- Authentication backend: 5 endpoint (`register`, `login`, `refresh`, `logout`, `me`)
- CORS allowlist + Origin check, error contract thống nhất, JWT authorities (role + permission)
- Integration test chạy trên PostgreSQL 17 Testcontainers
- 107 test, 0 failure, 0 error, 0 skipped, BUILD SUCCESS
- Backend đã commit (`d4b7fb5`) và push lên remote, đồng bộ `origin/main`
- Root đã commit (`ab0c195`) và push lên remote, đồng bộ `origin/main`

Flyway database hiện ở version 5. V1, V2, V3, V4, V5 đều đã áp dụng và không được sửa nữa.

Bước tiếp theo là Day 5 — Question Bank và Excel Import (chưa triển khai).

---

# 13. Kế hoạch tiếp theo (từ Day 3)

Phần dưới là kế hoạch đề xuất để tiếp tục theo đúng kiến trúc hiện tại. Các bước phải được thực hiện tuần tự và kiểm chứng sau mỗi phần.

## Phase 3 — Seed roles và permissions (ĐÃ HOÀN THÀNH)

Đã hoàn thành trong Day 2:

- Migration `V3__seed_roles_and_permissions.sql` đã áp dụng (mục 6.9).
- Đúng 4 role (không `PROCTOR`), đúng 84 permission (không `ATTEMPT_CANCEL`).
- Mapping 13 / 51 / 46 / 9 (tổng 119).
- Flyway database version sau V3 là 3 (sau Day 3, V4 nâng lên 4).
- V3 có khối validation `DO $$ ... $$` kiểm tra các bất biến bằng `code`.

Không sửa lại V3.

## Day 3 — Identity Repository Layer (ĐÃ HOÀN THÀNH)

Đã hoàn thành trong Day 3 (chi tiết ở mục 6.11–6.13 và mục 9):

- Migration `V4__add_username_format_constraint.sql` đã áp dụng (mục 6.11). Flyway database version hiện là 4.
- Quyết định login identifier đã chốt: có `@` → email, không `@` → username (mục 6.12).
- 6 repository đã tạo: `UserRepository`, `RoleRepository`, `PermissionRepository`, `UserRoleRepository`, `RolePermissionRepository`, `RefreshSessionRepository`.
- Integration test chạy trên PostgreSQL 17 Testcontainers. 14 test, 0 failure, 0 error, 0 skipped, BUILD SUCCESS.

Không sửa lại V1/V2/V3/V4.

## Day 4 — Authentication Backend (ĐÃ HOÀN THÀNH)

Đã hoàn thành trong Day 4 (chi tiết ở mục 6.14–6.19):

- V5 mã hóa dữ liệu cá nhân AES-256-GCM.
- Security primitives: Argon2id, AES-256-GCM, JWT HS256, opaque refresh token, Clock.
- Năm endpoint authentication: `POST /api/auth/register|login|refresh|logout`, `GET /api/auth/me`.
- Lockout 5 lần / 15 phút; access token JWT 15 phút; refresh token opaque qua cookie.
- Refresh rotation + reuse detection revoke family.
- CORS allowlist + Origin check; error contract `ApiError` thống nhất; JWT authorities (role + permission).
- 107 test, 0 failure / 0 error / 0 skipped, BUILD SUCCESS trên PostgreSQL 17 Testcontainers.

Các giá trị đã chốt trong Day 4:

```text
Password hashing       : Argon2id
Sensitive data         : AES-256-GCM (phone, nationalId), prefix v1:
Access token           : JWT HS256, 15 phút
Refresh token          : opaque, 256-bit, chỉ lưu SHA-256 hash, HttpOnly cookie
Lockout                : 5 lần sai liên tiếp trong 15 phút
Clock                  : Clock abstraction (MutableClock trong test)
```

Technical debt đã ghi nhận (KHÔNG phải blocker Day 4) nằm ở mục 6.19. Các Phase 5–9 dưới đây đã được triển khai trong Day 4; nội dung được giữ làm tham chiếu thiết kế.

## Phase 5 — Security primitives (ĐÃ HOÀN THÀNH trong Day 4)

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

## Phase 6 — Authentication use cases (ĐÃ HOÀN THÀNH trong Day 4)

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

## Phase 7 — Spring Security integration (ĐÃ HOÀN THÀNH trong Day 4)

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
- TEACHER chỉ được monitor session thuộc sở hữu/assignment hợp lệ (qua `EXAM_SESSION_MONITOR`); không còn role `PROCTOR`.
- STUDENT chỉ được thi exam mà mình được enroll và trong thời gian cho phép.
- SYSTEM_ADMIN không tự động được sửa nội dung học thuật nếu không có permission tương ứng.

## Phase 8 — API error model (ĐÃ HOÀN THÀNH trong Day 4 — `ApiError`)

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

## Phase 9 — Tests bắt buộc (ĐÃ HOÀN THÀNH trong Day 4 — 107 test pass)

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

## Day 5 — Question Bank và Excel Import (KẾ HOẠCH tiếp theo, chưa triển khai)

Day 5 chưa được triển khai trong nhiệm vụ cập nhật tài liệu này. Yêu cầu chốt cho Day 5:

- Hỗ trợ đủ bốn loại câu hỏi:

```text
SINGLE_CHOICE
MULTIPLE_CHOICE
TRUE_FALSE_MATRIX
NUMERIC_FILL
```

- Excel import phải validate từng dòng và báo lỗi rõ theo dòng (row-level error reporting), không im lặng bỏ dòng sai.
- Bắt đầu Day 5 bằng review/chốt thiết kế schema question bank và định dạng Excel trước khi code, đúng nguyên tắc "một bước nhỏ mỗi lần".

Không bắt đầu implementation Day 5 trong nhiệm vụ cập nhật tài liệu này.

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

Đã khóa (đã áp dụng, không sửa):

```text
V1__initialize_database.sql
V2__create_identity_schema.sql
V3__seed_roles_and_permissions.sql
V4__add_username_format_constraint.sql
V5__add_encrypted_personal_data.sql
```

Flyway database hiện ở version 5.

Migration tiếp theo (nếu cần schema mới) phải là V6 trở đi, không sửa V1/V2/V3/V4/V5.

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

- Root đang ở commit `ab0c195` (Day 4 implementation checkpoint) hoặc commit mới hơn hợp lệ.
- Backend đang ở `d4b7fb5` (Day 4 backend checkpoint) hoặc commit mới hơn hợp lệ.
- Root `main` đồng bộ với `origin/main` tại checkpoint kết thúc Day 4.
- Không có thay đổi backend chưa rõ nguồn gốc (backend working tree nên sạch).
- Frontend vẫn có thể hiện `m frontend`.
- `.gitignore`, `.vscode/`, `agent-engineer-main/` có thể chưa commit; `.claude/` bị gitignore loại trừ nên không xuất hiện trong `git status`.
- Docker services ở trạng thái hợp lý.
- Flyway database hiện ở version 5.

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
- Không sửa V1, V2, V3, V4 hoặc V5.
- Day 4 Authentication Backend đã hoàn tất (107 test pass). Bước tiếp theo hiện tại là Day 5 — Question Bank và Excel Import (chưa triển khai). Bước đầu là review/chốt thiết kế schema và định dạng Excel, chưa code controller.
- Khi viết prompt cho coding agent, dùng @File.java để tôi tag file.
- Trước khi bắt đầu, hãy yêu cầu tôi kiểm tra Git status, branch và Docker state.
```

---

# 20. Điểm tiếp tục chính xác

Điểm tiếp theo:

```text
Day 5 — Question Bank và Excel Import
```

Day 5 chưa được triển khai. Day 4 Authentication Backend đã hoàn tất (107 test pass). Bước đầu Day 5 phải là review và chốt thiết kế (schema question bank + định dạng Excel) trước khi code.

Yêu cầu chốt cho Day 5:

```text
Hỗ trợ đủ bốn loại câu hỏi: SINGLE_CHOICE, MULTIPLE_CHOICE, TRUE_FALSE_MATRIX, NUMERIC_FILL
Excel import phải validate và báo lỗi từng dòng (row-level error reporting)
```

Trình tự đúng để bắt đầu Day 5:

1. Kiểm tra Git và Docker state.
2. Xác nhận Flyway đang ở version 5 (V1–V5 đã áp dụng).
3. Xác nhận 6 repository Day 3 + authentication backend Day 4 và 107 test đang pass.
4. Review và chốt thiết kế question bank schema + định dạng Excel với người dùng.
5. Chỉ sau khi chốt mới bắt đầu code.
6. Không bắt đầu Day 5 bằng việc tạo controller/API endpoint ngay.

Giữ nguyên các nguyên tắc authorization:

- Permission không đủ để quyết định toàn bộ quyền truy cập. Phải kết hợp ownership, assignment, school scope, participation, resource state và time.
- Deny by default.
- SYSTEM_ADMIN không tự động là academic superuser.
- Không thêm role `PROCTOR`.
- Không thêm permission `ATTEMPT_CANCEL`.

---

# 21. Những điều chưa được xác nhận

Không được tự giả định các nội dung sau nếu chưa đọc repository hiện tại:

- Refresh token lifetime chính xác (giá trị cụ thể)
- CORS origins production
- Production secret management
- Frontend local changes hiện có là gì

Đã được xác nhận qua Day 4 (kiểm chứng trong code nếu cần):

- API endpoint path cuối cùng: `POST /api/auth/{register,login,refresh,logout}` và `GET /api/auth/me`
- JWT library: Spring Security OAuth2 resource server, ký HS256
- Access token lifetime: 15 phút
- Lockout threshold: 5 lần sai liên tiếp
- Lockout duration: 15 phút
- Refresh token: opaque, gửi qua HttpOnly cookie `quizopia_refresh` (DB chỉ lưu hash)

Lưu ý: Danh sách permission code cuối cùng ĐÃ được xác nhận tại `docs/security.md` và seed tại V3 (4 role, 84 permission, mapping 13/51/46/9). Không tự ý thêm permission hoặc role ngoài catalog này.

Các quyết định còn lại phải được thảo luận hoặc kiểm tra trong code/docs trước khi triển khai.

---

# 22. Kết luận

Dự án đã hoàn thành nền tảng quan trọng nhất:

- Hạ tầng Docker
- PostgreSQL và Redis
- Flyway (hiện version 5)
- Identity schema (V2), V4 username no-`@` constraint, V5 mã hóa AES-256-GCM cho phone/nationalId
- JPA model (9 file)
- Permission catalog và role-permission matrix đã chốt (`docs/security.md`)
- V3 seed roles & permissions đã áp dụng và kiểm chứng trực tiếp trong PostgreSQL
- Identity Repository Layer (6 repository)
- Security primitives (Argon2id, AES-256-GCM, JWT HS256, opaque refresh token, Clock)
- Authentication backend: 5 endpoint + CORS + origin check + error contract thống nhất + JWT authorities
- Integration test trên PostgreSQL 17 Testcontainers (107 test, 0 failure)
- Validation giữa code và database
- Git checkpoint backend (`d4b7fb5`) và root (`ab0c195`) đều đã push và đồng bộ `origin/main`

Permission model đã được chốt đúng ở V3: 4 role, 84 permission, mapping 13/51/46/9, không `PROCTOR`, không `ATTEMPT_CANCEL`.

Bước tiếp theo là Day 5 — Question Bank và Excel Import, hỗ trợ đủ bốn loại câu hỏi (SINGLE_CHOICE, MULTIPLE_CHOICE, TRUE_FALSE_MATRIX, NUMERIC_FILL) và Excel import validate/báo lỗi từng dòng. Bắt đầu bằng review và chốt thiết kế, không bắt đầu bằng việc code controller.
