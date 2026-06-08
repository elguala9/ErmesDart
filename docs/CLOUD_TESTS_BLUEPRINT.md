# Cloud Tests Blueprint - ErmesDart

**Goal**: Run OrcErmes integration tests against cloud-deployed signaling servers (Render + Koyeb) without mocks. Tests run locally and connect to remote instances.

---

## 📐 Architecture Overview

```
Local Developer Machine
├── dart test <test_file>
│   └── Connects to → Remote Signaling Server (Render)
│       │
│       └── Tests OrcErmes message exchange
│
└── Deploy to Docker Hub
    ├── Render pulls image
    └── Koyeb pulls image
```

---

## 🐳 Docker Strategy

### **Single Dockerfile** (`Dockerfile.cloud`)

```dockerfile
# Multi-stage for signaling server deployment
FROM dart:latest AS builder
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get
COPY . .
RUN dart pub get --offline

FROM dart:latest
WORKDIR /app
COPY --from=builder /app /app
EXPOSE 8080
ENV PORT=8080
CMD ["dart", "run", "packages/ermes_signaling/bin/server.dart"]
```

### **Docker Hub Registry**
- **Repository**: `lgualandi/ermes-dart-signaling:latest`
- **Build Trigger**: Manual (before testing) or GitHub Actions (on commit)
- **Tags Strategy**:
  - `latest` - Production ready
  - `test-YYYYMMDD` - Timestamped test builds
  - `v1.0.0` - Release versions

### **Build & Push Script** (`scripts/push-docker-hub.sh`)
```bash
#!/bin/bash
# Builds local, tags, and pushes to Docker Hub
docker build -f Dockerfile.cloud -t lgualandi/ermes-dart-signaling:latest .
docker push lgualandi/ermes-dart-signaling:latest
echo "✅ Pushed to Docker Hub"
```

---

## 🌐 Cloud Deployment Configuration

### **Render Configuration** (`render.yaml`)
```yaml
services:
  - type: web
    name: ermes-signaling-test
    image: lgualandi/ermes-dart-signaling:latest
    plan: free
    region: frankfurt
    healthCheckPath: /health
    envVars:
      - key: PORT
        value: 8080
      - key: LOG_LEVEL
        value: debug
```

### **Koyeb Configuration** (`koyeb.yaml`)
```yaml
version: 1
services:
  - name: ermes-signaling-test
    docker:
      image: lgualandi/ermes-dart-signaling:latest
    ports:
      - port: 8080
        protocol: http
    regions:
      - fra
    scaling:
      min_instances: 1
      max_instances: 1
    env:
      - name: PORT
        value: "8080"
      - name: LOG_LEVEL
        value: debug
```

---

## 🧪 Test Architecture

### **Test Flow**

```
1. Local Setup
   ├── Start local signaling server
   └── Get server address

2. Deploy to Cloud
   ├── Push Docker image to Docker Hub
   ├── Deploy to Render (or Koyeb)
   └── Wait for health check (/health endpoint)

3. Run Tests Locally
   ├── Connect to remote signaling server
   ├── Create two peers (Alice, Bob)
   ├── Exchange OrcErmes messages
   ├── Verify encryption/decryption
   └── Assert message receipt

4. Cleanup
   └── (Optional) Tear down cloud instance
```

### **Test File Structure**

```
packages/ermes_test/test/
├── integration/
│   ├── cloud_tests_base.dart          (Base class + utilities)
│   └── orcermes_cloud_exchange_test.dart   (Main test suite)
└── fixtures/
    └── cloud_config.dart              (Config URLs, timeouts)
```

### **Key Test Components**

#### **cloud_tests_base.dart**
- Abstract base class with setup/teardown
- Methods:
  - `waitForCloudServer()` - Retry logic for cloud endpoint
  - `createRemoteSignalingHandler()` - Connect to cloud server
  - `createOrcErmesInstance()` - Create peer with remote handler
  - `expectMessageReceived()` - Assert with timeout

#### **orcermes_cloud_exchange_test.dart**
Test cases:
```
1. Cloud Server Connectivity
   ├── Can connect to remote signaling server
   ├── Health check endpoint responds
   └── Correct contract address retrieved

2. Two-Peer Message Exchange
   ├── Alice creates OrcErmes instance
   ├── Bob creates OrcErmes instance
   ├── Alice sends message to Bob
   ├── Bob receives + decrypts message
   └── Bob replies to Alice

3. Multi-Message Sequence
   ├── 5 rapid messages Alice → Bob
   ├── 5 messages Bob → Alice (concurrent)
   ├── All messages received in order
   └── No message loss

4. Encryption Verification
   ├── Message encrypted before transmission
   ├── Cipher key exchange verified
   ├── Decryption produces original payload
   └── Invalid keys rejected

5. Cleanup & Idempotency
   ├── Peers cleanup without errors
   ├── Connection state cleared
   └── Repeated tests don't interfere
```

---

## 🚀 Test Execution Workflow

### **For Developer (Local)**

```bash
# 1. Deploy to cloud (first time only, or on code changes)
scripts/push-docker-hub.sh
# Then manual deploy to Render/Koyeb via web UI, or:
# fly deploy (Fly.io) / koyeb deploy (Koyeb)

# 3. Point tests to cloud server
export SIGNALING_SERVER_URL=https://ermes-signaling-test.onrender.com  # Render
# OR
export SIGNALING_SERVER_URL=https://ermes-signaling-test.koyeb.app     # Koyeb

# 4. Run cloud integration tests
dart test packages/ermes_test/test/integration/orcermes_cloud_exchange_test.dart

# 5. Verify results
# Output:
# ✅ All tests passed
# 📊 Message latency: avg 120ms
# 🔐 Encryption verified


```

