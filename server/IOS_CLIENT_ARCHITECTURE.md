# FormulaQuizzer iOS Client Architecture

**Native iOS/iPadOS application for cross-device quiz learning with cloud synchronization**

---

## 📱 Project Overview

### Purpose

A native iOS/iPadOS application that provides:
- **Cross-device sync**: Access your subjects and progress on any Apple device
- **Offline-first**: Works without internet, syncs when connected
- **Native performance**: Smooth, responsive UI built with SwiftUI
- **Cloud-backed**: All data stored on formula_quizzer_server backend

### Target Platforms

- **iOS 16.0+**: iPhone (12 and newer)
- **iPadOS 16.0+**: iPad (9th gen and newer)
- **Universal**: Single app works on both iPhone and iPad

---

## 🏗️ Core Architecture Principles

### 1. **MVVM Architecture**

```swift
┌─────────────────────────────────────────────────────────┐
│                         VIEW                             │
│  (SwiftUI Views - SubjectListView, QuizView, etc.)     │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                      VIEW MODEL                          │
│  (ObservableObject - SubjectViewModel, QuizViewModel)   │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                        MODEL                             │
│  (Codable structs - Subject, Question, QuizSession)     │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                       SERVICES                           │
│  (API Client, Core Data, Networking)                    │
└─────────────────────────────────────────────────────────┘
```

### 2. **Offline-First with Sync**

```
User Action → Local Cache (Core Data) → Background Sync → Server
                   ↓                                       ↓
              Immediate UI Update                    Cloud Storage
```

### 3. **Clean Architecture Layers**

```
Presentation Layer (SwiftUI Views)
       ↓
Business Logic Layer (ViewModels + Use Cases)
       ↓
Data Layer (Repositories + API Client + Core Data)
       ↓
Network Layer (URLSession + API Service)
```

---

## 📂 Project Structure

```
FormulaQuizzerIOS/
├── FormulaQuizzerIOS/
│   ├── App/
│   │   ├── FormulaQuizzerIOSApp.swift      # App entry point
│   │   ├── AppDelegate.swift               # App lifecycle
│   │   └── ContentView.swift               # Root view
│   │
│   ├── Models/
│   │   ├── Subject.swift                   # Subject model
│   │   ├── Question.swift                  # Question model
│   │   ├── QuizSession.swift               # Quiz session model
│   │   ├── APIModels.swift                 # API request/response models
│   │   └── CoreDataModels.xcdatamodeld     # Core Data schema
│   │
│   ├── ViewModels/
│   │   ├── SubjectListViewModel.swift      # Subject list logic
│   │   ├── SubjectDetailViewModel.swift    # Subject details logic
│   │   ├── QuizViewModel.swift             # Quiz taking logic
│   │   ├── ProgressViewModel.swift         # Progress analytics
│   │   └── SettingsViewModel.swift         # Settings management
│   │
│   ├── Views/
│   │   ├── Subjects/
│   │   │   ├── SubjectListView.swift       # Subject list screen
│   │   │   ├── SubjectDetailView.swift     # Subject details screen
│   │   │   ├── CreateSubjectView.swift     # Create subject form
│   │   │   └── SubjectCard.swift           # Subject card component
│   │   │
│   │   ├── Quiz/
│   │   │   ├── QuizView.swift              # Quiz taking screen
│   │   │   ├── QuestionCard.swift          # Question display
│   │   │   ├── AnswerButton.swift          # Answer option button
│   │   │   └── ResultsView.swift           # Quiz results
│   │   │
│   │   ├── Progress/
│   │   │   ├── ProgressView.swift          # Progress dashboard
│   │   │   ├── StatsCard.swift             # Statistics card
│   │   │   └── ChartView.swift             # Charts with SwiftUI Charts
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift          # Settings screen
│   │   │   └── ServerConfigView.swift      # API configuration
│   │   │
│   │   └── Components/
│   │       ├── LoadingView.swift           # Loading indicator
│   │       ├── ErrorView.swift             # Error display
│   │       └── EmptyStateView.swift        # Empty state
│   │
│   ├── Services/
│   │   ├── APIService.swift                # API client
│   │   ├── NetworkManager.swift            # Network layer
│   │   ├── SyncManager.swift               # Background sync
│   │   ├── CoreDataManager.swift           # Core Data operations
│   │   └── KeychainService.swift           # Secure storage
│   │
│   ├── Repositories/
│   │   ├── SubjectRepository.swift         # Subject data access
│   │   ├── QuestionRepository.swift        # Question data access
│   │   └── QuizRepository.swift            # Quiz session data access
│   │
│   ├── UseCases/
│   │   ├── CreateSubjectUseCase.swift      # Create subject logic
│   │   ├── StartQuizUseCase.swift          # Start quiz logic
│   │   ├── SubmitAnswerUseCase.swift       # Submit answer logic
│   │   └── SyncDataUseCase.swift           # Data sync logic
│   │
│   ├── Utilities/
│   │   ├── Extensions/
│   │   │   ├── Color+Extensions.swift      # Color utilities
│   │   │   ├── Date+Extensions.swift       # Date formatting
│   │   │   └── View+Extensions.swift       # View modifiers
│   │   ├── Constants.swift                 # App constants
│   │   └── Logger.swift                    # Logging utility
│   │
│   └── Resources/
│       ├── Assets.xcassets                 # Images, colors
│       ├── Localizable.strings             # Translations
│       └── Info.plist                      # App configuration
│
├── FormulaQuizzerIOSTests/                 # Unit tests
├── FormulaQuizzerIOSUITests/               # UI tests
└── FormulaQuizzerIOS.xcodeproj             # Xcode project
```

