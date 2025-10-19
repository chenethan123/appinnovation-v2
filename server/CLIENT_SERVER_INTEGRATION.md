# Client-Server Integration Guide

**Complete guide for integrating iOS/iPadOS clients with the FormulaQuizzer Server**

---

## 🌐 Integration Overview

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  iOS App (iPhone/iPad)                                       │
│  ├── Local Storage (Core Data)                              │
│  ├── Sync Manager (Background)                              │
│  └── API Service (Network)                                  │
│            ↕                                                 │
│       [HTTPS/JSON]                                           │
│            ↕                                                 │
│  FormulaQuizzer Server                                      │
│  ├── REST API (Express)                                     │
│  ├── Database (PostgreSQL)                                  │
│  └── AI Service (OpenAI)                                    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Synchronization Strategy

### Sync Architecture

**Three-Tier Synchronization**:

1. **Immediate Local Update**: User sees change instantly
2. **Queue for Sync**: Change queued in background
3. **Background Upload**: Sync happens asynchronously

### Sync Flow

```swift
User Action
    ↓
Local Update (Core Data)
    ↓
UI Updates Immediately
    ↓
Queue Sync Operation
    ↓
[Background Thread]
    ↓
Upload to Server
    ↓
Server Response
    ↓
Update Local Cache
    ↓
Reconcile Conflicts
```

---

## 📡 API Integration Patterns

### 1. Subject Management

#### Creating a Subject

**iOS Code**:
```swift
func createSubject(name: String, description: String, color: String) async throws -> Subject {
    // 1. Create local entity immediately
    let localSubject = try coreDataManager.createLocalSubject(
        name: name,
        description: description,
        color: color,
        syncStatus: .pending
    )
    
    // 2. User sees subject immediately
    // UI updates with localSubject
    
    // 3. Background sync to server
    do {
        let response = try await apiService.createSubject(
            name: name,
            description: description,
            color: color
        )
        
        // 4. Update local entity with server ID
        try coreDataManager.updateSubject(
            localSubject.id,
            serverID: response.id,
            syncStatus: .synced
        )
        
        return localSubject
    } catch {
        // Mark as failed, will retry later
        try coreDataManager.updateSyncStatus(localSubject.id, to: .conflict)
        throw error
    }
}
```

**Server API Call**:
```http
POST /api/v1/subjects
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json

{
  "name": "AP Physics 1",
  "description": "College-level physics",
  "color": "#2196F3"
}
```

**Server Response**:
```json
{
  "id": 1,
  "name": "AP Physics 1",
  "description": "College-level physics",
  "color": "#2196F3",
  "created_at": "2025-10-13T09:00:00Z",
  "updated_at": "2025-10-13T09:00:00Z",
  "is_active": true,
  "total_questions": 0,
  "correct_answers": 0,
  "accuracy": 0.0
}
```

#### Fetching Subjects

**iOS Code**:
```swift
func fetchSubjects() async throws -> [Subject] {
    // 1. Check local cache first
    let cachedSubjects = try coreDataManager.fetchSubjects()
    
    // 2. Return cached data immediately
    if !cachedSubjects.isEmpty {
        // Start background sync
        Task.detached {
            try await self.syncSubjectsInBackground()
        }
        return cachedSubjects
    }
    
    // 3. No cache - fetch from server
    let response = try await apiService.fetchSubjects()
    
    // 4. Save to cache
    try coreDataManager.saveSubjects(response)
    
    return try coreDataManager.fetchSubjects()
}

private func syncSubjectsInBackground() async throws {
    let serverSubjects = try await apiService.fetchSubjects()
    let localSubjects = try coreDataManager.fetchSubjects()
    
    // Reconcile differences
    for serverSubject in serverSubjects {
        if let local = localSubjects.first(where: { $0.serverID == serverSubject.id }) {
            // Update existing
            try coreDataManager.updateSubject(from: serverSubject)
        } else {
            // Insert new
            try coreDataManager.insertSubject(from: serverSubject)
        }
    }
}
```

**Server API Call**:
```http
GET /api/v1/subjects?page=1&page_size=50
Authorization: Bearer YOUR_API_KEY
```

---

### 2. AI Question Generation

#### Generate Question with AI

**iOS Code**:
```swift
func generateQuestion(for subject: Subject, difficulty: String) async throws -> Question {
    // Show loading indicator
    await MainActor.run {
        isGenerating = true
    }
    
    defer {
        Task { @MainActor in
            isGenerating = false
        }
    }
    
    // Call server to generate question
    let response = try await apiService.generateQuestion(
        subjectId: subject.serverID!,
        difficulty: difficulty,
        numChoices: 4
    )
    
    // Save to local database
    let question = try coreDataManager.createQuestion(from: response, subjectID: subject.id)
    
    // Update subject question count
    try coreDataManager.incrementQuestionCount(for: subject.id)
    
    return question
}
```

