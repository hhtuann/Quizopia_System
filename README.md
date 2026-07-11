# Quizopia

Hệ thống quản lý học tập và thi trắc nghiệm trực tuyến — nền tảng end-to-end cho phép giáo viên tạo ngân hàng câu hỏi, dựng đề thi, lên lịch ca thi, giám sát học sinh làm bài real-time, chấm điểm tự động và xuất bảng điểm.

Xây dựng bằng **Next.js 16 + Spring Boot 4.1 (Java 21) + PostgreSQL 17 + Redis + MinIO**, chạy hoàn toàn trong Docker bằng một lệnh.

---

## Mục lục

- [Tính năng chính](#tính-năng-chính)
- [Tech stack](#tech-stack)
- [Kiến trúc](#kiến-trúc)
- [Cấu trúc repository](#cấu-trúc-repository)
- [Bắt đầu nhanh](#bắt-đầu-nhanh)
- [Tài khoản demo](#tài-khoản-demo)
- [Vai trò & phân quyền](#vai-trò--phân-quyền)
- [API & real-time](#api--real-time)
- [Bảo mật](#bảo-mật)
- [Kiểm thử](#kiểm-thử)

---

## Tính năng chính

- **4 vai trò** với phân quyền đa lớp: System Admin, Academic Admin, Teacher, Student (RBAC + ownership + state policy, mặc định từ chối, kiểm tra tại backend).
- **Ngân hàng câu hỏi**: 4 loại câu hỏi (single choice, multiple choice, true/false matrix, numeric fill), import từ Excel có preview + validate theo từng dòng.
- **Đề thi**: soạn thảo theo phiên bản, công bố snapshot (đề đã công bố không bị thay đổi khi sửa ngân hàng câu hỏi).
- **Ca thi**: lên lịch, tự động mở/đóng theo cửa sổ thời gian (lazy open/close), duration theo từng lượt làm, visibility `PUBLIC` (toàn trường) hoặc `CLASS_RESTRICTED` (theo lớp), gán lớp.
- **Làm bài**: autosave (flush đáp án ở giây cuối), nộp bài idempotent (Idempotency-Key), tự nộp khi hết giờ (client timer + server-side sweeper), deadline = `min(endsAt, startedAt + duration)`.
- **Giám sát real-time**: WebSocket STOMP, dashboard live (đang làm / đã nộp / mất kết nối), đồng bộ server time.
- **Chấm điểm tự động**: hỗ trợ partial credit cho câu nhiều đáp án, chấm ngay trong transaction nộp bài.
- **Thông báo**: 10 loại thông báo trong app, đẩy qua WebSocket + polling fallback, icon riêng theo loại.
- **Báo cáo**: thống kê ca thi (điểm trung bình, phân bố, tỷ lệ đạt, câu khó/dễ…), xuất Excel đa sheet có chống formula injection.
- **Onboarding học sinh**: học sinh tự đăng ký, academic admin duyệt và gán vào trường/lớp.

---

## Tech stack

**Backend** (`backend/` submodule)
- Spring Boot 4.1, Java 21
- Spring Security (JWT + HttpOnly refresh cookie), Spring Data JPA, Spring Data Redis
- WebSocket STOMP, Flyway (15 migrations), Apache POI (Excel), MapStruct
- Argon2id (mật khẩu), AES-256-GCM (PII), Testcontainers

**Frontend** (`frontend/` submodule)
- Next.js 16 (App Router, Turbopack), React 19, TypeScript
- Tailwind CSS v4, TanStack Query, React Hook Form, Zod, Zustand, @stomp/stompjs

**Infrastructure**
- PostgreSQL 17, Redis 7.2, MinIO (object storage), Mailpit (email dev)
- Docker Compose

---

## Kiến trúc

Backend là **modular monolith** — chia thành các module nghiệp vụ độc lập, giao tiếp qua application service / domain event, sẵn sàng tách thành microservice sau này.

```text
Browser
   │  HTTPS
   ▼
Next.js (frontend, :3000) ──REST──► Spring Boot (backend, :8080)
   │                                  │
   └──WebSocket /ws──────────────────►│  (STOMP: live monitor, notifications, server-time)
                                      │
              ┌───────────────────────┼───────────────────────┐
              ▼                       ▼                       ▼
        PostgreSQL 17            Redis 7.2                 MinIO
        (nguồn sự thật)        (cache, rate limit,         (file, media)
                                 presence)
```

Backend modules: `identity`, `authentication`, `security`, `user`, `academic`, `classroom`, `question`, `exam`, `attempt`, `grading`, `realtime`, `notification`, `common`.

---

## Cấu trúc repository

Repository gốc dùng **git submodules** cho backend và frontend:

```text
Quizopia_System/
├── backend/            # submodule → Quizopia_Backend (Spring Boot)
├── frontend/           # submodule → Quizopia_Frontend (Next.js)
├── .gitmodules         # submodule config
├── docker-compose.yml  # orchestration: postgres, redis, minio, mailpit, backend, frontend
├── .env.example        # template biến môi trường (copy → .env)
└── README.md
```

---

## Bắt đầu nhanh

### Yêu cầu

- Docker + Docker Compose
- Git

### Cài đặt

**1. Clone kèm submodules:**

```bash
git clone --recurse-submodules https://github.com/hhtuann/Quizopia_System.git
cd Quizopia_System
```

Nếu đã clone bình thường, khởi tạo submodules:

```bash
git submodule update --init --recursive
```

**2. Tạo file `.env` từ template:**

```bash
cp .env.example .env
```

Sinh các secret và điền vào `.env`:

```bash
openssl rand -base64 48   # → QUIZOPIA_JWT_SECRET_BASE64  (≥ 32 bytes)
openssl rand -base64 32   # → QUIZOPIA_DATA_ENCRYPTION_KEY_BASE64  (đúng 32 bytes)
```

Đặt `QUIZOPIA_TEACHER_INVITE_CODE` (mã mời để đăng ký tài khoản Teacher).
Muốn dùng tài khoản demo thì đặt `QUIZOPIA_DEMO_DATA_ENABLED=true`.

**3. Khởi chạy:**

```bash
docker compose up --build
```

Sau khi các service healthy:

| Dịch vụ | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8080 |
| MinIO console | http://localhost:9001 (minioadmin / minioadmin123) |
| Mailpit (email) | http://localhost:8025 |

> Backend fail-fast nếu `QUIZOPIA_JWT_SECRET_BASE64` hoặc `QUIZOPIA_DATA_ENCRYPTION_KEY_BASE64` để trống — phải sinh giá trị thật trong `.env`.

---

## Tài khoản demo

Khi `QUIZOPIA_DEMO_DATA_ENABLED=true`, backend seed các tài khoản sau (mật khẩu `Demo@12345`) lần khởi động đầu tiên:

| Username | Vai trò |
|----------|---------|
| `demo_sysadmin` | System Administrator |
| `demo_academic_admin` | Academic Administrator |
| `demo_teacher` | Teacher |
| `demo_student_01` – `demo_student_04` | Student |

Cùng với một lớp demo (gồm các học sinh trên làm thành viên).

**Đăng ký thủ công** (khi không dùng demo data):

- **Student**: tự đăng ký tại `/register`, sau đó academic admin duyệt qua trang *Pending Students* và gán vào trường.
- **Teacher**: đăng ký với invite code (`QUIZOPIA_TEACHER_INVITE_CODE`).
- **System Admin / Academic Admin**: chỉ tạo qua dữ liệu demo.

---

## Vai trò & phân quyền

| Vai trò | Trách nhiệm chính |
|---------|-------------------|
| **System Administrator** | Quản lý tài khoản & vai trò, cấu hình hệ thống, xem nhật ký bảo mật |
| **Academic Administrator** | Quản lý môn học, duyệt học sinh vào trường, gán giáo viên, xem báo cáo tổng hợp |
| **Teacher** | Ngân hàng câu hỏi (import Excel), tạo đề & ca thi, giám sát real-time, xem kết quả, xuất Excel |
| **Student** | Xem ca thi, làm bài (autosave), nộp bài, xem kết quả khi được công bố |

Phân quyền 3 lớp:

- **RBAC** — mỗi vai trò có tập quyền cơ bản (`QUESTION_CREATE`, `EXAM_PUBLISH`, `ATTEMPT_SUBMIT`, `RESULT_EXPORT`…).
- **Ownership / Relationship** — giáo viên chỉ sửa câu hỏi sở hữu; học sinh chỉ truy cập attempt của chính mình.
- **State / Attribute** — đề chỉ sửa khi `DRAFT`; học sinh chỉ bắt đầu bài trong cửa sổ thời gian; kết quả chỉ hiện khi đã được công bố.

> Frontend ẩn nút chỉ để cải thiện UX — mọi quyền được kiểm tra tại backend.

---

## API & real-time

- **Base path**: `/api`
- **Auth**: JWT access token (header `Authorization: Bearer …`) + refresh token (cookie `HttpOnly`, rotation + reuse detection).
- **Idempotency**: header `Idempotency-Key` cho nộp bài (retry không tạo kết quả trùng).
- **Real-time**: WebSocket STOMP tại `/ws` — giám sát ca thi, thông báo, đồng bộ server time. Backend không bao giờ broadcast countdown; frontend tự đếm dựa trên `serverTime` + `deadline`.
- **Convention**: JSON `camelCase`, timestamp ISO-8601 UTC, error code ổn định, phân trang thống nhất.

---

## Bảo mật

- **Mật khẩu**: Argon2id, mỗi mật khẩu có salt riêng.
- **PII** (CCCD, SĐT): AES-256-GCM, key được inject qua biến môi trường (không nằm trong DB hay source).
- **Token**: access token JWT ngắn hạn; refresh token opaque, hash trong DB, gửi qua cookie `HttpOnly` + `SameSite`, rotation sau mỗi lần dùng, phát hiện reuse → thu hồi cả family.
- **Không lộ đáp án**: API học sinh không bao giờ trả `correctAnswer`.
- **Default deny**: kiểm tra quyền + ownership + state tại backend cho mọi request; integration test cho từng cặp vai trò–endpoint.

---

## Kiểm thử

- **Backend**: unit test + integration test với Testcontainers (PostgreSQL, Redis thật).
- Chạy full suite trong Docker:

```bash
docker compose --profile test run --rm backend-test
```

---

## Ghi chú

- Repo dùng submodules — khi clone nhớ `--recurse-submodules`.
- `ddl-auto=validate` (Flyway sở hữu schema, không tự update).
- Backend container cần rebuild sau khi sửa code backend: `docker compose up -d --build backend`.
