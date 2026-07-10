# Quizopia — Demo / Dev Seed Data

> File seed: `docs/demo/quizopia_demo_seed.sql`
> File README: `docs/demo/DEMO_DATA_README.md`
> Phạm vi: **DEMO / DEV ONLY** — phục vụ demo local cho giảng viên. **Không phải migration Flyway, không chạy trên production.**

---

## 1. Mục đích

Tạo một bộ dữ liệu mẫu tự contained để demo toàn bộ luồng MVP của Quizopia trên môi trường local:

- Đăng nhập với đủ các vai trò (SYSTEM_ADMIN, ACADEMIC_ADMIN, TEACHER, STUDENT).
- Ngân hàng câu hỏi với đủ **4 loại câu hỏi** đã chốt (SINGLE_CHOICE, MULTIPLE_CHOICE, TRUE_FALSE_MATRIX, NUMERIC_FILL).
- Một đề thi đã **publish** (snapshot bất biến dùng cho chấm điểm).
- Một ca thi (exam session) ở trạng thái **OPEN**, cửa sổ thời gian bao phủ hiện tại.
- 3 học sinh là participant; **2 học sinh đã nộp bài & chấm sẵn** (để Results / Statistics / Excel export hoạt động ngay), 1 học sinh chưa nộp (dành cho demo "làm bài trực tiếp").

Seed **idempotent** — chạy nhiều lần không tạo trùng, không ghi đè dữ liệu đã có.

---

## 2. Cảnh báo (bắt buộc đọc)

- **Chỉ dùng local/dev. Không chạy trên production.**
- **Không chứa secret production**: không có plaintext password, không refresh token, không JWT/AES key.
- **Chỉ insert dữ liệu có prefix DEMO / demo_** (username `demo_…`, email `@demo.quizopia.local`, code `DEMO_…`, title/name `[DEMO]…`). Không insert/sửa/xóa dữ liệu thật.
- **Không thay đổi schema**: file là SQL thuần (`INSERT … WHERE NOT EXISTS` / `ON CONFLICT`), không `CREATE/ALTER/DROP/TRUNCATE`, không tắt constraint, **không tạo V10**, không sửa V1–V9.
- **Mật khẩu demo** của mọi tài khoản là `Password123` (xem §4). Hash là Argon2id hợp lệ theo format backend (xem §9).

---

## 3. Cách chạy

Yêu cầu: Docker Compose đang `up` (service `postgres-db` / container `quizopia_postgres` đang chạy). Thông tin kết nối theo `docker-compose.yml`: user `quiz_user`, db `quizopia_db`.

> Lưu ý: file **tự `BEGIN/COMMIT`** (atomic, all-or-nothing). Nếu một statement lỗi → toàn bộ seed bị rollback, không ghi gì.

**Bash / Git Bash (Windows):**

```bash
docker exec -i quizopia_postgres psql -U quiz_user -d quizopia_db < docs/demo/quizopia_demo_seed.sql
```

**PowerShell** (nếu redirect `<` không ổn):

```powershell
Get-Content docs/demo/quizopia_demo_seed.sql -Raw | docker exec -i quizopia_postgres psql -U quiz_user -d quizopia_db
```

**Kiểm tra chạy thành công:** không có dòng `ERROR`. Để xem dữ liệu, dùng các lệnh ở §6.

---

## 4. Tài khoản demo

Mọi tài khoản dùng chung mật khẩu: **`Password123`**

| Role             | Username             | Email                               | Password       | display_name           | Ghi chú                                       |
|------------------|----------------------|-------------------------------------|----------------|------------------------|-----------------------------------------------|
| SYSTEM_ADMIN     | `demo_sysadmin`      | demo_sysadmin@demo.quizopia.local   | `Password123`  | [DEMO] System Admin    | Toàn cục (xem results/stats/export).          |
| ACADEMIC_ADMIN   | `demo_academic_admin`| demo_academic_admin@demo.quizopia.local | `Password123` | [DEMO] Academic Admin | MVP scope: mọi session.                       |
| TEACHER          | `demo_teacher`       | demo_teacher@demo.quizopia.local    | `Password123`  | [DEMO] Teacher Nguyen  | Sở hữu question bank + exam + session.        |
| STUDENT          | `demo_student_01`    | demo_student_01@demo.quizopia.local | `Password123`  | [DEMO] Student One     | Đã nộp — **100%**.                            |
| STUDENT          | `demo_student_02`    | demo_student_02@demo.quizopia.local | `Password123`  | [DEMO] Student Two     | Đã nộp — **50%**.                             |
| STUDENT          | `demo_student_03`    | demo_student_03@demo.quizopia.local | `Password123`  | [DEMO] Student Three   | Chưa nộp — dành cho demo "làm bài trực tiếp". |

