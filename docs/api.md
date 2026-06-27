# API Documentation - Quizopia

## 1. Tổng quan

- **Base URL**: `http://localhost:8080/api/v1`
- **Content-Type**: `application/json`
- **Authentication**: Bearer JWT (HttpOnly cookie)
- **Version**: v1

## 2. Authentication

### 2.1 Login

Đăng nhập với username/password.

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "teacher001",
  "password": "password123"
}
```

**Response:**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 900
  },
  "message": "Login successful"
}
```

**Headers:**
- `Set-Cookie`: `refresh_token=<opaque_token>; HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth/refresh`

### 2.2 Refresh Token

Làm mới access token.

```http
POST /api/v1/auth/refresh
Cookie: refresh_token=<opaque_token>
```

**Response:**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 900
  }
}
```

### 2.3 Logout

```http
POST /api/v1/auth/logout
Cookie: refresh_token=<opaque_token>
```

**Response:**
```json
{
  "message": "Logout successful"
}
```

### 2.4 Get Current User

```http
GET /api/v1/users/me
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "username": "teacher001",
    "email": "teacher@example.com",
    "fullName": "Nguyễn Văn A",
    "roles": ["TEACHER"],
    "avatarUrl": null
  }
}
```

## 3. Academic Module

### 3.1 Semesters

**Create Semester (TEACHER+)**
```http
POST /api/v1/semesters
Authorization: Bearer <access_token>

{
  "semesterName": "2024-1",
  "startDate": "2024-09-01",
  "endDate": "2025-01-31"
}
```

**Get All Semesters**
```http
GET /api/v1/semesters
```

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "semesterName": "2024-1",
      "startDate": "2024-09-01",
      "endDate": "2025-01-31",
      "status": "ONGOING"
    }
  ]
}
```

### 3.2 Courses

**Create Course (TEACHER+)**
```http
POST /api/v1/courses
Authorization: Bearer <access_token>

{
  "courseCode": "CS101",
  "courseName": "Introduction to Computer Science",
  "semesterId": 1
}
```

**Get My Courses (TEACHER)**
```http
GET /api/v1/courses/my
Authorization: Bearer <access_token>
```

**Get My Courses (STUDENT)**
```http
GET /api/v1/courses/enrolled
Authorization: Bearer <access_token>
```

**Enroll Student (TEACHER)**
```http
POST /api/v1/courses/{courseId}/enroll
Authorization: Bearer <access_token>

{
  "studentIds": [10, 11, 12]
}
```

## 4. Question Module

### 4.1 Question Banks

**Create Question Bank (TEACHER)**
```http
POST /api/v1/question-banks
Authorization: Bearer <access_token>

{
  "bankName": "CS101 - Midterm Questions",
  "isPublic": false
}
```

**Get My Question Banks**
```http
GET /api/v1/question-banks/my
Authorization: Bearer <access_token>
```

### 4.2 Questions

**Create Question (TEACHER)**
```http
POST /api/v1/questions
Authorization: Bearer <access_token>

{
  "bankId": 1,
  "questionType": "SINGLE_CHOICE",
  "content": "Câu hỏi 1 + 1 = ?",
  "options": ["1", "2", "3", "4"],
  "correctAnswer": "\"2\"",
  "explanation": "1 + 1 = 2",
  "difficulty": "EASY",
  "tags": ["math", "basic"]
}
```

**Import Questions from Excel (TEACHER)**
```http
POST /api/v1/questions/import
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

bankId: 1
file: <excel_file>
```

**Response:**
```json
{
  "data": {
    "total": 50,
    "valid": 45,
    "invalid": 5,
    "invalidRows": [
      {
        "row": 3,
        "reason": "Missing question content"
      }
    ]
  }
}
```

**Get Questions in Bank**
```http
GET /api/v1/question-banks/{bankId}/questions?page=0&size=20&type=SINGLE_CHOICE
Authorization: Bearer <access_token>
```

**Update Question (Owner only)**
```http
PUT /api/v1/questions/{questionId}
Authorization: Bearer <access_token>

{
  "content": "Updated content",
  "options": ["A", "B", "C"],
  "correctAnswer": "\"A\""
}
```

## 5. Exam Module

### 5.1 Exams

**Create Exam (TEACHER)**
```http
POST /api/v1/exams
Authorization: Bearer <access_token>

{
  "courseId": 1,
  "examName": "Midterm Exam",
  "description": "Midterm examination for CS101",
  "durationMinutes": 60,
  "startTime": "2024-10-15T10:00:00",
  "endTime": "2024-10-15T11:00:00",
  "passingScore": 50.0,
  "shuffleQuestions": true,
  "showResult": false
}
```

**Add Questions to Exam (TEACHER)**
```http
POST /api/v1/exams/{examId}/questions
Authorization: Bearer <access_token>

{
  "questions": [
    {
      "questionId": 10,
      "points": 5.0
    },
    {
      "questionId": 11,
      "points": 5.0
    }
  ]
}
```

**Get Course Exams (STUDENT)**
```http
GET /api/v1/courses/{courseId}/exams
Authorization: Bearer <access_token>
```

**Get Exam Detail (with questions if started)**
```http
GET /api/v1/exams/{examId}
Authorization: Bearer <access_token>
```

**Publish Exam (TEACHER)**
```http
POST /api/v1/exams/{examId}/publish
Authorization: Bearer <access_token>
```

## 6. Attempt Module

### 6.1 Start Exam

**Start Exam Attempt (STUDENT)**
```http
POST /api/v1/attempts
Authorization: Bearer <access_token>

{
  "examId": 1
}
```

