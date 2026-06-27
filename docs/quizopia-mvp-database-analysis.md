# Phân tích Database Quizopia MVP Phase 1

## 1. Quy mô

| Module            | Số bảng |
| ----------------- | ------: |
| Identity          |       0 |
| Academic          |       8 |
| Question Bank     |       4 |
| Exam              |       8 |
| Attempt & Grading |       6 |
| **Tổng**          |  **32** |

32 bảng đủ để hoàn thiện luồng cốt lõi: đăng nhập, quản lý học thuật, ngân hàng câu hỏi, tạo và publish đề, mở ca thi, làm bài, autosave, submit idempotent và chấm điểm.

## 2. Các quyết định thiết kế chính

### RBAC thay cho role enum

Một user có thể có nhiều role. Permission chỉ là lớp kiểm tra đầu tiên; service vẫn phải kiểm tra ownership, school scope, assignment và trạng thái nghiệp vụ.

### Profile composition thay JPA inheritance

`teacher_profiles` và `student_profiles` liên kết 1–1 với `users`. Điều này tách danh tính đăng nhập khỏi hồ sơ học thuật và tránh discriminator/inheritance phức tạp.

### Academic được giản lược có chủ đích

`subjects` gắn trực tiếp khối; `classrooms` chứa `academic_year`. Chưa tạo semester, class group hoặc course offering để tránh tăng scope MVP.

### Question versioning

`questions` là identity ổn định, `question_versions` là nội dung. Sửa câu hỏi tạo version mới.

### Exam snapshot

Khi publish, nội dung được copy sang `exam_questions` và `exam_question_options`. Thay đổi Question Bank sau đó không làm đổi đề đã publish.

### Attempt/Answer/Grade thay exam_result.answer TEXT

Tách dữ liệu theo câu cho phép autosave, random ổn định, thống kê, chấm chi tiết và idempotency.

## 3. Transaction boundaries

### Publish exam

Kiểm tra quyền và trạng thái → copy snapshot → tính tổng điểm → đổi status PUBLISHED trong một transaction.

### Start attempt

Kiểm tra participant, thời gian, max attempts → tạo attempt và stable question order trong một transaction.

### Autosave

UPSERT theo attempt/question và chỉ nhận `sequence_number` lớn hơn giá trị hiện tại.

### Submit

Khóa/kiểm tra attempt → kiểm tra idempotency → finalize answer → đổi trạng thái → auto-grade → tạo grade/items → lưu response idempotency → commit. Event/WebSocket chỉ phát sau commit.

## 4. Deletion strategy

Mặc định `RESTRICT`. Cascade chỉ dùng cho bảng nối, refresh session và child không có ý nghĩa độc lập. Application cấm hard delete version đã publish, attempt đã bắt đầu và grade lịch sử.

## 5. Rủi ro và trade-off

- Subject lặp theo grade level nhưng đơn giản và bám nghiệp vụ MVP.
- Academic year dạng chuỗi cần service validation.
- Snapshot tăng dung lượng nhưng giữ tính đúng đắn lịch sử.
- JSONB chỉ dùng ở chỗ cấu trúc thật sự biến đổi; phải validate bằng DTO/schema.
- Permission seed không thay thế ownership và school-scope checks.

## 6. Thứ tự triển khai

1. Identity + refresh rotation.
2. Academic CRUD và school scope.
3. Question Bank + versioning.
4. Exam draft/publish/snapshot.
5. Session + participant.
6. Attempt/autosave/idempotent submit.
7. Grading + integration/load tests.

## 7. Phần hoãn

OAuth/OIDC, password reset, MFA, Excel import, homework, document storage, audit, notification, outbox, incident và review request thuộc phase sau.