**Server API Call**:
```http
POST /api/v1/ai/generate-question
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json

{
  "subject_id": 1,
  "difficulty": "medium",
  "num_choices": 4
}
```

**Server Response**:
```json
{
  "id": 42,
  "subject_id": 1,
  "question_text": "A 5kg block is pushed with 25N of force...",
  "options": ["10 N", "25 N", "50 N", "100 N"],
  "correct_answer": "25 N",
  "explanation": "Using F=ma with a=5m/s², F=5×5=25N",
  "difficulty": "medium",
  "is_from_ai": true,
  "generation_time_ms": 1850,
  "cache_hit": false
}
```

---

### 3. Quiz Session Management

#### Start Quiz Session

**iOS Code**:
```swift
func startQuiz(subject: Subject, questionCount: Int) async throws -> QuizSession {
    // 1. Create local session immediately
    let localSession = try coreDataManager.createQuizSession(
        subjectID: subject.id,
        questionCount: questionCount
    )
    
    // 2. Fetch questions (local or generate)
    let questions = try await fetchQuestionsForQuiz(
        subjectID: subject.id,
        count: questionCount
    )
    
    // 3. Associate questions with session
    try coreDataManager.addQuestions(questions, to: localSession.id)
    
    // 4. Background sync to server
    Task.detached {
        do {
            let serverSession = try await self.apiService.startQuizSession(
                subjectId: subject.serverID!,
                numQuestions: questionCount
            )
            
            try self.coreDataManager.updateQuizSession(
                localSession.id,
                serverID: serverSession.sessionID
            )
        } catch {
            print("Failed to sync quiz session: \(error)")
        }
    }
    
    return localSession
}
```

**Server API Call**:
```http
POST /api/v1/quiz/start
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json

{
  "subject_id": 1,
  "num_questions": 10,
  "difficulty": "medium"
}
```

#### Submit Answer

**iOS Code**:
```swift
func submitAnswer(sessionID: UUID, questionID: UUID, answer: String) async throws -> AnswerResult {
    // 1. Save answer locally immediately
    try coreDataManager.saveAnswer(
        sessionID: sessionID,
        questionID: questionID,
        answer: answer
    )
    
    // 2. Get question to check correctness
    let question = try coreDataManager.fetchQuestion(id: questionID)
    let isCorrect = (answer == question.correctAnswer)
    
    // 3. Update statistics locally
    if isCorrect {
        try coreDataManager.incrementCorrectAnswers(for: sessionID)
    }
    
    // 4. Background sync to server
    if let serverSessionID = try coreDataManager.getServerID(for: sessionID),
       let serverQuestionID = question.serverID {
        Task.detached {
            try await self.apiService.submitAnswer(
                sessionId: serverSessionID,
                questionId: serverQuestionID,
                userAnswer: answer
            )
        }
    }
    
    return AnswerResult(
        isCorrect: isCorrect,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation
    )
}
```

**Server API Call**:
```http
POST /api/v1/quiz/answer
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json

{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "question_id": 42,
  "user_answer": "25 N",
  "time_spent_seconds": 45
}
```

---

## 🔒 Authentication & Security

### API Key Management

**Storing API Key Securely**:

```swift
// In Settings View
func saveAPIKey(_ key: String) {
    do {
        try KeychainService.shared.saveAPIKey(key)
        // Update API service
        APIService.shared.updateAPIKey(key)
        showSuccess = true
    } catch {
        errorMessage = "Failed to save API key"
        showError = true
    }
}

// In KeychainService
func saveAPIKey(_ key: String) throws {
    let data = key.data(using: .utf8)!
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.formulaquizzer.ios",
        kSecAttrAccount as String: "api_key",
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    
    guard status == errSecSuccess else {
        throw KeychainError.unableToSave
    }
}
```

### Request Authentication

**Every API Request**:

```swift
func makeRequest<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
    // 1. Build URL
    guard let url = URL(string: "\(baseURL)\(endpoint)") else {
        throw APIError.invalidURL
    }
    
    // 2. Create request
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("FormulaQuizzer-iOS/1.0", forHTTPHeaderField: "User-Agent")
    request.httpBody = body
    
    // 3. Make request
    let (data, response) = try await session.data(for: request)
    
    // 4. Handle response
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }
    
    // 5. Check status
    switch httpResponse.statusCode {
    case 200...299:
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    case 401:
        throw APIError.unauthorized
    case 429:
        throw APIError.rateLimitExceeded
    default:
        throw APIError.serverError(httpResponse.statusCode, "Request failed")
    }
}
```

