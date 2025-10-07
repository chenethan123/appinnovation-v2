# FormulaQuizzer Development Workflow

## Development Standards

### **Flutter Architecture Requirements**
- Use Riverpod for state management with proper provider separation
- StatefulWidget pattern with mounted checks before setState() calls
- Local-first design with SQLite as primary data store
- Material 3 theming with responsive design patterns

### **Critical Error Prevention**
- ALWAYS add `if (!mounted) return;` before setState() calls in StatefulWidgets
- Handle AI service failures gracefully with fallback questions
- Validate all user inputs before database operations
- Include try-catch blocks around all async operations

### **Performance Requirements**
- Database queries must use indexed columns for efficiency
- UI should remain responsive during AI question generation
- Implement proper loading states for all async operations
- Clean up old quiz sessions automatically (30+ day retention)

### **File Organization Standards**
- `/models`: Data classes with SQLite serialization methods
- `/database`: Database helper with CRUD operations and analytics
- `/providers`: Riverpod state management with proper separation
- `/services`: External API integrations (AI service, notifications)
- `/screens`: UI screens with StatefulWidget pattern
- `/widgets`: Reusable UI components with consistent styling

## Pre-Development Protocol

### **Environment Setup**
1. Run `flutter clean` before starting development sessions
2. Check Flutter version compatibility: `flutter doctor`
3. Verify SQLite dependencies: `flutter pub deps`
4. Test notification permissions on target platforms

### **Code Quality Checks**
1. Ensure all async methods have proper error handling
2. Validate that providers don't hold unnecessary state
3. Check for memory leaks in StatefulWidget disposal
4. Verify responsive design on multiple screen sizes

## Development Workflow

### **New Feature Development**
1. **Design Phase**: Define data models and database schema changes
2. **Provider Setup**: Create or update Riverpod providers for state management
3. **Service Integration**: Implement external API calls with fallback mechanisms
4. **UI Implementation**: Build screens with proper loading and error states
5. **Testing**: Verify functionality across iOS, Android, and macOS platforms

### **Database Changes**
1. Update model classes with new fields and serialization
2. Modify DatabaseHelper with schema migrations
3. Test data integrity with existing records
4. Update providers to handle new data structures

### **AI Service Integration**
1. Define question format and validation rules
2. Implement API calls with timeout handling
3. Create fallback questions for offline scenarios
4. Add educational disclaimers to all AI-generated content

## Testing Protocol

### **Core Functionality Tests**
- Subject creation, editing, and deletion
- Quiz question generation and caching
- Adaptive learning algorithm accuracy
- Notification scheduling and delivery
- Progress analytics and chart rendering

### **Performance Validation**
- Database query execution times (<100ms for common operations)
- UI responsiveness during AI question generation
- Memory usage during extended quiz sessions
- Battery impact of notification scheduling

### **Cross-Platform Testing**
- iOS: Notification permissions and background processing
- Android: Battery optimization and notification channels
- macOS: Desktop UI scaling and keyboard navigation
- Web: Local storage limitations and notification fallbacks

## Error Handling Standards

### **Database Errors**
- Log all SQLite exceptions with context
- Provide user-friendly error messages
- Implement automatic retry mechanisms
- Graceful degradation when database unavailable

### **Network Errors**
- Handle AI service timeouts gracefully
- Fall back to cached questions when API unavailable
- Display appropriate loading states during requests
- Retry failed requests with exponential backoff

### **UI Error States**
- Show meaningful error messages to users
- Provide retry buttons for recoverable errors
- Maintain app functionality during partial failures
- Log errors for debugging without exposing technical details

## Git Workflow Standards

### **Branch Management**
- `main`: Stable, production-ready code
- `feature/feature-name`: New feature development
- `fix/issue-description`: Bug fixes and improvements
- `refactor/component-name`: Code refactoring without feature changes

### **Commit Standards**
- `feat:` New features and enhancements
- `fix:` Bug fixes and error corrections
- `perf:` Performance improvements
- `refactor:` Code restructuring without behavior changes
- `docs:` Documentation updates
- `test:` Test additions and modifications

### **Pre-Commit Checklist**
- No setState() calls without mounted checks
- All async operations have error handling
- UI components are responsive across screen sizes
- Database operations use proper indexing
- AI service calls include fallback mechanisms

## Deployment Checklist

### **Pre-Release Validation**
- Clean build test: `flutter build apk --release`
- Cross-platform testing on iOS, Android, and macOS
- Performance validation with large datasets
- Notification scheduling accuracy verification
- AI service integration with rate limiting

### **Release Preparation**
- Update version numbers in pubspec.yaml
- Generate release notes with feature descriptions
- Test app store compliance requirements
- Verify educational disclaimers throughout UI
- Confirm privacy policy alignment with local-first design

## Maintenance Protocols

### **Regular Maintenance Tasks**
- Database cleanup of old quiz sessions
- Notification permission status verification
- AI service endpoint health checks
- Performance monitoring and optimization
- User feedback integration and bug fixes

### **Monitoring and Analytics**
- Track quiz completion rates and accuracy trends
- Monitor AI service usage and costs
- Analyze notification delivery success rates
- Measure app performance metrics
- Collect user feedback for feature prioritization
