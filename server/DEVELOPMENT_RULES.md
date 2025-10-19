# Development Rules for FormulaQuizzer Server

## 🚨 CRITICAL RULE: Documentation-First Development

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  ⚠️  MANDATORY DEVELOPMENT PROTOCOL                             │
│                                                                   │
│  Before making ANY code changes, you MUST:                       │
│                                                                   │
│  1. ✅ Consult relevant documentation                           │
│  2. ✅ Verify approach aligns with architecture                 │
│  3. ✅ Follow established patterns and standards                │
│  4. ✅ Update documentation after changes                       │
│                                                                   │
│  DO NOT proceed with changes until documentation is reviewed!    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Rule 1: Consult Documentation First

### Before ANY Code Change

**ALWAYS follow this sequence:**

```
1. CONSULT DOCUMENTATION
   ├── Read relevant section in docs/
   ├── Review existing patterns
   ├── Check API specifications
   └── Verify architecture alignment

2. PLAN IMPLEMENTATION
   ├── Identify files to modify
   ├── List required changes
   ├── Consider side effects
   └── Plan testing strategy

3. MAKE CHANGES
   ├── Follow coding standards
   ├── Implement with best practices
   ├── Add proper error handling
   └── Write tests

4. UPDATE DOCUMENTATION
   ├── Update affected docs
   ├── Add new examples
   ├── Update API specs
   └── Increment version if needed
```

### Documentation Lookup Guide

| Task | Documentation to Consult |
|------|--------------------------|
| Adding new endpoint | [API_SPECIFICATION.md](./API_SPECIFICATION.md), [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) |
| Changing database schema | [ARCHITECTURE.md](./ARCHITECTURE.md) → Database Schema |
| Adding new service | [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) → Services |
| Deployment changes | [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) |
| Modifying API response | [API_SPECIFICATION.md](./API_SPECIFICATION.md) |
| Adding middleware | [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) → Middleware |
| Security changes | [ARCHITECTURE.md](./ARCHITECTURE.md) → Security |
| Performance optimization | [ARCHITECTURE.md](./ARCHITECTURE.md) → Performance |

---

## Rule 2: Architecture Compliance

### ALWAYS verify changes comply with:

- ✅ **API-First Design**: RESTful, versioned endpoints
- ✅ **Repository Pattern**: Data access through repositories
- ✅ **Service Layer**: Business logic in services
- ✅ **Error Handling**: Consistent error responses
- ✅ **Security**: Authentication, validation, sanitization
- ✅ **Performance**: Caching, indexing, optimization

### Architecture Review Checklist

- [ ] Does this follow the repository pattern?
- [ ] Is business logic in the service layer?
- [ ] Are inputs validated with Zod?
- [ ] Is error handling comprehensive?
- [ ] Is authentication/authorization enforced?
- [ ] Are database queries optimized?
- [ ] Is caching strategy appropriate?
- [ ] Are types properly defined?

---

## Rule 3: Coding Standards

### TypeScript Standards (from DEVELOPMENT_GUIDE.md)

```typescript
// ✅ GOOD: Follows standards
export class SubjectService {
  constructor(
    private subjectRepo: SubjectRepository,
    private logger: Logger
  ) {}

  async create(data: CreateSubjectData): Promise<Subject> {
    try {
      // Validate business rules
      const existing = await this.subjectRepo.findByName(data.name);
      if (existing) {
        throw new ApiError('Subject already exists', 409);
      }

      const subject = await this.subjectRepo.create(data);
      this.logger.info({ subject_id: subject.id }, 'Subject created');
      return subject;
    } catch (error) {
      this.logger.error({ error, data }, 'Failed to create subject');
      throw error;
    }
  }
}
```

```typescript
// ❌ BAD: Violates standards
export class subjectService {  // Wrong: should be PascalCase
  async create(data: any) {  // Wrong: using 'any'
    const subject = await db.query('INSERT INTO subjects...');  // Wrong: direct DB access
    return subject;  // Wrong: no error handling
  }
}
```

---

## Rule 4: Testing Requirements

### Before Merging ANY Code

- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests pass
- [ ] API endpoints tested with curl/Postman
- [ ] Error cases tested
- [ ] Documentation examples tested

### Testing Checklist

```bash
# 1. Run all tests
npm test

# 2. Check coverage
npm run test:coverage

# 3. Lint code
npm run lint

# 4. Type check
npm run build

# 5. Test manually
curl http://localhost:3000/api/v1/health
```

---

## Rule 5: Documentation Updates

### ALWAYS update documentation when:

- ✅ Adding new API endpoint → Update `API_SPECIFICATION.md`
- ✅ Changing database schema → Update `ARCHITECTURE.md`
- ✅ Adding new service → Update `PROJECT_STRUCTURE.md`
- ✅ Changing deployment → Update `DEPLOYMENT_GUIDE.md`
- ✅ New coding pattern → Update `DEVELOPMENT_GUIDE.md`
- ✅ Environment variables → Update `GETTING_STARTED.md`

### Documentation Update Template

```markdown
## [Feature Name]

**Added**: 2025-10-13
**Version**: 1.1.0

### Description
[What was added/changed]

### API Changes
[New endpoints or modified responses]

### Example
```bash
curl -X POST http://localhost:3000/api/v1/new-endpoint \
  -H "Authorization: Bearer API_KEY" \
  -d '{"example": "data"}'
```

### Migration Required
[If database changes]

### Breaking Changes
[If any]
```

---

## Rule 6: Project Independence