---

## 🔄 Data Flow Architecture

### Creating a Subject

```swift
1. User taps "Create Subject" in UI
   ↓
2. CreateSubjectView collects input
   ↓
3. SubjectListViewModel validates data
   ↓
4. CreateSubjectUseCase executes business logic
   ↓
5. SubjectRepository saves to Core Data (local)
   ↓
6. SyncManager queues sync operation
   ↓
7. APIService sends to server in background
   ↓
8. UI updates immediately (optimistic update)
   ↓
9. Background sync completes and reconciles
```

### Taking a Quiz

```swift
1. User selects subject → QuizView
   ↓
2. QuizViewModel loads questions:
   - Check Core Data cache
   - If empty/stale, fetch from API
   - Generate with AI if needed
   ↓
3. User answers questions
   ↓
4. Each answer saved locally immediately
   ↓
5. Quiz completion triggers:
   - Local statistics update
   - Background sync to server
   - Analytics calculation
```

### Background Sync Strategy

```swift
Trigger Conditions:
- App enters foreground
- Network becomes available
- User completes significant action
- Periodic timer (every 5 minutes if active)

Sync Process:
1. Check for local changes (dirty flag)
2. Send changes to server
3. Fetch server updates
4. Resolve conflicts (server wins by default)
5. Update local cache
6. Notify UI of changes
```

---

## 💾 Data Storage Strategy

### Three-Tier Storage

```swift
┌────────────────────────────────────────────────┐
│  Tier 1: In-Memory Cache (ViewModels)         │
│  - Active data during user session             │
│  - Fastest access                              │
│  - Lost on app termination                     │
└────────────────────────────────────────────────┘
                    ↕
┌────────────────────────────────────────────────┐
│  Tier 2: Core Data (Local Persistence)        │
│  - Offline storage                             │
│  - Fast local queries                          │
│  - Survives app restart                        │
│  - Source of truth when offline                │
└────────────────────────────────────────────────┘
                    ↕
┌────────────────────────────────────────────────┐
│  Tier 3: Server (Cloud Storage)               │
│  - Cross-device sync                           │
│  - Authoritative source                        │
│  - Analytics and AI generation                 │
└────────────────────────────────────────────────┘
```

### Core Data Schema

```swift
// Subject Entity
Subject {
    id: UUID
    name: String
    subjectDescription: String
    color: String (hex)
    isActive: Bool
    totalQuestions: Int32
    correctAnswers: Int32
    createdAt: Date
    updatedAt: Date
    syncStatus: String (synced/pending/conflict)
    serverID: Int64 (nullable)
}

// Question Entity
Question {
    id: UUID
    subject: Subject (relationship)
    questionText: String
    options: [String] (transformable)
    correctAnswer: String
    explanation: String
    difficulty: String
    isFromAI: Bool
    createdAt: Date
    syncStatus: String
    serverID: Int64 (nullable)
}

// QuizSession Entity
QuizSession {
    id: UUID
    subject: Subject (relationship)
    questions: [Question] (relationship)
    answers: [String: String] (transformable)
    startedAt: Date
    completedAt: Date (nullable)
    score: Int32
    totalQuestions: Int32
    syncStatus: String
    serverID: String (nullable)
}
```

---

## 🌐 API Integration

### APIService Structure

```swift
class APIService {
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession
    
    // MARK: - Subjects
    func fetchSubjects() async throws -> [Subject]
    func createSubject(_ subject: Subject) async throws -> Subject
    func updateSubject(_ subject: Subject) async throws -> Subject
    func deleteSubject(id: Int) async throws
    
    // MARK: - Questions
    func fetchQuestions(subjectId: Int) async throws -> [Question]
    func generateQuestion(subjectId: Int, difficulty: String) async throws -> Question
    func generateQuestionBatch(subjectId: Int, count: Int) async throws -> [Question]
    
    // MARK: - Quiz Sessions
    func startQuizSession(subjectId: Int, questionCount: Int) async throws -> QuizSession
    func submitAnswer(sessionId: String, questionId: Int, answer: String) async throws
    func completeQuizSession(sessionId: String) async throws -> QuizResults
    
    // MARK: - Analytics
    func fetchAnalytics() async throws -> Analytics
    func fetchSubjectAnalytics(subjectId: Int) async throws -> SubjectAnalytics
}
```

