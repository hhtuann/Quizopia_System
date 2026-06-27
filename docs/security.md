# Security Documentation - Quizopia

## 1. Tổng quan

Quizopia áp dụng nhiều lớp bảo mật để đảm bảo:
- Xác thực người dùng đúng đắn
- Phân quyền theo role
- Bảo vệ dữ liệu thi
- Ngăn chặn tấn công phổ biến

## 2. Authentication Flow

### 2.1 Login Flow

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Frontend  │         │   Backend   │         │  Database   │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │ POST /auth/login      │                       │
       │ {username, password}  │                       │
       ├──────────────────────>│                       │
       │                       │                       │
       │                       │ 1. Validate input     │
       │                       │ 2. Load User          │
       │                       ├──────────────────-─-─>│
       │                       │<────────────────-────-|
       │                       │                       │
       │                       │ 3. Verify password    │
       │                       │    (Argon2id)         │
       │                       │                       │
       │                       │ 4. Check account      │
       │                       │    status             │
       │                       │                       │
       │                       │ 5. Generate JWT       │
       │                       │    (15 minutes)       │
       │                       │                       │
       │                       │ 6. Create Refresh     │
       │                       │    Session            │
       │                       ├────────────────────-->│
       │                       │<──────────────────-──-┤
       │                       │                       │
       │ 7. Return Access Token│                       │
       │    + HttpOnly Cookie  │                       │
       │<──────────────────────┤                       │
       │                       │                       │
```

### 2.2 Token Storage

**Frontend:**
- **Access Token**: Memory only (không persist)
- **Refresh Token**: HttpOnly Cookie (không accessible qua JS)

**Backend:**
- **Refresh Token**: Hashed trong database

**Cấm:**
```javascript
// ❌ KHÔNG lưu JWT trong localStorage
localStorage.setItem('token', jwt); // Dễ bị XSS đánh cắp

// ❌ KHÔNG lưu token trong React state
const [token, setToken] = useState(jwt); // Lost khi refresh
```

**Đúng:**
```javascript
// ✅ Access token chỉ trong memory
let accessToken = null;

// ✅ Refresh token trong HttpOnly cookie
// (Server tự động gửi, JS không thể truy cập)
```

## 3. Authorization

### 3.1 Role Hierarchy

```
SYSTEM_ADMIN (cao nhất)
    |
    ├── ACADEMIC_ADMIN
    │
    ├── TEACHER
    │
    ├── PROCTOR
    │
    └── STUDENT (thấp nhất)
```

### 3.2 Permission Matrix

| Resource            | SYSTEM_ADMIN | ACADEMIC_ADMIN | TEACHER     | PROCTOR | STUDENT |
| ------------------- | ------------ | -------------- | ----------- | ------- | ------- |
| User management     | ✅            | ✅              | ❌           | ❌       | ❌       |
| Course management   | ✅            | ✅              | Own only    | ❌       | ❌       |
| Question management | ✅            | ✅              | Own only    | ❌       | ❌       |
| Exam creation       | ✅            | ✅              | Own courses | ❌       | ❌       |
| Exam taking         | ❌            | ❌              | ❌           | ❌       | ✅       |
| Grading             | ✅            | ✅              | Own exams   | ❌       | ❌       |
| Monitoring          | ✅            | ✅              | Own exams   | ✅       | ❌       |

### 3.3 Method-Level Authorization

```java
@Service
public class ExamService {
    
    // Chỉ TEACHER mới được tạo exam
    @PreAuthorize("hasRole('TEACHER')")
    public Exam createExam(CreateExamDto dto) { ... }
    
    // TEACHER chỉ xem exam của course mình
    @PreAuthorize("hasRole('TEACHER') AND @examSecurity.isOwner(#examId, authentication)")
    public Exam getExam(Long examId) { ... }
    
    // STUDENT chỉ làm exam trong course mình
    @PreAuthorize("hasRole('STUDENT') AND @examSecurity.canAttempt(#examId, authentication)")
    public void startExam(Long examId) { ... }
    
    // Chỉ TEACHER hoặc PROCTOR được monitor
    @PreAuthorize("hasAnyRole('TEACHER', 'PROCTOR') AND @examSecurity.canMonitor(#examId, authentication)")
    public List<StudentStatus> monitorExam(Long examId) { ... }
}
```

### 3.4 Resource-Level Authorization

```java
@Component
public class ExamSecurity {
    
    public boolean isOwner(Long examId, Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        
        // Query exam và course
        Exam exam = examRepository.findById(examId);
        Course course = exam.getCourse();
        
        // Kiểm tra user là teacher của course
        return course.getTeacher().getId().equals(user.getId());
    }
    