Đăng nhập thử (PowerShell):

```powershell
$login = '{"identifier":"demo_teacher","password":"Password123"}'
Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/auth/login -ContentType "application/json" -Body $login
```

---

## 5. Dữ liệu demo được tạo

| Nhóm | Chi tiết |
|------|----------|
| **Users** | 6 user + gán role (theo code). |
| **Academic** | 1 school `DEMO-SCHOOL`, 3 grade levels `G10`/`G11`/`G12`, 15 môn THPT × 3 khối = 45 subjects, 4 exam purposes (MIDTERM/FINAL/QUIZ/PRACTICE), 1 teacher profile, 3 student profiles. Demo QB/exam gắn với subject `TIN` (Tin học) ở Grade 12. |
| **Question bank** | 1 bank `DEMO_QB_JAVA` sở hữu bởi `demo_teacher`. 4 câu hỏi, mỗi câu 1 version: `DEMO_Q_SC` (SINGLE, 1đ), `DEMO_Q_MC` (MULTIPLE, 2đ), `DEMO_Q_TF` (TRUE_FALSE_MATRIX, 2đ), `DEMO_Q_NF` (NUMERIC_FILL, 1đ). |
| **Exam** | 1 exam `DEMO_EXAM_JAVA` → 1 **PUBLISHED** version (total_points = 6.00, duration 30p) → 1 section → 4 exam_questions (snapshot pinned source version) + options. |
| **Session** | 1 session `DEMO_SESS_JAVA`, status **OPEN**, cửa sổ `now−1day … now+7day`, `opened_at = now−1h`, `max_attempts = 1`. |
| **Participants** | 3 student profiles thêm với status `ELIGIBLE` (added_by = demo teacher). |
| **Kết quả (Day 8)** | 2 attempt SUBMITTED + Grade AUTO_GRADED + 4 GradeItem mỗi attempt + idempotency cache. **demo_student_01 = 6.00/6.00 (100%)**, **demo_student_02 = 3.00/6.00 (50%)**. `demo_student_03` không có attempt. |

> **Interoperability:** code `DEMO-SCHOOL` + các grade/subject thật (G10/G11/G12, 15 môn THPT) cố tình trùng với backend `DemoDataSeeder` (`com.hhtuann.backend.academic.application.DemoDataSeeder`, bật bằng `QUIZOPIA_DEMO_DATA_ENABLED=true`). Seed SQL này và Java seeder có thể cùng tồn tại, không xung đột duplicate. Nếu Java seeder đã chạy trước, seed SQL sẽ "find" các dòng đó thay vì tạo mới.

> **Vì sao có kết quả chấm sẵn (Block 6 là optional):** để Results / Statistics / Excel export có dữ liệu ngay mà không phải tự nộp bài. Block 6 được tách rõ và có comment trong file SQL; **muốn bỏ, comment toàn bộ Block 6** là session/participants vẫn đủ để demo "làm bài + nộp trực tiếp".

---

## 6. Cách kiểm tra

Chạy qua container `quizopia_postgres`:

```sql
-- Demo users + role
SELECT u.username, u.email, u.display_name, r.code AS role
FROM users u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
WHERE u.username LIKE 'demo_%'
ORDER BY u.username;

-- Question types có mặt
SELECT DISTINCT qv.question_type
FROM question_versions qv
JOIN questions q ON q.id = qv.question_id
JOIN question_banks qb ON qb.id = q.question_bank_id
WHERE LOWER(qb.code) = 'demo_qb_java';

-- Session + trạng thái + số participant
SELECT es.code, es.status, es.starts_at, es.ends_at,
       (SELECT count(*) FROM exam_session_participants p WHERE p.exam_session_id = es.id) AS participants
FROM exam_sessions es WHERE LOWER(es.code) = 'demo_sess_java';

-- Kết quả đã chấm (BEST/source cho statistics/export)
SELECT u.username, a.status, g.final_score, g.max_score, g.percentage, g.status AS grade_status
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN grades g ON g.attempt_id = a.id
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users u ON u.id = sp.user_id
ORDER BY g.percentage DESC;

-- Kiểm tra idempotent: chạy seed lại rồi đếm (phải không đổi)
SELECT count(*) FROM users WHERE username LIKE 'demo_%';
```

Kiểm tra qua API Day 8 (đăng nhập `demo_teacher` lấy access token):

```text
GET  /api/exam-sessions/{sessionId}/results        # 2 dòng BEST (100%, 50%)
GET  /api/exam-sessions/{sessionId}/statistics       # eligible=3, submitted=2
GET  /api/exam-sessions/{sessionId}/results/export   # Excel (Results + Statistics)
```