### Error Handling

```swift
enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case notFound
    case rateLimitExceeded
    case serverError(Int, String)
    case decodingError(Error)
    case offline
    
    var userMessage: String {
        switch self {
        case .offline:
            return "No internet connection. Working offline."
        case .unauthorized:
            return "Invalid API key. Check settings."
        case .rateLimitExceeded:
            return "Too many requests. Please wait."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
```

### Request/Response Models

```swift
// Matches API_SPECIFICATION.md

struct CreateSubjectRequest: Codable {
    let name: String
    let description: String
    let color: String
}

struct SubjectResponse: Codable {
    let id: Int
    let name: String
    let description: String
    let color: String
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool
    let totalQuestions: Int
    let correctAnswers: Int
    let accuracy: Double
}

struct GenerateQuestionRequest: Codable {
    let subjectId: Int
    let difficulty: String
    let numChoices: Int
}

struct QuestionResponse: Codable {
    let id: Int
    let subjectId: Int
    let questionText: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
    let difficulty: String
    let isFromAI: Bool
}
```

---

## 🔐 Security Architecture

### API Key Storage

```swift
// Store API key securely in Keychain
class KeychainService {
    func saveAPIKey(_ key: String) throws
    func loadAPIKey() throws -> String?
    func deleteAPIKey() throws
}

// Usage
let keychain = KeychainService()
try keychain.saveAPIKey(userProvidedKey)
```

### Network Security

```swift
// URLSession configuration
let configuration = URLSessionConfiguration.default
configuration.tlsMinimumSupportedProtocolVersion = .TLSv13
configuration.httpAdditionalHeaders = [
    "Authorization": "Bearer \(apiKey)",
    "Content-Type": "application/json",
    "User-Agent": "FormulaQuizzer-iOS/1.0"
]
```

### Certificate Pinning (Production)

```swift
class NetworkManager: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Implement certificate pinning
        // Verify server certificate matches expected
    }
}
```

---

## 🎨 UI Architecture (SwiftUI)

### View Structure

```swift
// MARK: - Subject List View
struct SubjectListView: View {
    @StateObject private var viewModel = SubjectListViewModel()
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.subjects) { subject in
                        NavigationLink(destination: SubjectDetailView(subject: subject)) {
                            SubjectCard(subject: subject)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSubjectView()
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
        .task {
            await viewModel.loadSubjects()
        }
    }
}
```

### ViewModel Pattern

```swift
@MainActor
class SubjectListViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage: String?
    
    private let subjectRepository: SubjectRepository
    private let syncManager: SyncManager
    
    init(
        subjectRepository: SubjectRepository = .shared,
        syncManager: SyncManager = .shared
    ) {
        self.subjectRepository = subjectRepository
        self.syncManager = syncManager
    }
    
    func loadSubjects() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load from local cache first
            subjects = try await subjectRepository.fetchLocalSubjects()
            
            // Sync with server in background
            Task {
                try await syncManager.syncSubjects()
                // Reload from cache after sync
                subjects = try await subjectRepository.fetchLocalSubjects()
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func createSubject(name: String, description: String, color: String) async {
        do {
            let subject = try await subjectRepository.createSubject(
                name: name,
                description: description,
                color: color
            )
            subjects.insert(subject, at: 0)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
```

---

## 🔄 Sync Manager Architecture

### SyncManager Implementation

```swift
actor SyncManager {
    static let shared = SyncManager()
    
    private var isSyncing = false
    private var syncQueue: [SyncOperation] = []
    
    enum SyncOperation {
        case createSubject(Subject)
        case updateSubject(Subject)
        case deleteSubject(UUID)
        case createQuizSession(QuizSession)
        case submitAnswer(sessionId: String, answer: Answer)
    }
    
    // MARK: - Public API
    func syncSubjects() async throws {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        // 1. Upload local changes
        try await uploadLocalChanges()
        
        // 2. Download server changes
        try await downloadServerChanges()
        
        // 3. Resolve conflicts
        try await resolveConflicts()
    }
    
    func queueOperation(_ operation: SyncOperation) {
        syncQueue.append(operation)
        Task {
            try await processQueue()
        }
    }
    
    // MARK: - Private Methods
    private func uploadLocalChanges() async throws {
        // Upload subjects with syncStatus == "pending"
        // Upload quiz sessions with syncStatus == "pending"
    }
    
    private func downloadServerChanges() async throws {
        // Fetch subjects updated since last sync
        // Fetch quiz sessions updated since last sync
    }
    
    private func resolveConflicts() async throws {
        // Server wins by default
        // Or implement custom conflict resolution
    }
}
```

