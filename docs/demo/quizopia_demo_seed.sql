-- ============================================================
-- Quizopia — Demo / Dev Seed Data
-- File : docs/demo/quizopia_demo_seed.sql
-- Type : DEMO / DEV ONLY. NOT a Flyway migration. NOT for production.
--
-- Purpose
--   Provision a self-contained demo dataset so the Quizopia MVP can be
--   demonstrated end-to-end (login as each role, question bank, published
--   exam, open session, submitted results, statistics, Excel export).
--
-- Safety rules followed
--   - Idempotent: every row uses INSERT ... WHERE NOT EXISTS / ON CONFLICT,
--     keyed by natural/business keys (username, email, code, slug, ...).
--     Re-running never duplicates and never overwrites existing rows.
--   - Demo scoping: all demo data uses the demo_ / DEMO / [DEMO] prefix.
--     No real (non-demo) data is inserted, updated or deleted.
--   - No secrets: no plaintext password, no refresh token, no JWT/AES key.
--     password_hash is an Argon2id PHC string (Spring Security format) of
--     the demo password "Password123" — see DEMO_DATA_README.md.
--   - No schema change: no CREATE/ALTER/DROP/TRUNCATE, no constraint toggle,
--     no V10. V1-V9 migrations are untouched.
--   - Transactional: the whole seed runs in one BEGIN/COMMIT (all-or-nothing).
--
-- Interoperability
--   Real curriculum data: grade levels G10/G11/G12 and 15 Vietnamese subjects
--   per grade (45 rows). The demo exam/question bank attach to subject TIN
--   (Tin học) under Grade 12. Codes match the backend DemoDataSeeder so this
--   seed and the Java seeder (QUIZOPIA_DEMO_DATA_ENABLED=true) coexist without
--   duplicate-key conflicts.
-- ============================================================

SET client_encoding TO 'UTF8';

BEGIN;

-- ============================================================
-- BLOCK 1 — DEMO USERS + ROLE ASSIGNMENTS
-- All accounts use the demo password "Password123" (Argon2id hash below).
-- The hash is genuine Argon2id in Spring Security PHC format
-- ($argon2id$v=19$m=16384,t=2,p=1$<salt>$<tag>) and verifies against the
-- backend's Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8().
-- ============================================================

-- status defaults to 'ACTIVE' (V2); token_version / failed_login_attempts default to 0.
INSERT INTO users (username, email, password_hash, display_name)
SELECT v.username, v.email, v.password_hash, v.display_name
FROM (VALUES
    ('demo_sysadmin',       'demo_sysadmin@demo.quizopia.local',       '$argon2id$v=19$m=16384,t=2,p=1$fY85NY8PlcHqskQdq5qpfw$H2RuW/pR6ylqjDMKqDJH04GE+iI9+9a8eOovoNAvRBg', '[DEMO] System Admin'),
    ('demo_academic_admin', 'demo_academic_admin@demo.quizopia.local', '$argon2id$v=19$m=16384,t=2,p=1$fY85NY8PlcHqskQdq5qpfw$H2RuW/pR6ylqjDMKqDJH04GE+iI9+9a8eOovoNAvRBg', '[DEMO] Academic Admin'),
    ('demo_teacher',        'demo_teacher@demo.quizopia.local',        '$argon2id$v=19$m=16384,t=2,p=1$fY85NY8PlcHqskQdq5qpfw$H2RuW/pR6ylqjDMKqDJH04GE+iI9+9a8eOovoNAvRBg', '[DEMO] Teacher Nguyen'),
    ('demo_student_01',     'demo_student_01@demo.quizopia.local',     '$argon2id$v=19$m=16384,t=2,p=1$fY85NY8PlcHqskQdq5qpfw$H2RuW/pR6ylqjDMKqDJH04GE+iI9+9a8eOovoNAvRBg', '[DEMO] Student One'),
    ('demo_student_02',     'demo_student_02@demo.quizopia.local',     '$argon2id$v=19$m=16384,t=2,p=1$fY85NY8PlcHqskQdq5qpfw$H2RuW/pR6ylqjDMKqDJH04GE+iI9+9a8eOovoNAvRBg', '[DEMO] Student Two'),
    ('demo_student_03',     'demo_student_03@demo.quizopia.local',     '$argon2id$v=19$m=16384,t=2,p=1$fY85NY8PlcHqskQdq5qpfw$H2RuW/pR6ylqjDMKqDJH04GE+iI9+9a8eOovoNAvRBg', '[DEMO] Student Three')
) AS v(username, email, password_hash, display_name)
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE LOWER(u.username) = LOWER(v.username));

