# Hướng dẫn chạy Quizopia từ đầu

## 1. Chuẩn bị môi trường

### Yêu cầu bắt buộc:
- **Java 21+** (OpenJDK hoặc Oracle JDK)
- **Node.js 22+** (cho frontend)
- **Maven 3.9+** (hoặc dùng mvnw đi kèm)
- **Docker Desktop** (cho PostgreSQL, Redis, MinIO)

### Kiểm tra version:
```bash
java -version
node -version
docker --version
```

## 2. Clone repository (nếu chưa có)

```bash
git clone <your-repo-url>
cd quizopia-system
```

## 3. Khởi động Database với Docker Compose

```bash
# Từ thư mục gốc của dự án
docker-compose up -d postgres-db redis-cache minio mailpit
```

Kiểm tra containers đang chạy:
```bash
docker ps
```

Bạn nên thấy:
- `quizopia_postgres` (port 5432)
- `quizopia_redis` (port 6379)
- `quizopia_minio` (ports 9000, 9001)
- `quizopia_mailpit` (ports 8025, 1025)

## 4. Chạy Backend

### Cách 1: Chạy trực tiếp (推荐 cho development)

```bash
cd backend

# Chạy application (sử dụng application.properties với PostgreSQL thật)
./mvnw.cmd spring-boot:run

# Hoặc trên Linux/Mac:
./mvnw spring-boot:run
```

Backend sẽ chạy ở: `http://localhost:8080`

### Cách 2: Package và chạy JAR

```bash
cd backend

# Build JAR
./mvnw.cmd clean package -DskipTests

# Chạy JAR
java -jar target/backend-0.0.1-SNAPSHOT.jar
```

### Kiểm tra Backend health:

```bash
curl http://localhost:8080/actuator/health
```

Phản hồi mong đợi:
```json
{"status":"UP"}
```

## 5. Chạy Frontend

```bash
cd frontend

# Cài đặt dependencies (lần đầu)
npm install

# Chạy development server
npm run dev
```

Frontend sẽ chạy ở: `http://localhost:3000`

## 6. Chạy Test

### Test Backend:

```bash
cd backend

# Chạy tất cả tests
./mvnw.cmd test

# Chạy specific test
./mvnw.cmd test -Dtest=QuizopiaBackendApplicationTests
```

Test sẽ sử dụng H2 in-memory database (không cần PostgreSQL).

### Test Frontend:

```bash
cd frontend

npm run lint
```

## 7. Docker Compose đầy đủ (Optional)

Nếu muốn chạy toàn bộ hệ thống bằng Docker:

```bash
# Build và chạy tất cả services
docker-compose up --build

# Hoặc chạy ở background
docker-compose up --build -d
```

Truy cập:
- Frontend: `http://localhost:3000`
- Backend: `http://localhost:8080`
- MinIO Console: `http://localhost:9001`
- Mailpit: `http://localhost:8025`

## 8. Cấu trúc Project

```
quizopia-system/
├── backend/               # Spring Boot application
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/      # Source code
│   │   │   └── resources/ # Config files
│   │   └── test/          # Tests (sử dụng H2)
│   ├── pom.xml
│   └── mvnw.cmd           # Maven wrapper
│
├── frontend/              # Next.js application
│   ├── src/
│   ├── package.json
│   └── next.config.ts
│
├── docs/                  # Documentation
├── docker-compose.yml
└── README.md
```

## 9. Khắc phục sự cố

### Backend không kết nối được Database:

Kiểm tra PostgreSQL đang chạy:
```bash
docker ps | grep postgres
```

Nếu không chạy:
```bash
docker-compose up -d postgres-db
```

### Test failed với lỗi "Failed to determine driver class":

Đã được fix! Test sẽ tự động sử dụng H2 database. Nếu vẫn lỗi:
```bash
cd backend
./mvnw.cmd clean test
```

### Port conflicts:

Nếu ports bị chiếm:
- 3000: Frontend
- 8080: Backend
- 5432: PostgreSQL
- 6379: Redis
- 9000/9001: MinIO
- 8025: Mailpit

Sử dụng `docker-compose down` để dừng tất cả containers.

## 10. Development Workflow

1. **Môi trường Development**:
   ```bash
   # Terminal 1: Database
   docker-compose up -d postgres-db redis-cache

   # Terminal 2: Backend
   cd backend
   ./mvnw.cmd spring-boot:run

   # Terminal 3: Frontend
   cd frontend
   npm run dev
   ```

2. **Sau khi sửa code**:
   - Backend: Spring Boot sẽ auto-reload
   - Frontend: Next.js sẽ hot-reload

3. **Trước khi commit**:
   ```bash
   # Test backend
   cd backend && ./mvnw.cmd test

   # Lint frontend
   cd frontend && npm run lint
   ```

## 11. Environment Variables

Backend application.properties đã có defaults cho development:

```properties
# Database
DB_URL=jdbc:postgresql://localhost:5432/quizopia_db
DB_USERNAME=quiz_user
DB_PASSWORD=quiz_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis_password
```

Không cần config thêm cho development.

## 12. URLs quan trọng

| Service | URL | Username/Password |
|---------|-----|-------------------|
| Backend API | http://localhost:8080/api/v1 | - |
| Health Check | http://localhost:8080/actuator/health | - |
| Frontend | http://localhost:3000 | - |
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin123 |
| Mailpit | http://localhost:8025 | - |
| PostgreSQL | localhost:5432 | quiz_user / quiz_password |
| Redis | localhost:6379 | Password: redis_password |