### CRITICAL: Server Independence Rule

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  ⛔ NEVER EVER:                                                  │
│                                                                   │
│  - Modify files in ../formula_quizzer/                          │
│  - Import from ../formula_quizzer/                              │
│  - Share database files with Flutter app                         │
│  - Reference Flutter app code                                    │
│                                                                   │
│  ✅ ALWAYS:                                                      │
│                                                                   │
│  - Keep all code in formula_quizzer_server/                     │
│  - Use separate database                                         │
│  - Maintain API as standalone service                            │
│  - Document integration via API only                             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Rule 7: Security First

### Security Review Checklist

- [ ] All inputs validated
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevention (sanitized outputs)
- [ ] Authentication enforced
- [ ] Rate limiting active
- [ ] Secrets not hardcoded
- [ ] HTTPS in production
- [ ] CORS properly configured

### Security Consultation

**ALWAYS consult:**
- [ARCHITECTURE.md](./ARCHITECTURE.md) → Security Architecture
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) → Security Standards

---

## Rule 8: Performance Considerations

### Before Implementing

- [ ] Will this impact database performance?
- [ ] Is caching appropriate?
- [ ] Are database queries optimized?
- [ ] Is pagination implemented?
- [ ] Are indexes needed?

### Performance Targets

- **Health Check**: < 50ms
- **Simple CRUD**: < 100ms
- **AI Generation**: < 3000ms (< 200ms with cache)
- **Analytics**: < 500ms
- **Batch Operations**: < 5000ms

---

## Rule 9: Error Handling

### Standard Error Response (from API_SPECIFICATION.md)

```typescript
{
  "error": "error_code",
  "message": "Human-readable message",
  "timestamp": "2025-10-13T09:34:33-04:00",
  "path": "/api/v1/endpoint"
}
```

### Error Handling Pattern

```typescript
try {
  // Operation
} catch (error) {
  if (error instanceof ApiError) {
    throw error;  // Rethrow known errors
  }
  
  logger.error({ error }, 'Unexpected error');
  throw new ApiError('Internal server error', 500);
}
```

---

## Rule 10: Git Workflow

### Commit Message Format

```bash
<type>(<scope>): <subject>

# Types:
feat: New feature
fix: Bug fix
docs: Documentation only
test: Test additions/changes
refactor: Code refactoring
perf: Performance improvement
chore: Maintenance tasks
```

### Before Committing

```bash
# 1. Check documentation consulted
[ ] Reviewed relevant docs

# 2. Run checks
npm test
npm run lint
npm run build

# 3. Update documentation
[ ] Documentation updated

# 4. Commit with proper message
git add .
git commit -m "feat(subjects): add filtering by category"
```

---

## Enforcement

### Pull Request Checklist

**Reviewers MUST verify:**

- [ ] Documentation consulted (PR description lists docs reviewed)
- [ ] Code follows architecture patterns
- [ ] Tests included and passing
- [ ] Documentation updated
- [ ] Security considerations addressed
- [ ] Performance impact considered
- [ ] Error handling comprehensive

### PR Description Template

```markdown
## Changes
[Describe changes]

## Documentation Consulted
- [ ] ARCHITECTURE.md - [section]
- [ ] DEVELOPMENT_GUIDE.md - [section]
- [ ] API_SPECIFICATION.md - [section]

## Testing
- [ ] Unit tests added
- [ ] Integration tests pass
- [ ] Manual testing completed

## Documentation Updates
- [ ] API_SPECIFICATION.md updated
- [ ] [Other docs] updated

## Checklist
- [ ] Follows coding standards
- [ ] Error handling comprehensive
- [ ] Security reviewed
- [ ] Performance considered
```

---

## Quick Reference

### Common Tasks

| Task | Documentation Order |
|------|---------------------|
| **Add API Endpoint** | 1. API_SPECIFICATION.md<br>2. DEVELOPMENT_GUIDE.md (routes)<br>3. PROJECT_STRUCTURE.md |
| **Modify Database** | 1. ARCHITECTURE.md (schema)<br>2. PROJECT_STRUCTURE.md (migrations)<br>3. DEVELOPMENT_GUIDE.md (repository) |
| **Add Service** | 1. ARCHITECTURE.md (service layer)<br>2. PROJECT_STRUCTURE.md (services)<br>3. DEVELOPMENT_GUIDE.md (patterns) |
| **Deploy Changes** | 1. DEPLOYMENT_GUIDE.md<br>2. ARCHITECTURE.md (infrastructure) |

---

## Violations

### What Happens If Rules Are Broken?

- ❌ **No Documentation Consultation**: PR rejected immediately
- ❌ **Architecture Violation**: Must refactor to comply
- ❌ **No Tests**: PR blocked until tests added
- ❌ **Documentation Not Updated**: PR blocked
- ❌ **Security Issues**: Critical - must fix immediately

---

## Exception Process

### When Rules May Be Bent (Rarely!)

**Only in these cases:**
1. Emergency production fix (document after)
2. Prototype/spike (clearly marked, not merged)
3. Documentation itself being created

**Process:**
1. Document exception reason in PR
2. Get explicit approval
3. Create follow-up task to align with rules
4. Update documentation ASAP

---

## Summary

### The Golden Rule

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  📖 DOCUMENTATION FIRST, ALWAYS                                 │
│                                                                   │
│  1. Read docs before coding                                      │
│  2. Follow established patterns                                  │
│  3. Write tests                                                  │
│  4. Update documentation                                         │
│  5. Get review                                                   │
│                                                                   │
│  This ensures consistency, quality, and maintainability.         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

**Last Updated**: 2025-10-13  
**Version**: 1.0.0  
**Status**: ✅ Mandatory - All Contributors