-- Assign the foundational role to each demo user (resolved by role code).
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'SYSTEM_ADMIN'
WHERE LOWER(u.username) = 'demo_sysadmin'
ON CONFLICT (user_id, role_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'ACADEMIC_ADMIN'
WHERE LOWER(u.username) = 'demo_academic_admin'
ON CONFLICT (user_id, role_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'TEACHER'
WHERE LOWER(u.username) = 'demo_teacher'
ON CONFLICT (user_id, role_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.code = 'STUDENT'
WHERE LOWER(u.username) IN ('demo_student_01', 'demo_student_02', 'demo_student_03')
ON CONFLICT (user_id, role_id) DO NOTHING;

-- ============================================================
-- BLOCK 2 — ACADEMIC (school / grade level / subject / profiles)
-- Codes match DemoDataSeeder. Purpose codes are ensured here too so the
-- demo exam can attach a purpose regardless of whether the Java seeder ran.
-- ============================================================

INSERT INTO schools (code, name, address)
SELECT 'DEMO-SCHOOL', '[DEMO] Quizopia Demo School', 'Demo Campus, Hanoi'
WHERE NOT EXISTS (SELECT 1 FROM schools WHERE LOWER(code) = 'demo-school');

-- Real Vietnamese high-school grade levels: Grade 10 / 11 / 12.
INSERT INTO grade_levels (school_id, code, name, sort_order)
SELECT s.id, v.code, v.name, v.sort_order
FROM schools s
CROSS JOIN (VALUES
    ('G10', 'Grade 10', 10),
    ('G11', 'Grade 11', 11),
    ('G12', 'Grade 12', 12)
) AS v(code, name, sort_order)
WHERE LOWER(s.code) = 'demo-school'
  AND NOT EXISTS (
      SELECT 1 FROM grade_levels gl
      WHERE gl.school_id = s.id AND LOWER(gl.code) = LOWER(v.code)
  );

-- Real Vietnamese curriculum subjects, created for every grade level (15 x 3 = 45).
INSERT INTO subjects (school_id, grade_level_id, code, name)
SELECT s.id, gl.id, v.code, v.name
FROM schools s
JOIN grade_levels gl ON gl.school_id = s.id AND LOWER(gl.code) IN ('g10','g11','g12')
CROSS JOIN (VALUES
    ('VAN',      'Ngữ văn'),
    ('TOAN',     'Toán học'),
    ('NGOAI_NGU','Ngoại ngữ'),
    ('GDTC',     'Giáo dục thể chất'),
    ('GDQP',     'Giáo dục quốc phòng và an ninh'),
    ('GDKT_PL',  'Giáo dục kinh tế và pháp luật'),
    ('HDTN_HN',  'Hoạt động trải nghiệm, hướng nghiệp'),
    ('LY',       'Vật lý'),
    ('HOA',      'Hóa học'),
    ('SINH',     'Sinh học'),
    ('SU',       'Lịch sử'),
    ('DIA',      'Địa lý'),
    ('GDCD',     'Giáo dục công dân'),
    ('TIN',      'Tin học'),
    ('CN',       'Công nghệ')
) AS v(code, name)
WHERE LOWER(s.code) = 'demo-school'
  AND NOT EXISTS (
      SELECT 1 FROM subjects sub
      WHERE sub.school_id = s.id AND sub.grade_level_id = gl.id AND LOWER(sub.code) = LOWER(v.code)
  );

-- Ensure the 4 default exam purposes for the demo school (mirrors V8 seed + DemoDataSeeder).
INSERT INTO exam_purposes (school_id, code, title, position)
SELECT s.id, v.code, v.title, v.position
FROM schools s
CROSS JOIN (VALUES
    ('MIDTERM',  'Giua ky',       0),
    ('FINAL',    'Cuoi ky',       1),
    ('QUIZ',     'Bai kiem tra',  2),
    ('PRACTICE', 'Luyen tap',     3)
) AS v(code, title, position)
WHERE LOWER(s.code) = 'demo-school'
  AND NOT EXISTS (
      SELECT 1 FROM exam_purposes p
      WHERE p.school_id = s.id AND LOWER(p.code) = LOWER(v.code)
  );

-- Teacher profile (1-1 with demo_teacher), scoped to the demo school.
INSERT INTO teacher_profiles (user_id, school_id, teacher_code, title, employment_status)
SELECT u.id, s.id, 'DEMO_TCH_01', '[DEMO] Instructor', 'ACTIVE'
FROM users u, schools s
WHERE LOWER(u.username) = 'demo_teacher' AND LOWER(s.code) = 'demo-school'
  AND NOT EXISTS (
      SELECT 1 FROM teacher_profiles tp WHERE tp.user_id = u.id
  );

-- Student profiles (1-1 with each demo student), scoped to the demo school.
INSERT INTO student_profiles (user_id, school_id, student_code, enrollment_status)
SELECT u.id, s.id, v.student_code, 'ACTIVE'
FROM users u, schools s
CROSS JOIN (VALUES
    ('demo_student_01', 'DEMO_STU_01'),
    ('demo_student_02', 'DEMO_STU_02'),
    ('demo_student_03', 'DEMO_STU_03')
) AS v(username, student_code)
WHERE LOWER(u.username) = LOWER(v.username) AND LOWER(s.code) = 'demo-school'
  AND NOT EXISTS (
      SELECT 1 FROM student_profiles sp WHERE sp.user_id = u.id
  );

-- ============================================================
-- BLOCK 3 — QUESTION BANK (4 questions, one per approved type)
--   Q SINGLE_CHOICE      : 4 options, exactly 1 correct.       max 1 pt
--   Q MULTIPLE_CHOICE    : 4 options, correct = {A, B}.        max 2 pt
--   Q TRUE_FALSE_MATRIX  : 4 statements A-D.                   max 2 pt
--   Q NUMERIC_FILL       : expectedAnswer "1.00" (4 chars).    max 1 pt
-- Total exam max = 6.00.
-- NUMERIC_FILL answer_key: {"expectedAnswer":"1.00"} (V12: requiredInputLength +
--                            roundingInstruction removed; rounding hint is in the content)
-- Grading uses BigDecimal.compareTo, so 1.00 == 1 == 1.0 numerically.
-- ============================================================

INSERT INTO question_banks (school_id, subject_id, owner_teacher_id, code, name, description, visibility, status)
SELECT s.id, subj.id, tp.id, 'DEMO_QB_JAVA', '[DEMO] Java Backend Question Bank',
       '[DEMO] Spring Boot / Java fundamentals (demo only)', 'PRIVATE', 'ACTIVE'
FROM schools s
JOIN grade_levels gl  ON gl.school_id = s.id   AND LOWER(gl.code) = 'g12'
JOIN subjects subj   ON subj.school_id = s.id   AND subj.grade_level_id = gl.id AND LOWER(subj.code) = 'tin'
JOIN teacher_profiles tp ON tp.school_id = s.id
JOIN users u          ON u.id = tp.user_id       AND LOWER(u.username) = 'demo_teacher'
WHERE LOWER(s.code) = 'demo-school'
  AND NOT EXISTS (
      SELECT 1 FROM question_banks qb
      WHERE qb.owner_teacher_id = tp.id AND LOWER(qb.code) = 'demo_qb_java'
  );

-- Four questions (identity rows). status ACTIVE so they are usable in composition.
INSERT INTO questions (question_bank_id, code, current_version_number, status, created_by)
SELECT qb.id, v.code, 1, 'ACTIVE', u.id
FROM question_banks qb
JOIN teacher_profiles tp ON tp.id = qb.owner_teacher_id
JOIN users u             ON u.id = tp.user_id AND LOWER(u.username) = 'demo_teacher'
CROSS JOIN (VALUES
    ('DEMO_Q_SC'),
    ('DEMO_Q_MC'),
    ('DEMO_Q_TF'),
    ('DEMO_Q_NF')
) AS v(code)
WHERE LOWER(qb.code) = 'demo_qb_java'
  AND NOT EXISTS (
      SELECT 1 FROM questions q
      WHERE q.question_bank_id = qb.id AND LOWER(q.code) = LOWER(v.code)
  );

-- Helper: owner/creator user id for the question bank.
-- question_versions (immutable content + answer key).
-- SINGLE_CHOICE
INSERT INTO question_versions (question_id, version_number, question_type, content, explanation, difficulty, default_points, answer_key, metadata, created_by)
SELECT q.id, 1, 'SINGLE_CHOICE',
       '[DEMO] Which annotation marks a class as a REST controller in Spring Boot?',
       '[DEMO] @RestController is a @Controller + @ResponseBody stereotype.',
       'EASY', 1.00, NULL, '{}'::jsonb, u.id
FROM questions q
JOIN question_banks qb ON qb.id = q.question_bank_id
JOIN teacher_profiles tp ON tp.id = qb.owner_teacher_id
JOIN users u ON u.id = tp.user_id AND LOWER(u.username) = 'demo_teacher'
WHERE LOWER(qb.code) = 'demo_qb_java' AND LOWER(q.code) = 'demo_q_sc'
  AND NOT EXISTS (SELECT 1 FROM question_versions qv WHERE qv.question_id = q.id AND qv.version_number = 1);

-- MULTIPLE_CHOICE
INSERT INTO question_versions (question_id, version_number, question_type, content, explanation, difficulty, default_points, answer_key, metadata, created_by)
SELECT q.id, 1, 'MULTIPLE_CHOICE',
       '[DEMO] Select ALL Spring container stereotype annotations.',
       '[DEMO] @Component and @RestController are stereotypes; @GetMapping/@Transient are not.',
       'MEDIUM', 2.00, NULL, '{}'::jsonb, u.id
FROM questions q
JOIN question_banks qb ON qb.id = q.question_bank_id
JOIN teacher_profiles tp ON tp.id = qb.owner_teacher_id
JOIN users u ON u.id = tp.user_id AND LOWER(u.username) = 'demo_teacher'
WHERE LOWER(qb.code) = 'demo_qb_java' AND LOWER(q.code) = 'demo_q_mc'
  AND NOT EXISTS (SELECT 1 FROM question_versions qv WHERE qv.question_id = q.id AND qv.version_number = 1);

-- TRUE_FALSE_MATRIX (4 statements A-D)
INSERT INTO question_versions (question_id, version_number, question_type, content, explanation, difficulty, default_points, answer_key, metadata, created_by)
SELECT q.id, 1, 'TRUE_FALSE_MATRIX',
       '[DEMO] Mark each statement True or False.',
       '[DEMO] Java is statically typed; Spring Boot does not require XML; Hibernate is an ORM; PostgreSQL is relational (not NoSQL).',
       'MEDIUM', 2.00, NULL, '{}'::jsonb, u.id
FROM questions q
JOIN question_banks qb ON qb.id = q.question_bank_id
JOIN teacher_profiles tp ON tp.id = qb.owner_teacher_id
JOIN users u ON u.id = tp.user_id AND LOWER(u.username) = 'demo_teacher'
WHERE LOWER(qb.code) = 'demo_qb_java' AND LOWER(q.code) = 'demo_q_tf'
  AND NOT EXISTS (SELECT 1 FROM question_versions qv WHERE qv.question_id = q.id AND qv.version_number = 1);

-- NUMERIC_FILL (answer_key required; expectedAnswer must be exactly 4 chars per schema CHECK)
INSERT INTO question_versions (question_id, version_number, question_type, content, explanation, difficulty, default_points, answer_key, metadata, created_by)
SELECT q.id, 1, 'NUMERIC_FILL',
       '[DEMO] Compute 0.50 + 0.50. Enter the result as a 4-character number with two decimal places (e.g. 1.00).',
       '[DEMO] Grading compares numerically with BigDecimal.compareTo (1.00 == 1).',
       'EASY', 1.00,
       '{"expectedAnswer":"1.00"}'::jsonb,
       '{}'::jsonb, u.id
FROM questions q
JOIN question_banks qb ON qb.id = q.question_bank_id
JOIN teacher_profiles tp ON tp.id = qb.owner_teacher_id
JOIN users u ON u.id = tp.user_id AND LOWER(u.username) = 'demo_teacher'
WHERE LOWER(qb.code) = 'demo_qb_java' AND LOWER(q.code) = 'demo_q_nf'
  AND NOT EXISTS (SELECT 1 FROM question_versions qv WHERE qv.question_id = q.id AND qv.version_number = 1);

-- question_options for SINGLE_CHOICE (correct = B @RestController)
INSERT INTO question_options (question_version_id, option_key, content, is_correct, position)
SELECT qv.id, v.option_key, v.content, v.is_correct, v.position
FROM question_versions qv
JOIN questions q ON q.id = qv.question_id
JOIN question_banks qb ON qb.id = q.question_bank_id
CROSS JOIN (VALUES
    ('A', '@Component',       FALSE, 0),
    ('B', '@RestController',  TRUE,  1),
    ('C', '@Service',         FALSE, 2),
    ('D', '@Repository',      FALSE, 3)
) AS v(option_key, content, is_correct, position)
WHERE LOWER(qb.code) = 'demo_qb_java' AND LOWER(q.code) = 'demo_q_sc' AND qv.version_number = 1
  AND NOT EXISTS (
      SELECT 1 FROM question_options qo
      WHERE qo.question_version_id = qv.id AND qo.option_key = v.option_key
  );

-- question_options for MULTIPLE_CHOICE (correct = A, B)
INSERT INTO question_options (question_version_id, option_key, content, is_correct, position)
SELECT qv.id, v.option_key, v.content, v.is_correct, v.position
FROM question_versions qv
JOIN questions q ON q.id = qv.question_id
JOIN question_banks qb ON qb.id = q.question_bank_id
CROSS JOIN (VALUES
    ('A', '@Component',       TRUE,  0),
    ('B', '@RestController',  TRUE,  1),
    ('C', '@GetMapping',      FALSE, 2),
    ('D', '@Transient',       FALSE, 3)
) AS v(option_key, content, is_correct, position)
WHERE LOWER(qb.code) = 'demo_qb_java' AND LOWER(q.code) = 'demo_q_mc' AND qv.version_number = 1
  AND NOT EXISTS (
      SELECT 1 FROM question_options qo
      WHERE qo.question_version_id = qv.id AND qo.option_key = v.option_key
  );

-- question_options for TRUE_FALSE_MATRIX (statements A-D; expected = T,F,T,F)
INSERT INTO question_options (question_version_id, option_key, content, is_correct, position)
SELECT qv.id, v.option_key, v.content, v.is_correct, v.position
FROM question_versions qv
JOIN questions q ON q.id = qv.question_id
JOIN question_banks qb ON qb.id = q.question_bank_id
CROSS JOIN (VALUES
    ('A', 'Java is a statically typed language.',          TRUE,  0),
    ('B', 'Spring Boot requires XML configuration.',       FALSE, 1),
    ('C', 'Hibernate is an ORM framework.',                TRUE,  2),
    ('D', 'PostgreSQL is a NoSQL database.',               FALSE, 3)
) AS v(option_key, content, is_correct, position)
WHERE LOWER(qb.code) = 'demo_qb_java' AND LOWER(q.code) = 'demo_q_tf' AND qv.version_number = 1
  AND NOT EXISTS (
      SELECT 1 FROM question_options qo
      WHERE qo.question_version_id = qv.id AND qo.option_key = v.option_key
  );
-- (NUMERIC_FILL has no options; the answer lives in question_versions.answer_key.)

-- ============================================================
-- BLOCK 4 — EXAM (published, immutable snapshot for grading)
--   1 exam -> 1 PUBLISHED version (total_points = 6.00) -> 1 section -> 4 questions.
--   exam_questions pin the source (question, version) for provenance & grading.
-- ============================================================

INSERT INTO exams (school_id, subject_id, owner_teacher_id, purpose_id, code, title, description, current_version_number, status, version)
SELECT s.id, subj.id, tp.id, p.id, 'DEMO_EXAM_JAVA', '[DEMO] Java Backend Quiz',
       '[DEMO] Demo quiz covering the 4 question types.', 1, 'READY', 0
FROM schools s
JOIN grade_levels gl      ON gl.school_id = s.id      AND LOWER(gl.code) = 'g12'
JOIN subjects subj        ON subj.school_id = s.id    AND subj.grade_level_id = gl.id AND LOWER(subj.code) = 'tin'
JOIN teacher_profiles tp  ON tp.school_id = s.id
JOIN users u              ON u.id = tp.user_id        AND LOWER(u.username) = 'demo_teacher'
LEFT JOIN exam_purposes p ON p.school_id = s.id       AND LOWER(p.code) = 'quiz'
WHERE LOWER(s.code) = 'demo-school'
  AND NOT EXISTS (
      SELECT 1 FROM exams e WHERE e.owner_teacher_id = tp.id AND LOWER(e.code) = 'demo_exam_java'
  );

-- Published exam version (total_points 6.00 > 0; published_at set -> PUBLISHED invariant).
INSERT INTO exam_versions (school_id, exam_id, version_number, title, instructions, duration_minutes, total_points, status, published_at, created_by)
SELECT s.id, e.id, 1, '[DEMO] Java Backend Quiz', '[DEMO] Answer all questions. Auto-graded on submit.', 30, 6.00, 'PUBLISHED', NOW() - INTERVAL '2 hours', u.id
FROM exams e
JOIN schools s            ON s.id = e.school_id       AND LOWER(s.code) = 'demo-school'
JOIN teacher_profiles tp  ON tp.id = e.owner_teacher_id
JOIN users u              ON u.id = tp.user_id        AND LOWER(u.username) = 'demo_teacher'
WHERE LOWER(e.code) = 'demo_exam_java'
  AND NOT EXISTS (SELECT 1 FROM exam_versions ev WHERE ev.exam_id = e.id AND ev.version_number = 1);

-- Single section (position 0) holding all 4 questions.
INSERT INTO exam_sections (exam_version_id, code, title, instructions, position)
SELECT ev.id, 'DEMO_SEC_1', '[DEMO] Part 1', NULL, 0
FROM exam_versions ev
JOIN exams e ON e.id = ev.exam_id AND LOWER(e.code) = 'demo_exam_java'
WHERE ev.version_number = 1
  AND NOT EXISTS (
      SELECT 1 FROM exam_sections es WHERE es.exam_version_id = ev.id AND es.position = 0
  );

-- exam_questions: snapshot pinned to (source_question_id, source_question_version_id).
-- SINGLE_CHOICE (position 0, points 1)
INSERT INTO exam_questions (exam_version_id, exam_section_id, source_question_id, source_question_version_id, question_code, question_type, content, default_points, difficulty, explanation, answer_key, metadata, position)
SELECT ev.id, es.id, q.id, qv.id, 'DEMO_Q_SC', 'SINGLE_CHOICE', qv.content, 1.00, qv.difficulty, qv.explanation, NULL, '{}'::jsonb, 0
FROM exam_versions ev
JOIN exams e          ON e.id = ev.exam_id       AND LOWER(e.code) = 'demo_exam_java'
JOIN exam_sections es ON es.exam_version_id = ev.id AND es.position = 0
JOIN question_banks qb ON qb.owner_teacher_id = e.owner_teacher_id AND LOWER(qb.code) = 'demo_qb_java'
JOIN questions q       ON q.question_bank_id = qb.id AND LOWER(q.code) = 'demo_q_sc'
JOIN question_versions qv ON qv.question_id = q.id AND qv.version_number = 1
WHERE ev.version_number = 1
  AND NOT EXISTS (SELECT 1 FROM exam_questions eq WHERE eq.exam_version_id = ev.id AND eq.source_question_id = q.id);

-- MULTIPLE_CHOICE (position 1, points 2)
INSERT INTO exam_questions (exam_version_id, exam_section_id, source_question_id, source_question_version_id, question_code, question_type, content, default_points, difficulty, explanation, answer_key, metadata, position)
SELECT ev.id, es.id, q.id, qv.id, 'DEMO_Q_MC', 'MULTIPLE_CHOICE', qv.content, 2.00, qv.difficulty, qv.explanation, NULL, '{}'::jsonb, 1
FROM exam_versions ev
JOIN exams e          ON e.id = ev.exam_id       AND LOWER(e.code) = 'demo_exam_java'
JOIN exam_sections es ON es.exam_version_id = ev.id AND es.position = 0
JOIN question_banks qb ON qb.owner_teacher_id = e.owner_teacher_id AND LOWER(qb.code) = 'demo_qb_java'
JOIN questions q       ON q.question_bank_id = qb.id AND LOWER(q.code) = 'demo_q_mc'
JOIN question_versions qv ON qv.question_id = q.id AND qv.version_number = 1
WHERE ev.version_number = 1
  AND NOT EXISTS (SELECT 1 FROM exam_questions eq WHERE eq.exam_version_id = ev.id AND eq.source_question_id = q.id);

-- TRUE_FALSE_MATRIX (position 2, points 2)
INSERT INTO exam_questions (exam_version_id, exam_section_id, source_question_id, source_question_version_id, question_code, question_type, content, default_points, difficulty, explanation, answer_key, metadata, position)
SELECT ev.id, es.id, q.id, qv.id, 'DEMO_Q_TF', 'TRUE_FALSE_MATRIX', qv.content, 2.00, qv.difficulty, qv.explanation, NULL, '{}'::jsonb, 2
FROM exam_versions ev
JOIN exams e          ON e.id = ev.exam_id       AND LOWER(e.code) = 'demo_exam_java'
JOIN exam_sections es ON es.exam_version_id = ev.id AND es.position = 0
JOIN question_banks qb ON qb.owner_teacher_id = e.owner_teacher_id AND LOWER(qb.code) = 'demo_qb_java'
JOIN questions q       ON q.question_bank_id = qb.id AND LOWER(q.code) = 'demo_q_tf'
JOIN question_versions qv ON qv.question_id = q.id AND qv.version_number = 1
WHERE ev.version_number = 1
  AND NOT EXISTS (SELECT 1 FROM exam_questions eq WHERE eq.exam_version_id = ev.id AND eq.source_question_id = q.id);

-- NUMERIC_FILL (position 3, points 1) — answer_key copied into the snapshot.
INSERT INTO exam_questions (exam_version_id, exam_section_id, source_question_id, source_question_version_id, question_code, question_type, content, default_points, difficulty, explanation, answer_key, metadata, position)
SELECT ev.id, es.id, q.id, qv.id, 'DEMO_Q_NF', 'NUMERIC_FILL', qv.content, 1.00, qv.difficulty, qv.explanation,
       '{"expectedAnswer":"1.00"}'::jsonb,
       '{}'::jsonb, 3
FROM exam_versions ev
JOIN exams e          ON e.id = ev.exam_id       AND LOWER(e.code) = 'demo_exam_java'
JOIN exam_sections es ON es.exam_version_id = ev.id AND es.position = 0
JOIN question_banks qb ON qb.owner_teacher_id = e.owner_teacher_id AND LOWER(qb.code) = 'demo_qb_java'
JOIN questions q       ON q.question_bank_id = qb.id AND LOWER(q.code) = 'demo_q_nf'
JOIN question_versions qv ON qv.question_id = q.id AND qv.version_number = 1
WHERE ev.version_number = 1
  AND NOT EXISTS (SELECT 1 FROM exam_questions eq WHERE eq.exam_version_id = ev.id AND eq.source_question_id = q.id);

-- exam_question_options mirror the source options (correctness snapshot for grading).
-- SINGLE_CHOICE options
INSERT INTO exam_question_options (exam_question_id, option_key, content, is_correct, position)
SELECT eq.id, v.option_key, v.content, v.is_correct, v.position
FROM exam_questions eq
JOIN exam_versions ev ON ev.id = eq.exam_version_id
JOIN exams e          ON e.id = ev.exam_id AND LOWER(e.code) = 'demo_exam_java'
CROSS JOIN (VALUES
    ('A', '@Component',       FALSE, 0),
    ('B', '@RestController',  TRUE,  1),
    ('C', '@Service',         FALSE, 2),
    ('D', '@Repository',      FALSE, 3)
) AS v(option_key, content, is_correct, position)
WHERE eq.question_type = 'SINGLE_CHOICE' AND eq.position = 0
  AND NOT EXISTS (
      SELECT 1 FROM exam_question_options eo WHERE eo.exam_question_id = eq.id AND eo.option_key = v.option_key
  );

-- MULTIPLE_CHOICE options
INSERT INTO exam_question_options (exam_question_id, option_key, content, is_correct, position)
SELECT eq.id, v.option_key, v.content, v.is_correct, v.position
FROM exam_questions eq
JOIN exam_versions ev ON ev.id = eq.exam_version_id
JOIN exams e          ON e.id = ev.exam_id AND LOWER(e.code) = 'demo_exam_java'
CROSS JOIN (VALUES
    ('A', '@Component',       TRUE,  0),
    ('B', '@RestController',  TRUE,  1),
    ('C', '@GetMapping',      FALSE, 2),
    ('D', '@Transient',       FALSE, 3)
) AS v(option_key, content, is_correct, position)
WHERE eq.question_type = 'MULTIPLE_CHOICE' AND eq.position = 1
  AND NOT EXISTS (
      SELECT 1 FROM exam_question_options eo WHERE eo.exam_question_id = eq.id AND eo.option_key = v.option_key
  );

-- TRUE_FALSE_MATRIX statements (expected T,F,T,F)
INSERT INTO exam_question_options (exam_question_id, option_key, content, is_correct, position)
SELECT eq.id, v.option_key, v.content, v.is_correct, v.position
FROM exam_questions eq
JOIN exam_versions ev ON ev.id = eq.exam_version_id
JOIN exams e          ON e.id = ev.exam_id AND LOWER(e.code) = 'demo_exam_java'
CROSS JOIN (VALUES
    ('A', 'Java is a statically typed language.',    TRUE,  0),
    ('B', 'Spring Boot requires XML configuration.', FALSE, 1),
    ('C', 'Hibernate is an ORM framework.',          TRUE,  2),
    ('D', 'PostgreSQL is a NoSQL database.',         FALSE, 3)
) AS v(option_key, content, is_correct, position)
WHERE eq.question_type = 'TRUE_FALSE_MATRIX' AND eq.position = 2
  AND NOT EXISTS (
      SELECT 1 FROM exam_question_options eo WHERE eo.exam_question_id = eq.id AND eo.option_key = v.option_key
  );
-- (NUMERIC_FILL exam_question has no options.)

-- ============================================================
-- BLOCK 5 — EXAM SESSION (OPEN now) + 3 PARTICIPANTS
-- Window covers now: starts_at = now-1d, ends_at = now+7d, opened_at = now-1h.
-- Owner = demo teacher. max_attempts = 1.
-- ============================================================

INSERT INTO exam_sessions (school_id, exam_version_id, owner_teacher_id, code, title, status, starts_at, ends_at, max_attempts, created_by, opened_at, version)
SELECT s.id, ev.id, tp.id, 'DEMO_SESS_JAVA', '[DEMO] Backend Quiz Session', 'OPEN',
       NOW() - INTERVAL '1 day', NOW() + INTERVAL '7 days', 1, u.id, NOW() - INTERVAL '1 hour', 0
FROM exam_versions ev
JOIN exams e           ON e.id = ev.exam_id      AND LOWER(e.code) = 'demo_exam_java'
JOIN schools s         ON s.id = e.school_id     AND LOWER(s.code) = 'demo-school'
JOIN teacher_profiles tp ON tp.id = e.owner_teacher_id
JOIN users u           ON u.id = tp.user_id      AND LOWER(u.username) = 'demo_teacher'
WHERE ev.version_number = 1 AND ev.status = 'PUBLISHED'
  AND NOT EXISTS (
      SELECT 1 FROM exam_sessions es WHERE es.owner_teacher_id = tp.id AND LOWER(es.code) = 'demo_sess_java'
  );

-- Add the 3 demo students as ELIGIBLE participants (added_by = demo teacher).
INSERT INTO exam_session_participants (school_id, exam_session_id, student_profile_id, status, added_by, version)
SELECT s.id, es.id, sp.id, 'ELIGIBLE', u.id, 0
FROM exam_sessions es
JOIN schools s         ON s.id = es.school_id       AND LOWER(s.code) = 'demo-school'
JOIN teacher_profiles tp ON tp.id = es.owner_teacher_id
JOIN users u           ON u.id = tp.user_id         AND LOWER(u.username) = 'demo_teacher'
JOIN student_profiles sp ON sp.school_id = s.id
JOIN users su          ON su.id = sp.user_id
WHERE LOWER(es.code) = 'demo_sess_java'
  AND LOWER(su.username) IN ('demo_student_01', 'demo_student_02', 'demo_student_03')
  AND NOT EXISTS (
      SELECT 1 FROM exam_session_participants p
      WHERE p.exam_session_id = es.id AND p.student_profile_id = sp.id
  );

-- ============================================================
-- BLOCK 5b — CLASSROOM + MEMBERS + SESSION VISIBILITY (V10)
--   Create a demo classroom owned by the demo teacher, add the 3 demo
--   students as members, set the demo session to CLASS_RESTRICTED, and
--   assign the classroom so the students can see/start the session via
--   class-based visibility (replaces the legacy participant gatekeeper).
-- ============================================================

-- Demo classroom (owned by demo_teacher, school-scoped).
INSERT INTO classrooms (school_id, owner_teacher_id, code, name, description, status)
SELECT s.id, tp.id, 'DEMO_CLS_JAVA', '[DEMO] Java Backend Class',
       '[DEMO] Classroom for the demo Java quiz session.', 'ACTIVE'
FROM schools s
JOIN teacher_profiles tp ON tp.school_id = s.id
JOIN users u ON u.id = tp.user_id AND LOWER(u.username) = 'demo_teacher'
WHERE LOWER(s.code) = 'demo-school'
  AND NOT EXISTS (
      SELECT 1 FROM classrooms c
      WHERE c.owner_teacher_id = tp.id AND LOWER(c.code) = 'demo_cls_java'
  );

-- Add the 3 demo students as classroom members (same-school enforced by composite FK).
INSERT INTO classroom_members (classroom_id, student_profile_id, school_id)
SELECT c.id, sp.id, s.id
FROM classrooms c
JOIN schools s ON s.id = c.school_id AND LOWER(s.code) = 'demo-school'
JOIN teacher_profiles tp ON tp.id = c.owner_teacher_id
JOIN users tu ON tu.id = tp.user_id AND LOWER(tu.username) = 'demo_teacher'
JOIN student_profiles sp ON sp.school_id = s.id
JOIN users su ON su.id = sp.user_id
WHERE LOWER(c.code) = 'demo_cls_java'
  AND LOWER(su.username) IN ('demo_student_01', 'demo_student_02', 'demo_student_03')
  AND NOT EXISTS (
      SELECT 1 FROM classroom_members cm
      WHERE cm.classroom_id = c.id AND cm.student_profile_id = sp.id
  );

-- Set the demo session to CLASS_RESTRICTED (safe default: only class members see it).
UPDATE exam_sessions
SET visibility = 'CLASS_RESTRICTED'
WHERE LOWER(code) = 'demo_sess_java'
  AND visibility <> 'CLASS_RESTRICTED';

-- Assign the demo classroom to the demo session (junction table).
INSERT INTO exam_session_classes (exam_session_id, classroom_id, school_id)
SELECT es.id, c.id, s.id
FROM exam_sessions es
JOIN schools s ON s.id = es.school_id AND LOWER(s.code) = 'demo-school'
JOIN classrooms c ON c.school_id = s.id AND LOWER(c.code) = 'demo_cls_java'
WHERE LOWER(es.code) = 'demo_sess_java'
  AND NOT EXISTS (
      SELECT 1 FROM exam_session_classes esc
      WHERE esc.exam_session_id = es.id AND esc.classroom_id = c.id
  );

-- ============================================================
-- BLOCK 6 — OPTIONAL: PRE-SUBMITTED RESULTS (Day 8 demo)
-- Two consistent, graded attempts so Results / Statistics / Excel export
-- work immediately without manually submitting:
--   demo_student_01 : all correct  -> score 6.00 / 6.00  = 100.0000 %
--   demo_student_02 : Q1+Q2 correct -> score 3.00 / 6.00  =  50.0000 %
--   demo_student_03 : (no attempt) — left for a LIVE submit during the demo.
--
-- Each attempt is internally consistent with the grading engine:
--   attempt (SUBMITTED) -> attempt_questions (4) -> attempt_answers (payload)
--                       -> grade (AUTO_GRADED)  -> grade_items (4)
--                       -> idempotency_record (ATTEMPT_SUBMIT, cached response).
-- attempt.status is SUBMITTED (the real post-submit state); the persisted
-- Grade.status is AUTO_GRADED. Results/statistics/export filter on
-- status IN ('SUBMITTED','GRADED'), so these appear correctly.
--
-- To SKIP pre-submitted results, comment out this whole block; the session
-- and participants above are enough for a live submit-based demo.
-- ============================================================

-- ---- 6.1 Student 1 : 100% (all correct) ----
INSERT INTO attempts (school_id, exam_session_id, student_profile_id, exam_version_id, attempt_number, status, started_at, deadline_at, submitted_at, last_saved_at, submission_idempotency_key)
SELECT s.id, es.id, sp.id, ev.id, 1, 'SUBMITTED',
       NOW() - INTERVAL '2 hours', NOW() + INTERVAL '6 hours',
       NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '31 minutes', 'demo-submit-stu01'
FROM exam_sessions es
JOIN schools s          ON s.id = es.school_id        AND LOWER(s.code) = 'demo-school'
JOIN exam_versions ev   ON ev.id = es.exam_version_id
JOIN student_profiles sp ON sp.school_id = s.id
JOIN users su           ON su.id = sp.user_id         AND LOWER(su.username) = 'demo_student_01'
WHERE LOWER(es.code) = 'demo_sess_java'
  AND NOT EXISTS (
      SELECT 1 FROM attempts a
      WHERE a.exam_session_id = es.id AND a.student_profile_id = sp.id AND a.attempt_number = 1
  );

-- attempt_questions for student 1 (order snapshot; option_order per type).
INSERT INTO attempt_questions (attempt_id, exam_question_id, question_type, default_points, display_order, option_order)
SELECT a.id, eq.id, eq.question_type, eq.default_points, eq.position,
       CASE WHEN eq.question_type = 'NUMERIC_FILL' THEN NULL ELSE '["A","B","C","D"]'::jsonb END
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN exam_versions ev ON ev.id = a.exam_version_id
JOIN exam_questions eq ON eq.exam_version_id = ev.id
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_01'
WHERE NOT EXISTS (
    SELECT 1 FROM attempt_questions aq WHERE aq.attempt_id = a.id AND aq.exam_question_id = eq.id
);

-- attempt_answers for student 1 (all answered, all correct).
-- SINGLE (B), MULTIPLE (A,B), TF (A=T,B=F,C=T,D=F), NUMERIC (1.00).
INSERT INTO attempt_answers (attempt_id, attempt_question_id, answer_payload, sequence_number, saved_at)
SELECT a.id, aq.id, v.payload, 1, NOW() - INTERVAL '31 minutes'
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_01'
JOIN attempt_questions aq ON aq.attempt_id = a.id
JOIN exam_questions eq ON eq.id = aq.exam_question_id
CROSS JOIN (VALUES
    (0, '{"selectedOptionKey":"B"}'::jsonb),
    (1, '{"selectedOptionKeys":["A","B"]}'::jsonb),
    (2, '{"responses":{"A":true,"B":false,"C":true,"D":false}}'::jsonb),
    (3, '{"value":"1.00"}'::jsonb)
) AS v(position, payload)
WHERE eq.position = v.position
  AND NOT EXISTS (
      SELECT 1 FROM attempt_answers an WHERE an.attempt_id = a.id AND an.attempt_question_id = aq.id
  );

-- grade for student 1: 6.00 / 6.00 = 100.0000 %
INSERT INTO grades (attempt_id, automatic_score, final_score, max_score, percentage, status, graded_at, released_at, graded_by)
SELECT a.id, 6.00, 6.00, 6.00, 100.0000, 'AUTO_GRADED', NOW() - INTERVAL '30 minutes', NULL, NULL
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_01'
WHERE NOT EXISTS (SELECT 1 FROM grades g WHERE g.attempt_id = a.id);

-- grade_items for student 1 (all correct: 1 + 2 + 2 + 1 = 6.00).
INSERT INTO grade_items (grade_id, attempt_id, attempt_question_id, awarded_points, max_points, is_correct, grading_details)
SELECT g.id, a.id, aq.id, v.awarded, v.maxpts, TRUE, '{}'::jsonb
FROM grades g
JOIN attempts a ON a.id = g.attempt_id
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_01'
JOIN attempt_questions aq ON aq.attempt_id = a.id
JOIN exam_questions eq ON eq.id = aq.exam_question_id
CROSS JOIN (VALUES
    (0, 1.00, 1.00),
    (1, 2.00, 2.00),
    (2, 2.00, 2.00),
    (3, 1.00, 1.00)
) AS v(position, awarded, maxpts)
WHERE eq.position = v.position
  AND NOT EXISTS (
      SELECT 1 FROM grade_items gi WHERE gi.grade_id = g.id AND gi.attempt_question_id = aq.id
  );

-- idempotency cache for student 1's submit (SubmitResponse snapshot).
INSERT INTO idempotency_records (user_id, attempt_id, operation, idempotency_key, response_status, response_body, expires_at)
SELECT su.id, a.id, 'ATTEMPT_SUBMIT', 'demo-submit-stu01', 200,
       jsonb_build_object(
           'attemptId', a.id,
           'status', 'SUBMITTED',
           'submittedAt', a.submitted_at,
           'serverTime', a.submitted_at,
           'attemptNumber', 1,
           'sessionId', a.exam_session_id,
           'score', 6.00,
           'maxScore', 6.00,
           'percentage', 100.00
       ), NULL
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_01'
WHERE NOT EXISTS (
    SELECT 1 FROM idempotency_records ir WHERE ir.attempt_id = a.id AND ir.operation = 'ATTEMPT_SUBMIT'
);

-- ---- 6.2 Student 2 : 50% (Q1 + Q2 correct, Q3 + Q4 wrong) ----
INSERT INTO attempts (school_id, exam_session_id, student_profile_id, exam_version_id, attempt_number, status, started_at, deadline_at, submitted_at, last_saved_at, submission_idempotency_key)
SELECT s.id, es.id, sp.id, ev.id, 1, 'SUBMITTED',
       NOW() - INTERVAL '2 hours', NOW() + INTERVAL '6 hours',
       NOW() - INTERVAL '20 minutes', NOW() - INTERVAL '21 minutes', 'demo-submit-stu02'
FROM exam_sessions es
JOIN schools s          ON s.id = es.school_id        AND LOWER(s.code) = 'demo-school'
JOIN exam_versions ev   ON ev.id = es.exam_version_id
JOIN student_profiles sp ON sp.school_id = s.id
JOIN users su           ON su.id = sp.user_id         AND LOWER(su.username) = 'demo_student_02'
WHERE LOWER(es.code) = 'demo_sess_java'
  AND NOT EXISTS (
      SELECT 1 FROM attempts a
      WHERE a.exam_session_id = es.id AND a.student_profile_id = sp.id AND a.attempt_number = 1
  );

INSERT INTO attempt_questions (attempt_id, exam_question_id, question_type, default_points, display_order, option_order)
SELECT a.id, eq.id, eq.question_type, eq.default_points, eq.position,
       CASE WHEN eq.question_type = 'NUMERIC_FILL' THEN NULL ELSE '["A","B","C","D"]'::jsonb END
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN exam_versions ev ON ev.id = a.exam_version_id
JOIN exam_questions eq ON eq.exam_version_id = ev.id
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_02'
WHERE NOT EXISTS (
    SELECT 1 FROM attempt_questions aq WHERE aq.attempt_id = a.id AND aq.exam_question_id = eq.id
);

-- attempt_answers for student 2: Q1 (B) correct, Q2 (A,B) correct, Q3 wrong (flipped), Q4 wrong (2.50).
INSERT INTO attempt_answers (attempt_id, attempt_question_id, answer_payload, sequence_number, saved_at)
SELECT a.id, aq.id, v.payload, 1, NOW() - INTERVAL '21 minutes'
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_02'
JOIN attempt_questions aq ON aq.attempt_id = a.id
JOIN exam_questions eq ON eq.id = aq.exam_question_id
CROSS JOIN (VALUES
    (0, '{"selectedOptionKey":"B"}'::jsonb),
    (1, '{"selectedOptionKeys":["A","B"]}'::jsonb),
    (2, '{"responses":{"A":false,"B":true,"C":false,"D":true}}'::jsonb),
    (3, '{"value":"2.50"}'::jsonb)
) AS v(position, payload)
WHERE eq.position = v.position
  AND NOT EXISTS (
      SELECT 1 FROM attempt_answers an WHERE an.attempt_id = a.id AND an.attempt_question_id = aq.id
  );

-- grade for student 2: 3.00 / 6.00 = 50.0000 %
INSERT INTO grades (attempt_id, automatic_score, final_score, max_score, percentage, status, graded_at, released_at, graded_by)
SELECT a.id, 3.00, 3.00, 6.00, 50.0000, 'AUTO_GRADED', NOW() - INTERVAL '20 minutes', NULL, NULL
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_02'
WHERE NOT EXISTS (SELECT 1 FROM grades g WHERE g.attempt_id = a.id);

-- grade_items for student 2: Q1 correct(1), Q2 correct(2), Q3 wrong(0), Q4 wrong(0) = 3.00.
INSERT INTO grade_items (grade_id, attempt_id, attempt_question_id, awarded_points, max_points, is_correct, grading_details)
SELECT g.id, a.id, aq.id, v.awarded, v.maxpts, v.correct, '{}'::jsonb
FROM grades g
JOIN attempts a ON a.id = g.attempt_id
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_02'
JOIN attempt_questions aq ON aq.attempt_id = a.id
JOIN exam_questions eq ON eq.id = aq.exam_question_id
CROSS JOIN (VALUES
    (0, 1.00, 1.00, TRUE),
    (1, 2.00, 2.00, TRUE),
    (2, 0.00, 2.00, FALSE),
    (3, 0.00, 1.00, FALSE)
) AS v(position, awarded, maxpts, correct)
WHERE eq.position = v.position
  AND NOT EXISTS (
      SELECT 1 FROM grade_items gi WHERE gi.grade_id = g.id AND gi.attempt_question_id = aq.id
  );

-- idempotency cache for student 2's submit.
INSERT INTO idempotency_records (user_id, attempt_id, operation, idempotency_key, response_status, response_body, expires_at)
SELECT su.id, a.id, 'ATTEMPT_SUBMIT', 'demo-submit-stu02', 200,
       jsonb_build_object(
           'attemptId', a.id,
           'status', 'SUBMITTED',
           'submittedAt', a.submitted_at,
           'serverTime', a.submitted_at,
           'attemptNumber', 1,
           'sessionId', a.exam_session_id,
           'score', 3.00,
           'maxScore', 6.00,
           'percentage', 50.00
       ), NULL
FROM attempts a
JOIN exam_sessions es ON es.id = a.exam_session_id AND LOWER(es.code) = 'demo_sess_java'
JOIN student_profiles sp ON sp.id = a.student_profile_id
JOIN users su ON su.id = sp.user_id AND LOWER(su.username) = 'demo_student_02'
WHERE NOT EXISTS (
    SELECT 1 FROM idempotency_records ir WHERE ir.attempt_id = a.id AND ir.operation = 'ATTEMPT_SUBMIT'
);

-- ============================================================
-- END — single atomic commit. If any statement fails, nothing is written.
-- ============================================================
COMMIT;
