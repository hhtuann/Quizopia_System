# Quizopia System — Project Handoff & Continuity Guide

> Mục đích của tài liệu này là giúp một phiên ChatGPT khác, một tài khoản khác, hoặc một thành viên mới có thể tiếp tục dự án Quizopia đúng luồng, không làm sai kiến trúc, không sửa nhầm migration đã áp dụng, và không phá vỡ cấu trúc Git submodule.
>
> Cập nhật lần cuối: 2026-06-30  
> Trạng thái hiện tại: Hoàn tất Day 3 — Identity Repository Layer (Database đang ở Flyway version 4)

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
https://github.com/hhtuann/Quizopia-System.git
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

---

# 10. Git checkpoint hiện tại

## 10.1. Backend commit

Commit hiện tại (HEAD):

```text
0f83e2f feat(identity): add repository layer and integration tests
```

Commit V3 trong lịch sử backend:

```text
173bac6 feat(identity): seed roles and permissions
```

Remote state:

```text
backend/main == origin/main
```

Backend commit `0f83e2f` đã được push lên remote mới `https://github.com/hhtuann/Quizopia_Backend.git`.

## 10.2. Root commit

Commit hiện tại (HEAD):

```text
77da2fb docs: update project handoff for day 3
```

Root chưa commit các thay đổi Day 3 tại thời điểm cập nhật tài liệu này. Root repository đang chuẩn bị commit các thay đổi sau:

```text
backend submodule pointer (trỏ tới 0f83e2f)
docker-compose.yml
.gitmodules
QUIZOPIA_PROJECT_HANDOFF.md
```

Không tự bịa ra một root commit mới khi chưa thực sự commit.

## 10.3. Local changes chưa commit

Root repository đang chứa các thay đổi Day 3 chưa commit (xem 10.2) ngoài các mục sau vốn nằm ngoài phạm vi:

```text
 m frontend
?? .claude/
?? .gitignore
?? .vscode/
```

Ý nghĩa:

- `frontend` có thay đổi local chưa commit.
- `.claude/` chưa tracked.
- `.gitignore` chưa tracked.
- `.vscode/` chưa tracked.

Không được stage hoặc commit các mục ngoài phạm vi sau nếu chưa có yêu cầu riêng:

```text
.claude
.gitignore
.vscode
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

# 12. Trạng thái hiện tại (Day 3 hoàn tất)

Đã hoàn thành (tích lũy Day 1 → Day 3):

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
- Integration test chạy trên PostgreSQL 17 Testcontainers
- 14 test, 0 failure, 0 error, 0 skipped, BUILD SUCCESS
- Backend đã commit (`0f83e2f`) và push lên remote mới

Flyway database hiện ở version 4. V1, V2, V3, V4 đều đã áp dụng và không được sửa nữa.

Bước tiếp theo là Day 4 — Security Primitives (chưa triển khai).

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

## Day 4 — Security Primitives (KẾ HOẠCH, chưa triển khai)

Day 4 chưa được triển khai. Bước đầu Day 4 phải là review và chốt thiết kế trước khi code. Không tạo controller hoặc authentication endpoint ngay ở bước đầu Day 4.

Các chủ đề cần lần lượt thảo luận (theo thứ tự):

```text
PasswordHasher abstraction
Argon2id configuration
Opaque refresh token generation
Refresh token hashing
Access token JWT claims
JWT signing key strategy cho development và production
Access token lifetime
Refresh token lifetime
Lockout threshold
Lockout duration
Clock abstraction để test thời gian
```

Không tự quyết định các giá trị lifetime, lockout hoặc secret strategy nếu người dùng chưa chốt.

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
- TEACHER chỉ được monitor session thuộc sở hữu/assignment hợp lệ (qua `EXAM_SESSION_MONITOR`); không còn role `PROCTOR`.
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

Đã khóa (đã áp dụng, không sửa):

```text
V1__initialize_database.sql
V2__create_identity_schema.sql
V3__seed_roles_and_permissions.sql
V4__add_username_format_constraint.sql
```

Flyway database hiện ở version 4.

Migration tiếp theo (nếu cần schema mới) phải là V5 trở đi, không sửa V1/V2/V3/V4.

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

- Root đang ở commit `77da2fb`, với các thay đổi Day 3 (backend submodule pointer, `docker-compose.yml`, `.gitmodules`, `QUIZOPIA_PROJECT_HANDOFF.md`) có thể chưa commit.
- Backend đang ở `0f83e2f` hoặc commit mới hơn hợp lệ.
- Không có thay đổi backend chưa rõ nguồn gốc.
- Frontend vẫn có thể hiện `m frontend`.
- `.claude/`, `.gitignore` và `.vscode/` vẫn có thể untracked.
- Docker services ở trạng thái hợp lý.
- Flyway database hiện ở version 4.

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
- Không sửa V1, V2, V3 hoặc V4.
- Bước tiếp theo hiện tại là Day 4 — Security Primitives (chưa triển khai). Bước đầu là review và chốt thiết kế, không code controller.
- Khi viết prompt cho coding agent, dùng @File.java để tôi tag file.
- Trước khi bắt đầu, hãy yêu cầu tôi kiểm tra Git status, branch và Docker state.
```

