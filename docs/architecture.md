# Kiến trúc Hệ thống Quizopia

## 1. Tổng quan

Quizopia là hệ thống thi trực tuyến dựa trên kiến trúc **Modular Monolith**, được thiết kế để:
- Dễ bảo trì và mở rộng
- Tách biệt rõ ràng giữa các module nghiệp vụ
- Giảm thiểu độ phức tạp của distributed system
- Giữ khả năng scale theo hướng dọc (vertical scaling)

## 2. Kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend Layer                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │          Next.js 16 (React 19, TypeScript, Tailwind)      │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │  │
│  │  │   Auth UI    │  │   Exam UI    │  │  Admin UI    │     │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │ HTTP/WebSocket
                              ▼
┌─────────────────────────────────────────────────────────────────-----┐
│                         Backend Layer                                │
│  ┌───────────────────────────────────────────────────────────----─┐  |
│  │         Spring Boot 4.1 (Java 21) - Modular Monolith           │  │
│  │                                                                │  │ 
│  │  ┌───────────-┐ ┌──────────-─┐ ┌───────────-┐ ┌─────────-──┐   │  │
│  │  │  Identity  │ │   Content  │ │    Exam    │ │   Attempt  │   │  │
│  │  └──────────-─┘ └──────────-─┘ └───────────-┘ └──────────-─┘   │  │
│  │                                                                │  │
│  │  ┌───────-────┐ ┌───────────-┐ ┌─────────-──┐ ┌──────────-─┐   │  │
│  │  │    Auth    │ │  Question  │ │   Grading  │ │ Monitoring │   │  │
│  │  └────────-───┘ └──────────-─┘ └──────────-─┘ └───────────-┘   │  │
│  │                                                                │  │
│  │  ┌────────-───┐ ┌───────-────┐ ┌───────────-┐ ┌─────────-──┐   │  │
│  │  │ Reporting  │ │  Academic  │ │Notification│ |   Audit    │   │  │
│  │  └────────-───┘ └─────────-──┘ └───────────-┘ └─────────-──┘   │  │
│  │                                                                │  │
│  │  ┌────────────────────────────────────────────────────----─-┐  │  │
│  │  │                    Shared Kernel                         │  │  │
│  │  │  (Common types, utilities, domain primitives)            │  │  │
│  │  └─────────────────────────────────────────────────────-----┘  │  │
│  └───────────────────────────────────────────────────────────----─┘  │
└───────────────────────────────────────────────────────────────-----──┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  PostgreSQL   │    │     Redis     │    │     MinIO     │
│  (Primary DB) │    │   (Cache)     │    │  (Storage)    │
└───────────────┘    └───────────────┘    └───────────────┘
```

## 3. Backend - Modular Monolith Structure

### 3.1 Package Structure

```
com.hhtuann.backend
├── identity/              # Quản lý người dùng, thông tin cá nhân
│   ├── user/
│   │   ├── model/
│   │   ├── repository/
│   │   └── service/
│   └── role/
│       ├── model/
│       ├── repository/
│       └── service/
│
├── authorization/         # Quản lý phân quyền, permission
│   ├── model/
│   ├── repository/
│   └── service/
│
├── academic/             # Quản lý học kỳ, khóa học
│   ├── semester/
│   └── course/
│
├── content/              # Quản lý nội dung tài liệu học tập
│   └── material/
│
├── question/             # Quản lý câu hỏi thi
│   ├── model/
│   ├── repository/
│   └── service/
│
├── exam/                 # Quản lý đề thi
│   ├── model/
│   ├── repository/
│   └── service/
│
├── attempt/              # Quản lý bài làm của học sinh
│   ├── model/
│   ├── repository/
│   └── service/
│
├── grading/              # Tự động chấm điểm
│   └── service/
│
├── monitoring/           # Theo dõi trạng thái thi
│   └── service/
│
├── reporting/            # Thống kê, báo cáo
│   └── service/
│
├── notification/         # Gửi thông báo
│   └── service/
│
├── audit/               # Audit log
│   └── service/
│
└── shared/              # Shared kernel
    ├── domain/
    ├── exception/
    └── util/