---

## 🔄 Conflict Resolution

### Conflict Detection

**Scenario**: User edits subject offline, server also updated

```swift
struct ConflictResolution {
    enum Strategy {
        case serverWins      // Default - server is authoritative
        case clientWins      // Keep local changes
        case merge           // Attempt to merge both
        case manual          // Ask user
    }
    
    func resolve(local: Subject, server: SubjectResponse, strategy: Strategy) throws -> Subject {
        switch strategy {
        case .serverWins:
            return try Subject(from: server, keepingLocalID: local.id)
            
        case .clientWins:
            // Upload local changes to server
            Task {
                try await apiService.updateSubject(local)
            }
            return local
            
        case .merge:
            // Merge non-conflicting fields
            var merged = local
            merged.name = server.name  // Server wins on name
            merged.totalQuestions = max(local.totalQuestions, server.totalQuestions)
            merged.correctAnswers = max(local.correctAnswers, server.correctAnswers)
            return merged
            
        case .manual:
            // Present conflict to user
            throw ConflictError.requiresManualResolution(local: local, server: server)
        }
    }
}
```

---

## 📊 Analytics Sync

### Fetching Analytics

**iOS Code**:
```swift
func fetchAnalytics() async throws -> Analytics {
    // 1. Get local stats
    let localStats = try coreDataManager.calculateLocalAnalytics()
    
    // 2. Fetch server analytics
    let serverAnalytics = try await apiService.fetchAnalytics()
    
    // 3. Merge and return
    return Analytics(
        totalSubjects: serverAnalytics.totalSubjects,
        totalQuestionsAnswered: serverAnalytics.totalQuestionsAnswered,
        overallAccuracy: serverAnalytics.overallAccuracy,
        strongestSubjects: serverAnalytics.strongestSubjects,
        weakestSubjects: serverAnalytics.weakestSubjects,
        localCache: localStats
    )
}
```

**Server API Call**:
```http
GET /api/v1/analytics/overview
Authorization: Bearer YOUR_API_KEY
```

**Server Response**:
```json
{
  "total_subjects": 10,
  "total_questions_answered": 500,
  "overall_accuracy": 72.5,
  "strongest_subjects": [
    {"id": 1, "name": "AP Physics 1", "accuracy": 85.0}
  ],
  "weakest_subjects": [
    {"id": 5, "name": "AP Calculus BC", "accuracy": 55.0}
  ]
}
```

---

## 🔔 Background Sync Implementation

### Background Task Registration

```swift
import BackgroundTasks

class BackgroundSyncManager {
    static let shared = BackgroundSyncManager()
    private let identifier = "com.formulaquizzer.sync"
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            self.handleBackgroundSync(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background sync: \(error)")
        }
    }
    
    private func handleBackgroundSync(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleBackgroundSync()
        
        // Perform sync
        Task {
            do {
                try await SyncManager.shared.syncAll()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}
```

### Sync on App Lifecycle

```swift
// In App Delegate or Scene Delegate

func sceneWillEnterForeground(_ scene: UIScene) {
    // App coming to foreground - sync data
    Task {
        try? await SyncManager.shared.syncAll()
    }
}

func sceneDidEnterBackground(_ scene: UIScene) {
    // App going to background - schedule sync
    BackgroundSyncManager.shared.scheduleBackgroundSync()
}
```

---

## 📱 Cross-Device Sync Example

### Scenario: User has iPhone and iPad

**On iPhone**:
1. User creates subject "AP Chemistry"
2. Saved to local Core Data immediately
3. Synced to server in background
4. Server saves with ID: 15

**On iPad (minutes later)**:
1. App enters foreground → triggers sync
2. Fetches subjects from server
3. Finds new subject (ID: 15)
4. Saves to local Core Data
5. User sees "AP Chemistry" appear

**Implementation**:
```swift
func syncSubjectsFromServer() async throws {
    // Get server data
    let serverSubjects = try await apiService.fetchSubjects()
    
    // Get local data
    let localSubjects = try coreDataManager.fetchSubjects()
    
    // Find new subjects from server
    let newServerSubjects = serverSubjects.filter { serverSubject in
        !localSubjects.contains { local in
            local.serverID == serverSubject.id
        }
    }
    
    // Insert new subjects
    for serverSubject in newServerSubjects {
        try coreDataManager.insertSubject(from: serverSubject)
    }
    
    // Update existing subjects
    for serverSubject in serverSubjects {
        if let local = localSubjects.first(where: { $0.serverID == serverSubject.id }) {
            // Check if server version is newer
            if serverSubject.updatedAt > local.updatedAt {
                try coreDataManager.updateSubject(local.id, from: serverSubject)
            }
        }
    }
    
    // Notify UI to refresh
    NotificationCenter.default.post(name: .subjectsDidSync, object: nil)
}
```