    public boolean canAttempt(Long examId, Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        
        Exam exam = examRepository.findById(examId);
        
        // Kiểm tra học sinh enrolled trong course
        return courseEnrollmentRepository
            .existsByCourseIdAndStudentId(
                exam.getCourse().getId(),
                user.getId()
            );
    }
}
```

## 4. CSRF Protection

### 4.1 Frontend Configuration

```javascript
// Axios interceptor
axios.interceptors.request.use((config) => {
  // Lấy CSRF token từ meta tag
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  
  if (csrfToken) {
    config.headers['X-CSRF-TOKEN'] = csrfToken;
  }
  
  return config;
});
```

### 4.2 Backend Configuration

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                .ignoringRequestMatchers("/api/v1/auth/**")  // Login exempt
            );
        
        return http.build();
    }
}
```

## 5. CORS Configuration

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    @Value("${app.cors.allowed-origins}")
    private String[] allowedOrigins;
    
    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowCredentials(true);
        config.addAllowedOriginPattern("http://localhost:*");  // Dev only
        
        config.addAllowedHeader("*");
        config.addAllowedMethod("*");
        
        // Expose headers cần thiết
        config.addExposedHeader("X-CSRF-TOKEN");
        
        source.registerCorsConfiguration("/**", config);
        
        return new CorsFilter(source);
    }
}
```

## 6. Password Security

### 6.1 Hashing Algorithm

**Chosen: Argon2id**

```java
@Configuration
public class SecurityConfig {
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        // Argon2id với:
        // - Memory: 16MB (16384 KB)
        // - Parallelism: 2 threads
        // - Iterations: 2
        return new Argon2PasswordEncoder(
            16,              // salt length
            32,              // hash length
            1,               // parallelism
            16384,           // memory (KB)
            2                // iterations
        );
    }
}
```

### 6.2 Password Requirements

```
- Độ dài: 8 - 128 ký tự
- Phải chứa: chữ hoa, chữ thường, số
- Không chứa: username, common passwords
```

## 7. Refresh Token Security

### 7.1 Token Rotation

```java
@Service
public class RefreshTokenService {
    