```

### 3.2 Module Boundaries

**Nguyên tắc:**
- Mỗi module có package riêng biệt
- Không truy cập trực tiếp repository của module khác
- Chỉ giao tiếp qua service layer
- Domain entities không leak ra bên ngoài module

**Ví dụ đúng:**
```java
// Module Attempt gọi Service của Module Question
questionService.getQuestionById(questionId);
```

**Ví dụ SAI:**
```java
// Module Attempt truy cập Repository của Module Question
questionRepository.findById(questionId); // ❌ VI PHẠM BOUNDARY
```

## 4. Frontend Architecture

### 4.1 Component Structure

```
src/
├── app/                   # Next.js App Router
│   ├── (auth)/           # Auth routes
│   ├── (exam)/           # Exam routes
│   ├── (admin)/          # Admin routes
│   └── api/              # API routes (BFF pattern)
│
├── components/           # UI Components
│   ├── ui/              # Reusable UI components
│   ├── auth/            # Auth-specific components
│   ├── exam/            # Exam-specific components
│   └── admin/           # Admin-specific components
│
├── features/            # Feature modules
│   ├── auth/
│   ├── exam/
│   ├── question/
│   └── monitoring/
│
├── lib/                 # Utilities
│   ├── api/
│   ├── hooks/
│   └── utils/
│
└── stores/              # Zustand state management
```

### 4.2 State Management

- **Server State**: TanStack Query (React Query) - cache, sync với server
- **Client State**: Zustand - local UI state, temporary form data
- **Form State**: React Hook Form với Zod validation

## 5. Communication Patterns

### 5.1 Frontend → Backend

**REST API:**
- CRUD operations
- File uploads
- Authentication flows

**WebSocket:**
- Real-time exam monitoring
- Live proctoring updates
- Exam status changes

### 5.2 Backend → External Services

| Service    | Purpose                          | Protocol |
| ---------- | -------------------------------- | -------- |
| PostgreSQL | Primary data store               | JDBC     |
| Redis      | Cache, session storage           | Lettuce  |
| MinIO      | File storage (images, documents) | S3 API   |
| Mailpit    | Email testing (dev only)         | SMTP     |

## 6. Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Security                        │
│  - HttpOnly cookies for tokens                              │
│  - CSRF protection                                          │
│  - Input validation (Zod)                                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Spring Security Filter Chain              │
│  ┌─────────────────────────────────────────────────────-─┐  │
│  │  1. JWT Authentication Filter                         │  │
│  │  2. CSRF Filter                                       │  │
│  │  3. CORS Filter                                       │  │
│  │  4. Method Security (@PreAuthorize)                   │  │
│  │  5. Resource Access Control                           │  │
│  └─────────────────────────────────────────────────────-─┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer Security                    │
│  - Resource ownership validation                            │
│  - Business rule authorization                              │
│  - Audit logging                                            │
└─────────────────────────────────────────────────────────────┘
```

## 7. Transaction Boundaries

**Nguyên tắc:**
- Transaction bắt đầu ở Service layer
- Một service method = một transaction
- Không gọi service khác trong transaction (để tránh distributed transaction)

**Ví dụ:**
```java
@Service
@Transactional
public class ExamSubmissionService {
    // Transaction bắt đầu ở đây
    public void submitAttempt(AttemptSubmissionDto dto) {
        // Chỉ thao tác trên entities của module Attempt
        // KHÔNG gọi service của module khác
    }
}
```

## 8. Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose (Dev)                     │
│                                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Frontend │ │ Backend  │ │PostgreSQL│ │  Redis   │        │
│  │ :3000    │ │ :8080    │ │:5432     │ │  :6379   │        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
│                                                             │
│  ┌──────────┐ ┌──────────┐                                  │
│  │  MinIO   │ │ Mailpit  │                                  │
│  │  :9000   │ │ :8025    │                                  │
│  └──────────┘ └──────────┘                                  │
│                                                             │
│  Network: quizopia_network                                  │
└─────────────────────────────────────────────────────────────┘
```

## 9. Non-Functional Requirements

### 9.1 Performance
- API response < 200ms (p95)
- WebSocket latency < 100ms
- Page load < 2s

### 9.2 Reliability
- Idempotent submission (không trùng bài)
- Autosave answers (không mất dữ liệu)
- Graceful degradation khi Redis unavailable

### 9.3 Scalability
- Stateless application ( JWT, not session)
- Connection pooling cho DB
- Redis cache cho frequently accessed data

## 10. Technology Stack Summary

| Layer            | Technology                                 |
| ---------------- | ------------------------------------------ |
| Frontend         | Next.js 16, React 19, TypeScript, Tailwind |
| Backend          | Spring Boot 4.1, Java 21                   |
| Database         | PostgreSQL 17                              |
| Cache            | Redis 7.2                                  |
| Storage          | MinIO (S3-compatible)                      |
| Containerization | Docker, Docker Compose                     |
| Testing          | JUnit 5, Testcontainers, Playwright        |
