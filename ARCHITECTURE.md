# FormulaQuizzer Architecture

## Project Overview
FormulaQuizzer is a Flutter app that delivers randomized quizzes across unlimited subjects using AI-generated questions, local scheduling, and adaptive learning algorithms.

## Core Architecture Principles

### 1. **Local-First Design**
- All data stored locally using SQLite
- Offline-first functionality with AI fallbacks
- No cloud dependencies for core features
- Privacy-focused approach

### 2. **Riverpod State Management**
- Clean separation of business logic and UI
- Reactive state updates across the app
- Testable provider-based architecture
- Efficient rebuilds with granular state watching

### 3. **Adaptive Learning Algorithm**
- Subjects with lower accuracy get higher quiz priority
- Dynamic weighting based on performance history
- Local analytics and progress tracking
- Personalized learning experience

## Directory Structure

```
lib/
├── main.dart                 # App entry point with Riverpod setup
├── models/                   # Data models with SQLite serialization
│   ├── subject.dart         # Subject model with adaptive priority
│   ├── question.dart        # Question model with AI integration
│   └── quiz_session.dart    # Quiz session and settings models
├── database/                 # SQLite database layer
│   └── database_helper.dart # CRUD operations and analytics
├── providers/                # Riverpod state management
│   ├── subject_provider.dart # Subject CRUD and filtering
│   └── quiz_provider.dart   # Quiz logic and session management
├── services/                 # External integrations
│   ├── ai_service.dart      # OpenAI API integration with fallbacks
│   └── notification_service.dart # Local notifications scheduling
├── screens/                  # UI screens
│   ├── home_screen.dart     # Main navigation and dashboard
│   ├── quiz_screen.dart     # Interactive quiz interface
│   ├── subjects_screen.dart # Subject management
│   ├── progress_screen.dart # Analytics and charts
│   └── settings_screen.dart # Quiz scheduling configuration
└── widgets/                  # Reusable UI components
    ├── subject_card.dart    # Subject display with stats
    ├── quick_quiz_card.dart # Quiz launcher widget
    └── stats_overview_card.dart # Progress summary
```

## Key Features Implementation

### 1. **Subject Management**
- Unlimited subject creation with color coding
- Active/inactive status management
- Performance tracking (accuracy, total questions)
- Adaptive priority calculation for quiz selection

### 2. **AI Question Generation**
- FastAPI backend integration for OpenAI API calls
- Local question caching in SQLite
- Fallback to sample questions when AI unavailable
- Educational disclaimers on all AI content

### 3. **Quiz Scheduling**
- Local notification system using flutter_local_notifications
- Configurable active hours and days
- Daily quiz limits with user control
- Random scheduling within specified time windows

### 4. **Adaptive Learning**
- Performance-based subject weighting
- Lower accuracy subjects appear more frequently
- Real-time statistics updates after each quiz
- Progress tracking with visual charts

### 5. **Progress Analytics**
- Overall accuracy and question count tracking
- Per-subject performance visualization
- Bar charts using fl_chart package
- Historical data retention with cleanup

## Data Flow

### Quiz Session Flow
1. User starts quiz (random or specific subject)
2. Subject selected using adaptive priority weighting
3. Question loaded from cache or generated via AI
4. User answers and receives immediate feedback
5. Session data saved to SQLite with performance updates
6. Subject statistics recalculated for future prioritization

### Notification Flow
1. User configures schedule in settings
2. NotificationService calculates random times within active hours
3. Local notifications scheduled for next 7 days
4. Notifications trigger quiz launch when tapped
5. Schedule refreshes automatically

## Performance Considerations

### Database Optimization
- Indexed queries for subject_id and answered_at columns
- Automatic cleanup of old quiz sessions (30+ days)
- Efficient statistics calculation with aggregated queries
- Connection pooling and proper resource management

### UI Performance
- Lazy loading with ListView.builder for large lists
- Efficient state management with granular Riverpod providers
- Image and color caching for subject cards
- Responsive design for various screen sizes

### Memory Management
- Proper disposal of controllers and subscriptions
- Efficient chart rendering with fl_chart
- Minimal state retention in providers
- Garbage collection friendly data structures

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Database CRUD operations
- Adaptive learning algorithm calculations
- AI service integration with mocks

### Integration Tests
- End-to-end quiz flow
- Notification scheduling
- Subject management workflows
- Progress analytics accuracy

### Widget Tests
- Screen rendering with various states
- User interaction handling
- Error state displays
- Responsive layout behavior

## Deployment Considerations

### Platform Support
- iOS: Notification permissions and background processing
- Android: Notification channels and battery optimization
- macOS: Desktop-optimized layouts and interactions
- Web: Limited notification support, local storage fallbacks

### Configuration
- AI service endpoint configuration
- Notification permission handling
- Database migration strategies
- Feature flag management

## Security & Privacy

### Data Protection
- All data stored locally on device
- No cloud synchronization or external data sharing
- User consent for notification permissions
- Educational disclaimers for AI-generated content

### API Security
- Rate limiting for AI service calls
- Error handling for network failures
- Fallback mechanisms for offline usage
- Input validation and sanitization

## Future Enhancements

### Planned Features
- Export/import functionality for subjects and questions
- Advanced analytics with time-series charts
- Collaborative features with local network sharing
- Custom question creation by users
- Spaced repetition algorithm integration

### Technical Improvements
- Background sync for AI question generation
- Advanced caching strategies
- Performance monitoring and analytics
- Accessibility improvements
- Internationalization support