**Response:**
```json
{
  "data": {
    "attemptId": 100,
    "examId": 1,
    "startTime": "2024-10-15T10:05:00",
    "durationMinutes": 60,
    "questions": [
      {
        "examQuestionId": 1001,
        "orderIndex": 1,
        "questionType": "SINGLE_CHOICE",
        "content": "Question content",
        "options": ["A", "B", "C", "D"],
        "points": 5.0
      }
    ]
  }
}
```

### 6.2 Autosave Answer

**Save Answer (STUDENT)**
```http
PUT /api/v1/attempts/{attemptId}/answers
Authorization: Bearer <access_token>

{
  "examQuestionId": 1001,
  "answer": "\"B\"",
  "isMarked": false
}
```

**Response:**
```json
{
  "data": {
    "success": true,
    "savedAt": "2024-10-15T10:10:00"
  }
}
```

### 6.3 Submit Exam

**Submit Exam (Idempotent) (STUDENT)**
```http
POST /api/v1/attempts/{attemptId}/submit
Authorization: Bearer <access_token>

{
  "submissionKey": "<unique-key>"  // Optional, for idempotency
}
```

**Response:**
```json
{
  "data": {
    "attemptId": 100,
    "submitTime": "2024-10-15T10:55:00",
    "status": "SUBMITTED",
    "score": null
  }
}
```

**Get Attempt Result (STUDENT)**
```http
GET /api/v1/attempts/{attemptId}
Authorization: Bearer <access_token>
```

### 6.4 Get My Attempts

```http
GET /api/v1/attempts/my?examId=1
Authorization: Bearer <access_token>
```

## 7. Monitoring Module (WebSocket)

### 7.1 Connect to Exam Monitoring

**WebSocket Endpoint:**
```
ws://localhost:8080/ws/exam/{examId}/monitor
```

**Headers:**
- `Cookie`: `refresh_token=<token>` or Bearer in query

**Subscribe:**
```javascript
// STOMP
stompClient.subscribe('/topic/exam/' + examId + '/monitor', (message) => {
  const data = JSON.parse(message.body);
  // {
  //   "studentId": 10,
  //   "fullName": "Nguyễn Văn B",
  //   "status": "IN_PROGRESS",
  //   "answeredCount": 5,
  //   "totalCount": 10,
  //   "lastActivity": "2024-10-15T10:30:00"
  // }
});
```

## 8. Reporting Module

### 8.1 Exam Statistics (TEACHER)

```http
GET /api/v1/exams/{examId}/statistics
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "data": {
    "totalStudents": 30,
    "submittedCount": 25,
    "averageScore": 75.5,
    "passCount": 22,
    "failCount": 3,
    "scoreDistribution": [
      { "range": "0-20", "count": 1 },
      { "range": "20-40", "count": 2 },
      { "range": "40-60", "count": 5 },
      { "range": "60-80", "count": 10 },
      { "range": "80-100", "count": 7 }
    ]
  }
}
```

### 8.2 Export Results (TEACHER)

```http
GET /api/v1/exams/{examId}/export
Authorization: Bearer <access_token>
Accept: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
```

## 9. Error Responses

### 9.1 Error Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Email is required"
      }
    ]
  },
  "timestamp": "2024-10-15T10:00:00",
  "path": "/api/v1/auth/login"
}
```

### 9.2 HTTP Status Codes

| Code | Description                   |
| ---- | ----------------------------- |
| 200  | Success                       |
| 201  | Created                       |
| 204  | No Content                    |
| 400  | Bad Request                   |
| 401  | Unauthorized                  |
| 403  | Forbidden                     |
| 404  | Not Found                     |
| 409  | Conflict (duplicate resource) |
| 422  | Validation Error              |
| 429  | Too Many Requests             |
| 500  | Internal Server Error         |

### 9.3 Error Codes

| Code                       | Description                  |
| -------------------------- | ---------------------------- |
| `AUTH_INVALID_CREDENTIALS` | Username/password không đúng |
| `AUTH_TOKEN_EXPIRED`       | Access token hết hạn         |
| `AUTH_REFRESH_INVALID`     | Refresh token không hợp lệ   |
| `VALIDATION_ERROR`         | Validation lỗi               |
| `RESOURCE_NOT_FOUND`       | Resource không tồn tại       |
| `ACCESS_DENIED`            | Không có quyền truy cập      |
| `EXAM_ALREADY_STARTED`     | Đã bắt đầu làm bài           |
| `EXAM_ALREADY_SUBMITTED`   | Đã nộp bài                   |
| `EXAM_NOT_ACTIVE`          | Exam chưa/không active       |
| `QUESTION_NOT_IN_EXAM`     | Câu hỏi không trong đề       |

## 10. Rate Limiting

| Endpoint                   | Limit              |
| -------------------------- | ------------------ |
| POST /auth/login           | 10 requests/minute |
| POST /auth/refresh         | 30 requests/minute |
| PUT /attempts/{id}/answers | 10 requests/second |
| POST /attempts/{id}/submit | 5 requests/minute  |

## 11. Pagination

**Request:**
```http
GET /api/v1/questions?page=0&size=20&sort=createdAt,desc
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "page": 0,
    "size": 20,
    "totalElements": 150,
    "totalPages": 8,
    "first": true,
    "last": false
  }
}
```

## 12. File Upload

**Import Excel Template:**
```http
GET /api/v1/questions/template
Accept: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
```

**Template Format:**
| Question Type | Content | Option A | Option B | Option C | Option D | Correct | Points | Difficulty | Tags |
| ------------- | ------- | -------- | -------- | -------- | -------- | ------- | ------ | ---------- | ---- |
| SINGLE_CHOICE | 1+1=?   | 1        | 2        | 3        | 4        | B       | 5      | EASY       | math |