`sessionId` lấy từ: `SELECT id FROM exam_sessions WHERE lower(code)='demo_sess_java';`

---

## 7. Cách cleanup

Cleanup **chỉ xoá dữ liệu demo** (`demo_%` / `DEMO` / school `DEMO-SCHOOL`), theo đúng thứ tự FK (RESTRICT/CASCADE). **Nếu chưa rành FK, đừng tự xoá tay** — dùng đúng script dưới. Lưu thành `docs/demo/quizopia_demo_cleanup.sql` rồi chạy như §3.

```sql
BEGIN;

-- 6. Kết quả / attempt demo (thuộc session DEMO_SESS_JAVA)
DELETE FROM idempotency_records WHERE attempt_id IN (
  SELECT a.id FROM attempts a JOIN exam_sessions es ON es.id=a.exam_session_id WHERE LOWER(es.code)='demo_sess_java');
DELETE FROM grade_items WHERE grade_id IN (
  SELECT g.id FROM grades g JOIN attempts a ON a.id=g.attempt_id
  JOIN exam_sessions es ON es.id=a.exam_session_id WHERE LOWER(es.code)='demo_sess_java');
DELETE FROM grades WHERE attempt_id IN (
  SELECT a.id FROM attempts a JOIN exam_sessions es ON es.id=a.exam_session_id WHERE LOWER(es.code)='demo_sess_java');
DELETE FROM attempt_answers WHERE attempt_id IN (
  SELECT a.id FROM attempts a JOIN exam_sessions es ON es.id=a.exam_session_id WHERE LOWER(es.code)='demo_sess_java');
DELETE FROM attempt_questions WHERE attempt_id IN (
  SELECT a.id FROM attempts a JOIN exam_sessions es ON es.id=a.exam_session_id WHERE LOWER(es.code)='demo_sess_java');
DELETE FROM attempts WHERE exam_session_id IN (
  SELECT id FROM exam_sessions WHERE LOWER(code)='demo_sess_java');

-- 5. Participants + session
DELETE FROM exam_session_participants WHERE exam_session_id IN (
  SELECT id FROM exam_sessions WHERE LOWER(code)='demo_sess_java');
DELETE FROM exam_question_options WHERE exam_question_id IN (
  SELECT eq.id FROM exam_questions eq JOIN exam_versions ev ON ev.id=eq.exam_version_id
  JOIN exams e ON e.id=ev.exam_id WHERE LOWER(e.code)='demo_exam_java');
DELETE FROM exam_questions WHERE exam_version_id IN (
  SELECT ev.id FROM exam_versions ev JOIN exams e ON e.id=ev.exam_id WHERE LOWER(e.code)='demo_exam_java');
DELETE FROM exam_sections WHERE exam_version_id IN (
  SELECT ev.id FROM exam_versions ev JOIN exams e ON e.id=ev.exam_id WHERE LOWER(e.code)='demo_exam_java');
DELETE FROM exam_versions WHERE exam_id IN (SELECT id FROM exams WHERE LOWER(code)='demo_exam_java');
DELETE FROM exam_sessions WHERE LOWER(code)='demo_sess_java';
DELETE FROM exams WHERE LOWER(code)='demo_exam_java';

-- 4. Question bank
DELETE FROM question_options WHERE question_version_id IN (
  SELECT qv.id FROM question_versions qv JOIN questions q ON q.id=qv.question_id
  JOIN question_banks qb ON qb.id=q.question_bank_id WHERE LOWER(qb.code)='demo_qb_java');
DELETE FROM question_versions WHERE question_id IN (
  SELECT q.id FROM questions q JOIN question_banks qb ON qb.id=q.question_bank_id WHERE LOWER(qb.code)='demo_qb_java');
DELETE FROM questions WHERE question_bank_id IN (SELECT id FROM question_banks WHERE LOWER(code)='demo_qb_java');
DELETE FROM question_banks WHERE LOWER(code)='demo_qb_java';

-- 3. Profiles (FK RESTRICT tới users)
DELETE FROM teacher_profiles WHERE user_id IN (SELECT id FROM users WHERE username LIKE 'demo_%');
DELETE FROM student_profiles WHERE user_id IN (SELECT id FROM users WHERE username LIKE 'demo_%');

-- 2. Roles assignment + users
DELETE FROM user_roles WHERE user_id IN (SELECT id FROM users WHERE username LIKE 'demo_%');
DELETE FROM users WHERE username LIKE 'demo_%';

-- 1. (Tuỳ chọn) academic tree — CHUNG với DemoDataSeeder. Chỉ xoá nếu chắc.
DELETE FROM exam_purposes WHERE school_id IN (SELECT id FROM schools WHERE LOWER(code)='demo-school');
DELETE FROM subjects WHERE school_id IN (SELECT id FROM schools WHERE LOWER(code)='demo-school');
DELETE FROM grade_levels WHERE school_id IN (SELECT id FROM schools WHERE LOWER(code)='demo-school');
DELETE FROM schools WHERE LOWER(code)='demo-school';

COMMIT;
```

