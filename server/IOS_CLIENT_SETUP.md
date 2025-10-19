# FormulaQuizzer iOS Client Setup Guide

Complete guide to set up and develop the iOS/iPadOS client application.

---

## Prerequisites

### Development Environment

| Requirement | Version | Download |
|-------------|---------|----------|
| **macOS** | Ventura 13.0+ | Required for Xcode |
| **Xcode** | 15.0+ | [Mac App Store](https://apps.apple.com/app/xcode/id497799835) |
| **iOS Simulator** | 16.0+ | Included with Xcode |
| **Swift** | 5.9+ | Included with Xcode |

### Apple Developer Account

- **Free Account**: For local development and testing
- **Paid Account ($99/year)**: Required for App Store distribution and advanced features

### Backend Server

The iOS app requires the **formula_quizzer_server** to be running:

```bash
# Start the server (see GETTING_STARTED.md)
cd formula_quizzer_server
npm run dev

# Server should be running at:
# http://localhost:3000
```

---

## Step 1: Create Xcode Project

### Using Xcode

1. **Open Xcode** → "Create New Project"
2. **Select Template**: iOS → App
3. **Project Configuration**:
   - **Product Name**: `FormulaQuizzerIOS`
   - **Team**: Select your Apple Developer team
   - **Organization Identifier**: `com.yourname.formulaquizzer`
   - **Bundle Identifier**: Will be auto-generated
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: Core Data ✅ (check this!)
   - **Tests**: Include Tests ✅

4. **Save Location**: `/Users/ethanchen/Desktop/App Innovation/FormulaQuizzerIOS/`

### Project Structure Created

```
FormulaQuizzerIOS/
├── FormulaQuizzerIOS.xcodeproj
└── FormulaQuizzerIOS/
    ├── FormulaQuizzerIOSApp.swift
    ├── ContentView.swift
    ├── FormulaQuizzerIOS.xcdatamodeld
    ├── Assets.xcassets
    └── Preview Content/
```

---

## Step 2: Configure Project Settings

### General Settings

1. **Open Project Settings** → Select target `FormulaQuizzerIOS`
2. **General Tab**:
   - **Minimum Deployments**: iOS 16.0, iPadOS 16.0
   - **Supported Destinations**: iPhone, iPad
   - **Device Orientation**: Portrait, Landscape (iPad)

### Capabilities

1. **Signing & Capabilities Tab** → Click "+ Capability"
2. **Add**:
   - ✅ **Background Modes**
     - Background fetch
     - Remote notifications
   - ✅ **Push Notifications** (optional, for future features)

### Info.plist

Add these keys to `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <!-- For development only - Remove in production -->
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
</array>
```

---

## Step 3: Set Up Core Data

### Define Core Data Schema

1. **Open** `FormulaQuizzerIOS.xcdatamodeld`
2. **Create Entities**:

#### Subject Entity

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| id | UUID | No | - |
| name | String | No | - |
| subjectDescription | String | No | - |
| color | String | No | #2196F3 |
| isActive | Boolean | No | true |
| totalQuestions | Integer 32 | No | 0 |
| correctAnswers | Integer 32 | No | 0 |
| createdAt | Date | No | now |
| updatedAt | Date | No | now |
| syncStatus | String | No | synced |
| serverID | Integer 64 | Yes | - |

#### Question Entity

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| id | UUID | No | - |
| questionText | String | No | - |
| options | Transformable | No | - |
| correctAnswer | String | No | - |
| explanation | String | No | - |
| difficulty | String | No | medium |
| isFromAI | Boolean | No | false |
| createdAt | Date | No | now |
| syncStatus | String | No | synced |
| serverID | Integer 64 | Yes | - |

**Relationships**:
- `subject` → Subject (To One)
- Subject has `questions` → Question (To Many)

#### QuizSession Entity

| Attribute | Type | Optional | Default |
|-----------|------|----------|---------|
| id | UUID | No | - |
| startedAt | Date | No | now |
| completedAt | Date | Yes | - |
| score | Integer 32 | No | 0 |
| totalQuestions | Integer 32 | No | 0 |
| answers | Transformable | No | - |
| syncStatus | String | No | synced |
| serverID | String | Yes | - |

**Relationships**:
- `subject` → Subject (To One)
- `questions` → Question (To Many)

### Configure Transformable Attributes

Create a `ValueTransformer` for arrays:

```swift
// Utilities/ArrayTransformer.swift

import Foundation

@objc(ArrayTransformer)
class ArrayTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        [NSArray.self, NSString.self, NSDictionary.self]
    }
    
    static func register() {
        let transformer = ArrayTransformer()
        ValueTransformer.setValueTransformer(
            transformer,
            forName: NSValueTransformerName("ArrayTransformer")
        )
    }
}
```

In `FormulaQuizzerIOSApp.swift`:

```swift
init() {
    ArrayTransformer.register()
}
```

---

## Step 4: Create Folder Structure

### Add Groups in Xcode

Right-click project → "New Group":

```
FormulaQuizzerIOS/
├── App/
├── Models/
├── ViewModels/
├── Views/
│   ├── Subjects/
│   ├── Quiz/
│   ├── Progress/
│   ├── Settings/
│   └── Components/
├── Services/
├── Repositories/
├── UseCases/
├── Utilities/
│   └── Extensions/
└── Resources/
```

---

## Step 5: Create Core Models

### Models/Subject.swift

```swift
import Foundation

struct Subject: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var color: String
    var isActive: Bool
    var totalQuestions: Int
    var correctAnswers: Int
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus
    var serverID: Int?
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100.0
    }
    
    enum SyncStatus: String, Codable {
        case synced
        case pending
        case conflict
    }
}

// MARK: - API Response Model
struct SubjectResponse: Codable {
    let id: Int
    let name: String
    let description: String
    let color: String
    let isActive: Bool
    let totalQuestions: Int
    let correctAnswers: Int
    let accuracy: Double
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, color
        case isActive = "is_active"
        case totalQuestions = "total_questions"
        case correctAnswers = "correct_answers"
        case accuracy
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

### Models/Question.swift

```swift
import Foundation

struct Question: Identifiable, Codable {
    let id: UUID
    var questionText: String
    var options: [String]
    var correctAnswer: String
    var explanation: String
    var difficulty: Difficulty
    var isFromAI: Bool
    var subjectID: UUID
    var createdAt: Date
    var syncStatus: SyncStatus
    var serverID: Int?
    
    enum Difficulty: String, Codable {
        case easy, medium, hard
    }
    
    enum SyncStatus: String, Codable {
        case synced, pending, conflict
    }
}
```

---

## Step 6: Create Services

### Services/APIService.swift

```swift
import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession
    
    private init() {
        // Load from environment or settings
        self.baseURL = UserDefaults.standard.string(forKey: "apiBaseURL") 
            ?? "http://localhost:3000/api/v1"
        self.apiKey = KeychainService.shared.loadAPIKey() 
            ?? "dev_key_1"
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Subjects
    func fetchSubjects() async throws -> [SubjectResponse] {
        let url = URL(string: "\(baseURL)/subjects")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode, "Failed to fetch subjects")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let apiResponse = try decoder.decode(SubjectsAPIResponse.self, from: data)
        return apiResponse.data
    }
    
    func createSubject(name: String, description: String, color: String) async throws -> SubjectResponse {
        let url = URL(string: "\(baseURL)/subjects")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body = CreateSubjectRequest(name: name, description: description, color: color)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            throw APIError.serverError(httpResponse.statusCode, "Failed to create subject")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SubjectResponse.self, from: data)
    }
    
    // Add more methods for questions, quiz sessions, etc.
}