---

## 📊 Analytics & Charts

### SwiftUI Charts Integration

```swift
import Charts

struct ProgressChartView: View {
    let dataPoints: [ProgressDataPoint]
    
    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Accuracy", point.accuracy)
            )
            .foregroundStyle(.blue)
            
            PointMark(
                x: .value("Date", point.date),
                y: .value("Accuracy", point.accuracy)
            )
            .foregroundStyle(.blue)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    Text("\(value.as(Double.self) ?? 0, specifier: "%.0f")%")
                }
            }
        }
        .frame(height: 200)
    }
}
```

---

## 📱 iPad-Specific Features

### Adaptive Layout

```swift
struct AdaptiveContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad layout - Two column
            NavigationSplitView {
                SubjectListView()
            } detail: {
                SubjectDetailView()
            }
        } else {
            // iPhone layout - Single column
            NavigationStack {
                SubjectListView()
            }
        }
    }
}
```

### Multitasking Support

- **Split View**: App works in slide over and split view
- **Drag and Drop**: Support dragging subjects between apps
- **Multiple Windows**: iPadOS 16+ multiple window support

---

## 🧪 Testing Strategy

### Unit Tests

```swift
class SubjectViewModelTests: XCTestCase {
    var viewModel: SubjectListViewModel!
    var mockRepository: MockSubjectRepository!
    
    override func setUp() {
        mockRepository = MockSubjectRepository()
        viewModel = SubjectListViewModel(subjectRepository: mockRepository)
    }
    
    func testLoadSubjects() async throws {
        // Given
        let expectedSubjects = [Subject.mock(), Subject.mock()]
        mockRepository.subjects = expectedSubjects
        
        // When
        await viewModel.loadSubjects()
        
        // Then
        XCTAssertEqual(viewModel.subjects.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

### UI Tests

```swift
class SubjectFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        app.launch()
    }
    
    func testCreateSubject() {
        // Tap create button
        app.buttons["plus"].tap()
        
        // Fill form
        app.textFields["Subject Name"].tap()
        app.textFields["Subject Name"].typeText("Physics")
        
        // Submit
        app.buttons["Create"].tap()
        
        // Verify appears in list
        XCTAssertTrue(app.staticTexts["Physics"].exists)
    }
}
```

---

## ⚡ Performance Optimization

### Image Caching

```swift
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }
    
    func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url.absoluteString as NSString)
    }
}
```

### Lazy Loading

```swift
// Use LazyVStack for long lists
LazyVStack(spacing: 16) {
    ForEach(subjects) { subject in
        SubjectCard(subject: subject)
    }
}
```

### Background Task Management

```swift
import BackgroundTasks

// Register background task
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.formulaquizzer.sync",
    using: nil
) { task in
    handleBackgroundSync(task: task as! BGAppRefreshTask)
}

// Schedule background sync
func scheduleBackgroundSync() {
    let request = BGAppRefreshTaskRequest(identifier: "com.formulaquizzer.sync")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
    try? BGTaskScheduler.shared.submit(request)
}
```

---

## 🔔 Notifications

### Local Notifications

```swift
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func scheduleQuizReminder(for subject: Subject, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Quiz Time!"
        content.body = "Ready to practice \(subject.name)?"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: subject.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## 📦 Dependencies

### Swift Package Manager

```swift
// Package.swift dependencies

dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.1"),
]
```

### Recommended Packages

- **Alamofire**: HTTP networking (alternative to URLSession)
- **SwiftUI Charts**: Built-in charting (iOS 16+)
- **KeychainAccess**: Simplified keychain operations

---

## 🚀 Deployment

### App Store Configuration

```swift
// Info.plist requirements

NSUserTrackingUsageDescription: "We use this to improve your experience"
NSPhotoLibraryUsageDescription: "To save quiz results as images"
UIBackgroundModes: ["fetch", "remote-notification"]
```

### Build Configurations

- **Debug**: Points to localhost:3000
- **Staging**: Points to staging server
- **Production**: Points to production API

---

## 📝 Next Steps

1. **Project Setup**: Create Xcode project with SwiftUI
2. **Core Data**: Implement local storage schema
3. **API Service**: Build networking layer
4. **MVVM Setup**: Create ViewModels and Views
5. **Sync Manager**: Implement background sync
6. **Testing**: Write unit and UI tests
7. **Polish**: Animations, error handling, loading states
8. **App Store**: Submit for review

---

**Last Updated**: 2025-10-13  
**Version**: 1.0.0  
**Status**: ✅ Architecture Complete - Ready for Implementation