---

## 🚨 Error Handling

### Network Errors

```swift
enum APIError: LocalizedError {
    case offline
    case unauthorized
    case rateLimitExceeded
    case serverError(Int, String)
    case timeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "No internet connection. Changes will sync when online."
        case .unauthorized:
            return "Invalid API key. Please check your settings."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .timeout:
            return "Request timed out. Please try again."
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .offline:
            return "Your changes are saved locally and will sync automatically when you're back online."
        case .unauthorized:
            return "Go to Settings and verify your API key is correct."
        case .rateLimitExceeded:
            return "Wait a minute and try again."
        default:
            return "Try again later or contact support if the problem persists."
        }
    }
}
```

### Retry Logic

```swift
func makeRequestWithRetry<T: Decodable>(
    _ endpoint: String,
    maxRetries: Int = 3,
    retryDelay: TimeInterval = 2.0
) async throws -> T {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await makeRequest(endpoint)
        } catch let error as APIError {
            lastError = error
            
            // Don't retry on these errors
            if case .unauthorized = error { throw error }
            if case .invalidResponse = error { throw error }
            
            // Wait before retry
            if attempt < maxRetries - 1 {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
        } catch {
            lastError = error
        }
    }
    
    throw lastError ?? APIError.invalidResponse
}
```

---

## 📈 Performance Optimization

### Request Batching

**Instead of**:
```swift
// BAD: Multiple individual requests
for subject in subjects {
    try await apiService.syncSubject(subject)
}
```

**Do this**:
```swift
// GOOD: Batch sync
let pendingSubjects = subjects.filter { $0.syncStatus == .pending }
if !pendingSubjects.isEmpty {
    try await apiService.syncSubjectsBatch(pendingSubjects)
}
```

### Caching Strategy

```swift
class CacheManager {
    private var subjectCache: [Int: Subject] = [:]
    private var lastFetch: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    func getSubject(id: Int) async throws -> Subject {
        // Check cache
        if let cached = subjectCache[id],
           let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < cacheTimeout {
            return cached
        }
        
        // Fetch from API
        let subject = try await apiService.fetchSubject(id: id)
        
        // Update cache
        subjectCache[id] = subject
        lastFetch = Date()
        
        return subject
    }
}
```

---

## 🧪 Testing Integration

### Mock API Service

```swift
class MockAPIService: APIService {
    var shouldFail = false
    var mockSubjects: [SubjectResponse] = []
    
    override func fetchSubjects() async throws -> [SubjectResponse] {
        if shouldFail {
            throw APIError.serverError(500, "Mock error")
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        return mockSubjects
    }
}

// In tests
func testFetchSubjects() async throws {
    let mockService = MockAPIService()
    mockService.mockSubjects = [SubjectResponse.mock()]
    
    let viewModel = SubjectListViewModel(apiService: mockService)
    await viewModel.loadSubjects()
    
    XCTAssertEqual(viewModel.subjects.count, 1)
}
```

---

## 📚 Best Practices

### ✅ DO

- **Cache aggressively** - show cached data first
- **Sync in background** - don't block UI
- **Handle offline gracefully** - app should work offline
- **Use optimistic updates** - assume success
- **Implement retry logic** - network is unreliable
- **Batch operations** - reduce API calls
- **Monitor sync status** - show user what's syncing

### ❌ DON'T

- **Block UI** - don't wait for network
- **Ignore errors** - handle all error cases
- **Sync too frequently** - respect rate limits
- **Store API keys insecurely** - use Keychain
- **Trust client data** - server is authoritative
- **Forget to reconcile** - handle conflicts

---

## 🎯 Summary

### Integration Checklist

- [ ] Server running and accessible
- [ ] API key configured in iOS app
- [ ] Core Data schema matches server models
- [ ] APIService implemented with all endpoints
- [ ] SyncManager handles background sync
- [ ] Conflict resolution strategy defined
- [ ] Error handling comprehensive
- [ ] Offline mode works correctly
- [ ] Background tasks registered
- [ ] Cross-device sync tested

---

**Last Updated**: 2025-10-13  
**Version**: 1.0.0  
**Status**: ✅ Integration Guide Complete
