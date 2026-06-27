# ADR 001: Sử dụng Modular Monolith

## Trạng thái

Đã chấp nhận (Accepted) - 27/06/2026

## Bối cảnh

Quizopia là một hệ thống thi trực tuyến với các yêu cầu:
- Hỗ trợ hàng ngàn học sinh cùng lúc thi
- Xử lý lưu lượng cao trong mùa thi
- Đảm bảo tính nhất quán dữ liệu (bài thi, điểm số)
- Phát triển bởi một team nhỏ (2-3 người) trong 10 ngày
- Cần khả năng mở rộng sau này

## Quyết định

Chúng tôi chọn **Modular Monolith** thay vì Microservices.

### Định nghĩa

**Modular Monolith** là một ứng dụng单体 được tổ chức thành các module độc lập về mặt logic, nhưng chạy trong cùng một process.

### Cấu trúc

```
quizopia-backend/
├── src/main/java/com/hhtuann/backend/
│   ├── identity/           # Module quản lý người dùng
│   ├── authorization/      # Module phân quyền
│   ├── academic/           # Module học vụ
│   ├── content/            # Module nội dung
│   ├── question/           # Module câu hỏi
│   ├── exam/               # Module đề thi
│   ├── attempt/            # Module bài làm
│   ├── grading/            # Module chấm điểm
│   ├── monitoring/         # Module theo dõi
│   ├── reporting/          # Module báo cáo
│   ├── notification/       # Module thông báo
│   ├── audit/              # Module audit
│   └── shared/             # Shared kernel
│       ├── domain/
│       ├── exception/
│       └── util/
```

## Lý do chọn

### 1. Độ phức tạp ban đầu

| Yếu tố          | Modular Monolith | Microservices                      |
| --------------- | ---------------- | ---------------------------------- |
| Setup ban đầu   | Đơn giản         | Phức tạp (K8s, Service Mesh, etc.) |
| Network latency | ~0ms             | 10-100ms giữa services             |
| Debugging       | Dễ (một process) | Khó (distributed tracing)          |
| Deployment      | Một deploy       | Nhiều deploy coordination          |

**Thời gian phát triển 10 ngày**: Monolith giảm 80% thời gian setup.

### 2. Transaction Management

```java
// Monolith: Simple transaction
@Service
@Transactional
public class ExamSubmissionService {
    public void submitAttempt(SubmissionDto dto) {
        // Cả hai operations trong một transaction
        attempt.setStatus(SUBMITTED);
        attemptRepository.save(attempt);
        
        gradingService.grade(attempt);
        // Rollback tự động nếu lỗi
    }
}
```

```java
// Microservices: Distributed transaction (Saga pattern)
@Service
public class ExamSubmissionService {
    public void submitAttempt(SubmissionDto dto) {
        // Step 1: Call Attempt Service
        attemptService.submit(dto);
        
        // Step 2: Call Grading Service
        try {
            gradingService.grade(attempt.getId());
        } catch (Exception e) {
            // Compensating transaction
            attemptService.cancel(attempt.getId());
        }
    }
}
```

### 3. Team Size

Với 2-3 developers:
- **Monolith**: Mỗi người làm 3-4 modules, dễ coordination
- **Microservices**: Cần một người để làm infrastructure/devops

### 4. Scaling Requirements

Quizopia cần scale theo hướng dọc trước:
- Cpu scaling: Scale up server
- Database scaling: Connection pooling, read replicas
- Cache scaling: Redis cluster

Scale ngang (horizontal) chỉ cần khi vượt quá:
- ~10,000 concurrent users
- Hoặc cần scale từng module riêng biệt

### 5. Module Boundaries

Monolith không nghĩa là "spaghetti code". Chúng tôi áp dụng:

**Strict Module Boundaries**:
```java
// ❌ VI PHẠM: Module truy cập repository của module khác
@Service
public class ExamService {
    @Autowired
    private QuestionRepository questionRepository;  // ❌ KHÔNG ĐƯỢC
}

// ✅ ĐÚNG: Chỉ giao tiếp qua service layer
@Service
public class ExamService {
    @Autowired
    private QuestionService questionService;  // ✅ ĐƯỢC PHÉP
}
```

**Enforced by Architecture Tests**:
```java
@ArchTest
static final ArchRule module_boundary_rule = noClasses()
    .that().resideInAPackage("..exam..")
    .should().dependOnClassesThat()
    .resideInAnyPackage("..question..repository..");
```

## Hệ quả

### Tích cực

1. **Nhanh lên production**: Deploy một JAR file duy nhất
2. **Dễ debugging**: Logs trong một place, không cần distributed tracing
3. **Dễ testing**: Integration tests đơn giản hơn
4. **Nhanh hơn trong 10 ngày**: Ít overhead hơn 80%

### Tiêu cực

1. **Coupling cao hơn**: Modules chạy cùng process
2. **Scaling hạn chế**: Cần scale toàn bộ application
3. **Technology lock-in**: Không thể mix Java + Node.js + Go

### Giải pháp cho tiêu cực

1. **Coupling cao**: Enforce module boundaries qua tests
2. **Scaling hạn chế**: Scale theo hướng dọc trước, horizontal sau
3. **Technology lock-in**: Chấp nhận vì team chỉ dùng Java

## Khi nào chuyển sang Microservices?

Chuyển khi CẢ HAI điều kiện sau được đáp ứng:

1. **Team size > 10 developers**
   - Monolith trở thành bottleneck cho development speed

2. **Scaling requirements cần tách biệt**
   - Một module cần 20 servers
   - Modules khác chỉ cần 2 servers
   - Cost inefficiency quá lớn

3. **Clear bounded contexts**
   - Modules có clear ownership
   - ít interactions giữa modules

**Quizopia hiện tại**: Không đáp ứng bất kỳ điều kiện nào.

## Lộ trình

### Ngày 1-10 (Vibe Coding)
- Xây modular monolith
- Enforce module boundaries via tests
- Prepare for future split ( nếu cần)

### Sau 10 ngày
- Monitor performance
- Nếu cần scale: scale dọc
- Nếu team lớn: cân nhắc split modules

### Nếu split
1. Bắt đầu với modules ít dependencies:
   - `notification` (independent)
   - `reporting` (read-only)
2. Dùng shared database ban đầu
3. Migrate đến database-per-service sau

## Tham khảo

- [Modular Monolith: How to Work with It and Not Lose Your Mind](https://blog.devgenius.io/modular-monolith-architecture-basics-for-spring-boot-applications-8c728bb0f1e7)
- [Monolith vs Microservices: A Comprehensive Guide](https://www.kafka-summit.org/en/2024/keynote/microservices-versus-modular-monolith-building-a-scalable-and-maintainable-architecture/)
- [Spring Boot Modular Monolith](https://spring.io/blog/2023/06/09/spring-boot-modular-monolith-architecture)

## Kết luận

Modular Monolith là lựa chọn phù hợp nhất cho Quizopia ở giai đoạn này:
- Phù hợp với team size nhỏ
- Đảm bảo delivery trong 10 ngày
- Giữ lại khả năng mở rộng sau này
- Giảm độ phức tạp của distributed system