// MARK: - Request Models
struct CreateSubjectRequest: Codable {
    let name: String
    let description: String
    let color: String
}

struct SubjectsAPIResponse: Codable {
    let data: [SubjectResponse]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case pageSize = "page_size"
        case total
        case totalPages = "total_pages"
    }
}
```

### Services/KeychainService.swift

```swift
import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.formulaquizzer.ios"
    private let apiKeyAccount = "api_key"
    
    private init() {}
    
    func saveAPIKey(_ key: String) throws {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data
        ]
        
        // Delete old key if exists
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToLoad
    case unableToDelete
}
```

---

## Step 7: Create ViewModels

### ViewModels/SubjectListViewModel.swift

```swift
import Foundation
import Combine

@MainActor
class SubjectListViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let apiService: APIService
    private let coreDataManager: CoreDataManager
    
    init(apiService: APIService = .shared, coreDataManager: CoreDataManager = .shared) {
        self.apiService = apiService
        self.coreDataManager = coreDataManager
    }
    
    func loadSubjects() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load from local cache first
            subjects = try coreDataManager.fetchSubjects()
            
            // Fetch from API in background
            Task {
                do {
                    let apiSubjects = try await apiService.fetchSubjects()
                    try coreDataManager.saveSubjects(apiSubjects)
                    subjects = try coreDataManager.fetchSubjects()
                } catch {
                    // Silently fail - we have cached data
                    print("Background sync failed: \(error)")
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func createSubject(name: String, description: String, color: String) async {
        do {
            let response = try await apiService.createSubject(
                name: name,
                description: description,
                color: color
            )
            
            try coreDataManager.saveSubject(response)
            subjects = try coreDataManager.fetchSubjects()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
```

---

## Step 8: Create Views

### Views/Subjects/SubjectListView.swift

```swift
import SwiftUI

struct SubjectListView: View {
    @StateObject private var viewModel = SubjectListViewModel()
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.subjects.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        title: "No Subjects Yet",
                        message: "Create your first subject to get started",
                        systemImage: "book.closed"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.subjects) { subject in
                                NavigationLink {
                                    SubjectDetailView(subject: subject)
                                } label: {
                                    SubjectCard(subject: subject)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSubjectView()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error occurred")
            }
        }
        .task {
            await viewModel.loadSubjects()
        }
    }
}
```

### Views/Components/SubjectCard.swift

```swift
import SwiftUI

struct SubjectCard: View {
    let subject: Subject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: subject.color))
                    .frame(width: 12, height: 12)
                
                Text(subject.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(subject.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 20) {
                StatLabel(
                    title: "Questions",
                    value: "\(subject.totalQuestions)"
                )
                
                StatLabel(
                    title: "Accuracy",
                    value: String(format: "%.0f%%", subject.accuracy)
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatLabel: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}
```

---

## Step 9: Configure App Entry Point

### FormulaQuizzerIOSApp.swift

```swift
import SwiftUI

@main
struct FormulaQuizzerIOSApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    init() {
        // Configure app on launch
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.container.viewContext)
        }
    }
    
    private func setupApp() {
        // Register transformers
        ArrayTransformer.register()
        
        // Configure appearance
        configureAppearance()
    }
    
    private func configureAppearance() {
        // Customize navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
```

---

## Step 10: Test the App

### Run on Simulator

1. **Select Device**: iPhone 15 Pro or iPad Pro (12.9-inch)
2. **Press**: Cmd + R or click Run button
3. **Wait**: App should launch in simulator

### Initial Configuration

1. **Open Settings** in the app
2. **Configure Server**:
   - API URL: `http://localhost:3000/api/v1`
   - API Key: `dev_key_1`
3. **Save Settings**
4. **Return to Subject List** - should sync with server

### Test Offline Mode

1. **Enable Airplane Mode** in simulator
2. **App should still work** with cached data
3. **Create a subject** - should be queued for sync
4. **Disable Airplane Mode** - sync should complete automatically

---

## Common Issues & Solutions

### Issue: Cannot Connect to Server

**Solution**:
```bash
# Check server is running
curl http://localhost:3000/api/v1/health

# If not working, check Info.plist has:
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

### Issue: Core Data Errors

**Solution**:
```swift
// Reset Core Data (development only)
CoreDataManager.shared.resetAllData()
```

### Issue: Build Fails

**Solution**:
```bash
# Clean build folder
Product → Clean Build Folder (Cmd + Shift + K)

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

---

## Next Steps

1. ✅ **Server Running**: Ensure formula_quizzer_server is running
2. ✅ **App Configured**: API URL and key set correctly
3. ✅ **Test Sync**: Create subject, verify appears in server database
4. 📱 **Test on Device**: Deploy to physical iPhone/iPad
5. 🎨 **Polish UI**: Add animations, improve UX
6. 🧪 **Write Tests**: Unit tests for ViewModels
7. 📦 **Prepare Release**: App Store submission

---

**Last Updated**: 2025-10-13  
**Version**: 1.0.0  
**Status**: ✅ Setup Complete - Ready for Development