---

# 20. Điểm tiếp tục chính xác

Điểm tiếp theo:

```text
Day 4 — Security Primitives
```

Day 4 chưa được triển khai. Bước đầu Day 4 phải là review và chốt thiết kế trước khi code. Không tạo controller hoặc authentication endpoint ngay ở bước đầu Day 4.

Các chủ đề cần lần lượt thảo luận trước khi code:

```text
PasswordHasher abstraction
Argon2id configuration
Opaque refresh token generation
Refresh token hashing
Access token JWT claims
JWT signing key strategy cho development và production
Access token lifetime
Refresh token lifetime
Lockout threshold
Lockout duration
Clock abstraction để test thời gian
```

Không tự quyết định các giá trị lifetime, lockout hoặc secret strategy nếu người dùng chưa chốt.

Trình tự đúng để bắt đầu Day 4:

1. Kiểm tra Git và Docker state.
2. Xác nhận Flyway đang ở version 4 (V1–V4 đã áp dụng).
3. Xác nhận 6 repository Day 3 và 14 test đang pass.
4. Review và chốt thiết kế security primitives với người dùng theo danh sách chủ đề trên.
5. Chỉ sau khi chốt mới bắt đầu code (PasswordHasher, token generation, hashing, clock...).
6. Không bắt đầu Day 4 bằng việc tạo controller hoặc authentication endpoint.

Giữ nguyên các nguyên tắc authorization:

- Permission không đủ để quyết định toàn bộ quyền truy cập. Phải kết hợp ownership, assignment, school scope, participation, resource state và time.
- Deny by default.
- SYSTEM_ADMIN không tự động là academic superuser.
- Không thêm role `PROCTOR`.
- Không thêm permission `ATTEMPT_CANCEL`.

---

# 21. Những điều chưa được xác nhận

Không được tự giả định các nội dung sau nếu chưa đọc repository hiện tại:

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

Lưu ý: Danh sách permission code cuối cùng ĐÃ được xác nhận tại `docs/security.md` và seed tại V3 (4 role, 84 permission, mapping 13/51/46/9). Không tự ý thêm permission hoặc role ngoài catalog này.

Các quyết định còn lại phải được thảo luận hoặc kiểm tra trong code/docs trước khi triển khai.

---

# 22. Kết luận

Dự án đã hoàn thành nền tảng quan trọng nhất:

- Hạ tầng Docker
- PostgreSQL và Redis
- Flyway (hiện version 4)
- Identity schema (V2) và V4 username no-`@` constraint
- JPA model (9 file)
- Permission catalog và role-permission matrix đã chốt (`docs/security.md`)
- V3 seed roles & permissions đã áp dụng và kiểm chứng trực tiếp trong PostgreSQL
- Identity Repository Layer (6 repository)
- Integration test trên PostgreSQL 17 Testcontainers (14 test, 0 failure)
- Validation giữa code và database
- Git checkpoint backend đã push lên remote mới; root đang chứa thay đổi Day 3 chưa commit

Permission model đã được chốt đúng ở V3: 4 role, 84 permission, mapping 13/51/46/9, không `PROCTOR`, không `ATTEMPT_CANCEL`.

Bước tiếp theo là Day 4 — Security Primitives, bắt đầu bằng review và chốt thiết kế (PasswordHasher, Argon2id, token generation/hashing, JWT claims, signing key, lifetime, lockout, clock), không bắt đầu bằng việc code controller.