    @Transactional
    public RefreshTokenResponse refreshToken(String token) {
        // 1. Validate token
        RefreshSession session = validateToken(token);
        
        // 2. Check nếu bị revoke
        if (session.isRevoked()) {
            throw new RefreshTokenRevokedException();
        }
        
        // 3. Revoke token cũ
        session.setRevoked(true);
        session.setRevokedAt(Instant.now());
        
        // 4. Tạo session mới
        RefreshSession newSession = createSession(session.getUser());
        newSession.setReplacedBy(session);
        
        refreshSessionRepository.save(newSession);
        
        // 5. Trả về access token mới
        return new RefreshTokenResponse(
            generateAccessToken(session.getUser())
        );
    }
}
```

### 7.2 Token Storage

```sql
CREATE TABLE refresh_session (
    session_id      BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL UNIQUE,  -- Hashed token
    expires_at      TIMESTAMP NOT NULL,
    revoked         BOOLEAN DEFAULT FALSE,
    revoked_at      TIMESTAMP,
    replaced_by     BIGINT REFERENCES refresh_session(session_id),  -- Chain
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
```

## 8. Exam Security

### 8.1 Anti-Cheating Measures

**Backend validations:**
```java
@Service
public class ExamAttemptService {
    
    @Transactional
    public void submitAttempt(Long attemptId, SubmitAttemptDto dto) {
        ExamAttempt attempt = repository.findById(attemptId);
        
        // 1. Kiểm tra trạng thái
        if (attempt.getStatus() != AttemptStatus.IN_PROGRESS) {
            throw new AlreadySubmittedException();
        }
        
        // 2. Kiểm tra thời gian
        if (Instant.now().isAfter(attempt.getExam().getEndTime())) {
            throw new ExamExpiredException();
        }
        
        // 3. Idempotency check
        if (submissionKeyExists(dto.getSubmissionKey())) {
            throw new DuplicateSubmissionException();
        }
        
        // 4. Ghi nhận submission
        attempt.setStatus(AttemptStatus.SUBMITTED);
        attempt.setSubmitTime(Instant.now());
        
        // 5. Lưu submission key cho idempotency
        saveSubmissionKey(attemptId, dto.getSubmissionKey());
    }
}
```

**Frontend validations:**
```javascript
// Ngăn copy/paste trong exam
document.addEventListener('copy', (e) => {
  if (isInExamMode()) {
    e.preventDefault();
    showNotification('Không được copy trong khi thi');
  }
});

// Ngăn tab switch (tuỳ chọn)
document.addEventListener('visibilitychange', () => {
  if (document.hidden && isInExamMode()) {
    logSuspiciousActivity('Tab switched during exam');
  }
});
```

### 8.2 Question Protection

```java
@Service
public class QuestionService {
    
    // KHÔNG bao giờ trả về correct answer cho student
    @PreAuthorize("hasRole('TEACHER') OR hasRole('SYSTEM_ADMIN')")
    public Question getQuestionWithAnswer(Long questionId) {
        return questionRepository.findById(questionId);
    }
    
    // Student chỉ nhận content không có answer
    @PreAuthorize("hasRole('STUDENT')")
    public QuestionDto getQuestionForStudent(Long questionId) {
        Question question = questionRepository.findById(questionId);
        
        return QuestionDto.builder()
            .id(question.getId())
            .content(question.getContent())
            .options(question.getOptions())
            .points(question.getPoints())
            // KHÔNG include correctAnswer
            .build();
    }
}
```

## 9. Rate Limiting

### 9.1 API Rate Limits

```java
@Configuration
public class RateLimitConfig {
    
    @Bean
    public BucketResolver bucketResolver() {
        return (request) -> {
            String path = request.getRequestURI();
            String userId = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();
            
            // Different limits for different endpoints
            if (path.startsWith("/api/v1/attempts/") && path.contains("/answers")) {
                // Autosave: 10 requests/second
                return Bucket.builder()
                    .addLimit(Bandwidth.classic(10, Refill.intervally(10, Duration.ofSeconds(1))))
                    .build();
            }
            
            if (path.startsWith("/api/v1/auth/login")) {
                // Login: 5 requests/minute
                return Bucket.builder()
                    .addLimit(Bandwidth.classic(5, Refill.intervally(5, Duration.ofMinutes(1))))
                    .build();
            }
            
            // Default: 100 requests/minute
            return Bucket.builder()
                .addLimit(Bandwidth.classic(100, Refill.intervally(100, Duration.ofMinutes(1))))
                .build();
        };
    }
}
```

### 9.2 IP-based Rate Limiting

```java
@Component
public class IpRateLimiter {
    
    private final RedisTemplate<String, String> redisTemplate;
    
    public boolean checkLimit(String ipAddress, String endpoint) {
        String key = "rate_limit:" + endpoint + ":" + ipAddress;
        
        Long count = redisTemplate.opsForValue().increment(key);
        
        if (count == 1) {
            redisTemplate.expire(key, 1, TimeUnit.MINUTES);
        }
        
        return count <= 100; // Max 100 requests/minute per IP
    }
}
```

## 10. Input Validation

### 10.1 Backend Validation

```java
@PostMapping("/questions")
public ResponseEntity<?> createQuestion(@Valid @RequestBody CreateQuestionDto dto) {
    // @Valid triggers Bean Validation
}

public record CreateQuestionDto(
    @NotBlank(message = "Question content is required")
    String content,
    
    @NotEmpty(message = "Options cannot be empty")
    @Size(min = 2, max = 10, message = "Options must be between 2 and 10")
    List<@NotBlank String> options,
    
    @NotBlank(message = "Correct answer is required")
    String correctAnswer,
    
    @DecimalMin(value = "0.1", message = "Points must be at least 0.1")
    @DecimalMax(value = "100", message = "Points cannot exceed 100")
    BigDecimal points
) {}
```

### 10.2 Frontend Validation

```typescript
import { z } from 'zod';

const questionSchema = z.object({
  content: z.string().min(1, 'Nội dung không được để trống'),
  options: z.array(z.string().min(1)).min(2).max(10),
  correctAnswer: z.string().min(1),
  points: z.number().min(0.1).max(100),
});

type QuestionFormData = z.infer<typeof questionSchema>;
```

## 11. XSS Protection

### 11.1 Output Encoding

```java
@Service
public class QuestionService {
    
    public QuestionDto getQuestion(Long id) {
        Question question = repository.findById(id);
        
        return QuestionDto.builder()
            .content(escapeHtml(question.getContent()))  // Escape HTML
            .options(question.getOptions().stream()
                .map(this::escapeHtml)
                .toList())
            .build();
    }
    
    private String escapeHtml(String input) {
        return input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#x27;");
    }
}
```

### 11.2 Frontend Sanitization

```typescript
import DOMPurify from 'dompurify';

// Sanitize HTML content
const sanitizeContent = (html: string): string => {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a'],
    ALLOWED_ATTR: ['href']
  });
};
```

## 12. SQL Injection Prevention

### 12.1 Using JPA (Parameterized Queries)

```java
// ✅ CORRECT - JPA handles parameterization
@Query("SELECT q FROM Question q WHERE q.bank.id = :bankId")
List<Question> findByBankId(@Param("bankId") Long bankId);