> Nếu `QUIZOPIA_DEMO_DATA_ENABLED=true`, sau khi xoá school tree, backend sẽ tự tạo lại `DEMO-SCHOOL` + G10/G11/G12 + 45 subjects + purposes ở lần khởi động kế tiếp — đây là hành vi bình thường.

---

## 8. Demo flow đề xuất

1. `docker compose up -d` (đảm bảo backend healthy: `curl http://localhost:8080/actuator/health`).
2. Chạy seed (§3).
3. **Đăng nhập `demo_teacher`** → mở Question Bank (`DEMO_QB_JAVA`) xem 4 loại câu hỏi; mở Exam (`DEMO_EXAM_JAVA`) + Session (`DEMO_SESS_JAVA`) ở trạng thái OPEN.
4. **Đăng nhập `demo_student_03`** → thấy session khả dụng → **Start attempt → làm bài → Submit** (backend tự chấm). Có thể thử NUMERIC với `1.00`, `1` hoặc `01.0` (đều bằng `1` do `BigDecimal.compareTo`).
5. **Đăng nhập `demo_teacher` (hoặc admin)** → xem **Results** (3 dòng sau khi stu03 nộp), **Statistics** (distribution + per-question), **Export Excel**.
6. (Tuỳ chọn) Đăng nhập `demo_student_01`/`demo_student_02` → xem kết quả của chính mình (`/result`, `/results/me/best`).

> Nếu frontend chưa có trang Results/Statistics/Export (FE15 chưa build theo handoff), dùng API ở §6 để demo Day 8 backend.

---

## 9. Ghi chú về password hash (Argon2id)

- Mật khẩu demo: **`Password123`** (cho mọi tài khoản).
- `password_hash` lưu là chuỗi **Argon2id dạng PHC** đúng format backend Spring Security:
  `$argon2id$v=19$m=16384,t=2,p=1$<salt>$<hash>`
- Đây chính là định dạng do `Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8()` sinh ra (`com.hhtuann.backend.security.password.Argon2PasswordHasher`). Tham số `m=16384, t=2, p=1, salt 16 byte, hash 32 byte` khớp mặc định Spring → backend **không cần re-hash** khi login.
- Backend verify bằng cách giải mã tham số + salt từ chuỗi rồi re-derive, nên hash này được chấp nhận bất kể tham số mặc định.
- **Không bao giờ** lưu plaintext password. Hash này chỉ dùng cho demo.

**Cách tự sinh lại hash khác** (nếu muốn đổi mật khẩu demo):

```bash
# Cần argon2-cffi (pip install argon2-cffi) — hoặc chạy trong container python
python -c "from argon2 import PasswordHasher, Type; \
ph=PasswordHasher(time_cost=2,memory_cost=16384,parallelism=1,hash_len=32,salt_len=16,type=Type.ID); \
print(ph.hash('Password123'))"
```

Hoặc dùng endpoint `POST /api/auth/register` rồi copy `password_hash` từ DB (khuyến nghị nếu muốn hash do chính backend sinh).

---

## 10. Trạng thái kiểm thử (validation)

Seed đã được kiểm thử thực tế trong một container **PostgreSQL 17 dùng một lần (throwaway)** — **không** đụng tới DB dự án:

- Áp dụng V1–V9 thành công.
- Seed chạy thành công (pass 1); các số liệu đúng: 6 user + role, 1 school + profiles, 4 loại câu hỏi, exam PUBLISHED, session OPEN, 3 participant, 2 attempt SUBMITTED + Grade AUTO_GRADED + 8 grade_items + 2 idempotency record.
- **Idempotent**: chạy lại (pass 2) cho số liệu không đổi (không trùng).
- **Nhất quán chấm điểm**: `sum(grade_items.awarded) = grade.final_score`, `sum(max) = max_score`. Recompute correctness từ `answer_payload` so với `answer_key` khớp đúng `grade_items.is_correct` cho cả 8 câu.
- **BEST CTE** (như `SessionResultService`) trả về đúng: stu01 = 100%, stu02 = 50%. **Statistics**: eligible = 3, submitted = 2.
- Hash Argon2id **verify đúng** `Password123`, **reject** mật khẩu sai.

> Lưu ý rollback-test: vì file tự `COMMIT`, nếu muốn test-rollback hãy **comment dòng `COMMIT;`** cuối file rồi `BEGIN; \i ...sql; ROLLBACK;`.