### **Configuration via Environment Variables**

```bash
# .env.cloud (not committed)
SIGNALING_SERVER_URL=https://ermes-signaling-test.onrender.com
SIGNALING_SERVER_TIMEOUT_MS=30000
LOG_LEVEL=debug
SKIP_CLOUD_TESTS=false  # For CI/CD conditional execution
```

---

## 📋 Deployment Checklist

### **First-Time Setup**

- [ ] Docker Hub account created
- [ ] Docker image built locally and tested
- [ ] Image pushed to `lgualandi/ermes-dart-signaling:latest`
- [ ] Render account created, linked to Docker Hub
- [ ] Koyeb account created, linked to Docker Hub
- [ ] `render.yaml` configured with correct image
- [ ] `koyeb.yaml` configured with correct image
- [ ] Both services deployed (at least one for testing)
- [ ] Health endpoint (`/health`) implemented in signaling server
- [ ] Cloud URLs noted and added to `.env.cloud`

### **Before Each Test Run**

- [ ] Docker image updated (if code changed)
- [ ] Cloud server responding to health check
- [ ] `SIGNALING_SERVER_URL` environment variable set
- [ ] Network connectivity verified (can ping cloud server)

---

## 🔧 Implementation Tasks

### **Phase 1: Docker & Registry**
- [ ] Create `Dockerfile.cloud` (signaling server only)
- [ ] Build and test Docker image locally
- [ ] Create Docker Hub account and push image
- [ ] Verify image pulls and runs correctly

### **Phase 2: Cloud Deployment**
- [ ] Create `render.yaml` with Docker Hub image reference
- [ ] Create `koyeb.yaml` with Docker Hub image reference
- [ ] Deploy to Render (or Koyeb first)
- [ ] Add `/health` endpoint to signaling server
- [ ] Verify cloud instance runs and responds

### **Phase 3: Test Infrastructure**
- [ ] Create `cloud_tests_base.dart` with base class
- [ ] Implement `waitForCloudServer()` with retry logic
- [ ] Create `cloud_config.dart` for config management
- [ ] Write `orcermes_cloud_exchange_test.dart` suite

### **Phase 4: Integration & CI/CD**
- [ ] Test manual execution workflow
- [ ] Create `push-docker-hub.sh` script
- [ ] Document environment variable setup
- [ ] (Optional) GitHub Actions workflow for auto-deploy
- [ ] Update CLAUDE.md with cloud testing guide

---

## 📊 Expected Results

### **Test Output**
```
Running: packages/ermes_test/test/integration/orcermes_cloud_exchange_test.dart
✓ Cloud Server Connectivity (8.2s)
  ✓ Can connect to remote signaling server
  ✓ Health check endpoint responds
  ✓ Correct contract address retrieved

✓ Two-Peer Message Exchange (12.4s)
  ✓ Alice creates OrcErmes instance
  ✓ Bob creates OrcErmes instance
  ✓ Alice sends message to Bob
  ✓ Bob receives + decrypts message
  ✓ Bob replies to Alice

✓ Multi-Message Sequence (18.7s)
  ✓ 5 rapid messages Alice → Bob
  ✓ 5 messages Bob → Alice (concurrent)
  ✓ All messages received in order
  ✓ No message loss

✓ Encryption Verification (9.3s)
  ✓ Message encrypted before transmission
  ✓ Cipher key exchange verified
  ✓ Decryption produces original payload
  ✓ Invalid keys rejected

✓ Cleanup & Idempotency (5.1s)
  ✓ Peers cleanup without errors
  ✓ Connection state cleared
  ✓ Repeated tests don't interfere

All 18 tests passed! (53.7s)
📊 Average message latency: 145ms
🌐 Cloud region: frankfurt (Render)
✅ Test suite complete
```

### **Metrics Tracked**
- Message latency (p50, p95, p99)
- Encryption overhead
- Connection time to cloud server
- Message delivery rate (%)
- Test execution time

---

## 🛡️ Failure Scenarios & Recovery

| Scenario | Detection | Recovery |
|----------|-----------|----------|
| Cloud server down | Health check fails | Retry with exponential backoff (3x) |
| Network timeout | `SocketException` | Skip cloud tests, run local only |

| Message not received | Timeout waiting for callback | Fail test, log remote server logs |
| Docker image corrupt | Container crashes | Pull fresh image from Docker Hub |

---

## 🔒 Security Considerations

- **No credentials in Docker image** - Use env vars for config
- **No hardcoded URLs** - All config via `SIGNALING_SERVER_URL`
- **TLS/HTTPS** - Cloud providers provide automatic HTTPS
- **Contract address verification** - Tests assert expected contract address


---

## 📚 Related Documentation

- `CLAUDE.md` - Project guidelines (to be updated)
- `packages/ermes_signaling/README.md` - Signaling server details
- `packages/ermes_test/CLAUDE.md` - Testing guidelines
- Docker Hub docs: https://docs.docker.com/docker-hub/
- Render docs: https://render.com/docs
- Koyeb docs: https://www.koyeb.com/docs

---

## 🎯 Success Criteria

✅ **Docker Image**
- Builds without errors
- Runs signaling server on port 8080
- Health check endpoint works
- Pulls from Docker Hub in < 30s

✅ **Cloud Deployment**
- Instance starts in < 60s
- Responds to HTTP requests
- Handles multiple concurrent connections
- No crashes during test run

✅ **Tests**
- Connect to cloud server from local machine
- Successfully exchange OrcErmes messages
- Verify encryption/decryption works
- No flaky tests (100% pass rate)
- Complete in < 2 minutes

✅ **Workflow**
- Developer can run tests with one command
- Clear error messages if setup missing
- Reproducible results
- No manual cleanup needed