// ✅ CORRECT - Positional parameters
@Query("SELECT e FROM Exam e WHERE e.course.id = ?1")
List<Exam> findByCourseId(Long courseId);

// ❌ WRONG - String concatenation vulnerable
@Query("SELECT q FROM Question q WHERE q.content LIKE '" + searchTerm + "'")
List<Question> search(String searchTerm);  // DON'T DO THIS!
```

### 12.2 Criteria API for Dynamic Queries

```java
public List<Question> searchQuestions(SearchCriteria criteria) {
    CriteriaBuilder cb = entityManager.getCriteriaBuilder();
    CriteriaQuery<Question> query = cb.createQuery(Question.class);
    Root<Question> root = query.from(Question.class);
    
    List<Predicate> predicates = new ArrayList<>();
    
    if (criteria.getType() != null) {
        predicates.add(cb.equal(root.get("type"), criteria.getType()));
    }
    
    if (criteria.getDifficulty() != null) {
        predicates.add(cb.equal(root.get("difficulty"), criteria.getDifficulty()));
    }
    
    query.where(predicates.toArray(new Predicate[0]));
    
    return entityManager.createQuery(query).getResultList();
}
```

## 13. Audit Logging

```java
@Aspect
@Component
public class AuditAspect {
    
    @Autowired
    private AuditLogRepository auditLogRepository;
    
    @AfterReturning("@annotation(auditable)")
    public void auditAction(JoinPoint joinPoint, Auditable auditable) {
        Authentication auth = SecurityContextHolder.getContext()
            .getAuthentication();
        
        AuditLog log = AuditLog.builder()
            .actorId(extractUserId(auth))
            .action(auditable.action())
            .resourceType(auditable.resourceType())
            .resourceId(extractResourceId(joinPoint))
            .details(buildDetails(joinPoint))
            .timestamp(Instant.now())
            .build();
        
        auditLogRepository.save(log);
    }
}

// Usage
@PostMapping("/exams")
@Auditable(action = "exam.create", resourceType = "EXAM")
public ResponseEntity<?> createExam(@RequestBody CreateExamDto dto) {
    // ...
}
```

## 14. Security Checklist

### Before Deployment:
- [ ] Review all public endpoints
- [ ] Verify rate limiting is enabled
- [ ] Test CSRF protection
- [ ] Verify CORS configuration
- [ ] Check password hashing strength
- [ ] Review all permissions
- [ ] Test file upload restrictions
- [ ] Verify session timeout settings
- [ ] Review error messages (no sensitive info)
- [ ] Enable security headers
- [ ] Configure TLS/SSL

### Runtime Monitoring:
- Failed login attempts
- Unusual request patterns
- Suspicious activity during exams
- API error rates
- Token refresh patterns

## 15. Security Headers

```java
@Configuration
public class SecurityHeaderConfig implements WebMvcConfigurer {
    
    @Bean
    public Filter securityHeadersFilter() {
        return new OncePerRequestFilter() {
            @Override
            protected void doFilterInternal(HttpServletRequest request,
                                           HttpServletResponse response,
                                           FilterChain filterChain) {
                response.setHeader("X-Content-Type-Options", "nosniff");
                response.setHeader("X-Frame-Options", "DENY");
                response.setHeader("X-XSS-Protection", "1; mode=block");
                response.setHeader("Strict-Transport-Security", "max-age=31536000");
                response.setHeader("Content-Security-Policy", "default-src 'self'");
                
                filterChain.doFilter(request, response);
            }
        };
    }
}
```

## 16. OAuth2 Integration (Future)

```java
@Configuration
@EnableOAuth2Client
public class OAuth2Config {
    
    // Google OAuth2
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(
            ClientRegistrationRepository clientRegistrationRepository,
            OAuth2AuthorizedClientRepository authorizedClientRepository) {
        
        OAuth2AuthorizedClientProvider authorizedClientProvider =
            OAuth2AuthorizedClientProviderBuilder.builder()
                .authorizationCode()
                .refreshToken()
                .build();
        
        DefaultOAuth2AuthorizedClientManager authorizedClientManager =
            new DefaultOAuth2AuthorizedClientManager(
                clientRegistrationRepository,
                authorizedClientRepository);
        
        authorizedClientManager.setAuthorizedClientProvider(authorizedClientProvider);
        
        return authorizedClientManager;
    }
}
```
