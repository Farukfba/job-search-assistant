# Job Search Assistant - Complete Architecture Analysis

## 1. Architecture Overview

This is a **cross-platform Flutter application** paired with a **backend service** that leverages AI (Claude Haiku) to help users find and apply for jobs. The architecture follows a **clean separation of concerns**:

- **Frontend**: Flutter app (iOS, Android, Linux, Windows)
- **Backend**: TanStack Start on Cloudflare Workers
- **Database**: Supabase (PostgreSQL)
- **AI Engine**: Anthropic Claude API (claude-haiku-4-5-20251001)
- **Job Search**: Adzuna API via MCP tools

**Architecture Pattern**: **Client-Server with Stateless API** + **Riverpod State Management**

---

## 2. Folder Structure Explanation

```
job_search_assistant/
├── lib/
│   ├── main.dart                           # App entry, auth gate, Supabase init
│   ├── models/
│   │   ├── job.dart                        # Job data model (JSON serializable)
│   │   └── profile.dart                    # User profile (CV data)
│   ├── services/
│   │   └── api_service.dart                # All backend HTTP calls
│   ├── screens/
│   │   ├── auth_screen.dart                # Login/Sign up
│   │   ├── cv_upload_screen.dart           # CV parsing & profile creation
│   │   ├── main_shell.dart                 # Bottom nav shell (Search + Tracker)
│   │   ├── job_search_screen.dart          # Search UI + results
│   │   ├── job_detail_screen.dart          # Match score + actions
│   │   ├── cover_letter_screen.dart        # AI-generated cover letter
│   │   ├── interview_prep_screen.dart      # Interview Q&A prep
│   │   └── tracker_screen.dart             # Kanban-style application tracker
│   ├── widgets/
│   │   ├── job_card.dart                   # Job list item
│   │   └── match_score_ring.dart           # Circular progress indicator
│   └── PROJECT_PLAN.md                     # High-level roadmap
├── android/                                # Android native layer
├── ios/                                    # iOS native layer (not shown)
├── linux/                                  # Linux runner (GTK)
├── windows/                                # Windows runner (Win32)
├── test/                                   # Widget tests
├── pubspec.yaml                            # Dependencies
└── analysis_options.yaml                   # Lint rules
```

---

## 3. Key Business Logic

### **User Journey Flow**
```
AuthScreen
    ↓ (Login/Sign Up via Supabase)
CvUploadScreen
    ↓ (Pick PDF → parse-cv endpoint → Claude extracts skills/exp)
MainShell (Bottom Nav)
    ├── JobSearchScreen
    │    ↓ (search-jobs endpoint → Adzuna API)
    │    ↓ JobDetailScreen
    │         ├── match-job (Compare CV skills vs job desc)
    │         ├── CoverLetterScreen (Claude generates letter)
    │         ├── InterviewPrepScreen (Claude Q&A)
    │         └── Save to Tracker (Supabase insert)
    │
    └── TrackerScreen
         └── Kanban board (Applied → Interview → Offer / Rejected)
```

### **Core Logic Flows**

#### **CV Parsing**
1. User picks PDF
2. FilePicker extracts bytes
3. ApiService.parseCv() sends to backend (multipart/form-data)
4. Backend: Claude parses PDF → extracts skills[], experience[], raw_text
5. Save to Supabase profiles table
6. Auto-redirect to MainShell if profile exists

#### **Job Matching**
1. User taps job → JobDetailScreen loads
2. Fetch user's CV data from profiles table
3. Call match-job endpoint with {cv_data, job_description}
4. Backend: Claude scores match 0-100, identifies missing skills, recommendation
5. Display match score ring + missing skills chips + recommendation card

#### **Application Tracker**
1. Load saved_jobs table grouped by stage (Applied, Interview, Offer, Rejected)
2. Display in columnar layout with stage indicators
3. PopupMenu to advance stage or mark rejected
4. updateJobStatus endpoint persists changes

---

## 4. State Management Pattern

**Framework**: Flutter Riverpod (declarative, functional)

**Current Implementation**: Mostly **StatefulWidget + setState** with some Riverpod dependency

### **Why Riverpod?**
- ✅ Declared as dependency in pubspec.yaml
- ✅ Wrapped app in ProviderScope()
- ❌ **Minimal actual usage** — most logic still in setState

### **Recommendation for Scale**
Create providers for:
```dart
// lib/providers/user_provider.dart
final userProvider = FutureProvider<User>((ref) async {
  return supabase.auth.currentUser;
});

// lib/providers/profile_provider.dart
final profileProvider = FutureProvider<Profile>((ref) async {
  final user = await ref.watch(userProvider.future);
  return ApiService.getProfile(user.id);
});

// lib/providers/saved_jobs_provider.dart
final savedJobsProvider = FutureProvider<List<SavedJob>>((ref) async {
  return ApiService.getSavedJobs();
});
```

---

## 5. API Integrations

### **Backend Endpoints**

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/api/public/parse-cv` | POST | Parse PDF → extract skills/exp | x-user-id header |
| `/api/public/search-jobs` | POST | Search Adzuna API | x-user-id header |
| `/api/public/match-job` | POST | Score job match (Claude) | x-user-id header |
| `/api/public/cover-letter` | POST | Generate cover letter (Claude) | x-user-id header |
| `/api/public/interview-prep` | POST | Generate interview Q&A (Claude) | x-user-id header |
| `/api/public/save-job` | POST | Insert to saved_jobs table | x-user-id header |
| `/api/public/update-job-status` | POST | Update application stage | x-user-id header |

### **Auth Header Implementation**
```dart
static String? get _userId =>
    Supabase.instance.client.auth.currentUser?.id;

static Map<String, String> get _headers => {
      'Content-Type': 'application/json',
      'x-user-id': _userId ?? '',
};
```

**Base URL**: `https://skill-seeker-service.lovable.app`

---

## 6. Database Interactions

### **Supabase Tables**

#### **profiles table**
```sql
user_id (UUID, PK)
extracted_skills (JSON array)
extracted_experience (JSON array)
raw_cv_text (TEXT)
updated_at (TIMESTAMP)
```

**Operations**:
- SELECT → Load CV data before matching
- UPSERT → Save parsed CV after upload
- Directly via supabase.from('profiles').select()

#### **saved_jobs table**
```sql
id (UUID, PK)
user_id (UUID, FK)
job_title (TEXT)
company (TEXT)
job_url (TEXT)
match_score (INT)
status (TEXT: 'Applied'|'Interview'|'Offer'|'Rejected')
created_at (TIMESTAMP)
```

**Operations**:
- INSERT → Save job via ApiService.saveJob()
- SELECT → Load tracker via ApiService.getSavedJobs()
- UPDATE → Change status via ApiService.updateJobStatus()

### **Query Examples**

```dart
// Get user's profile
final profile = await supabase
    .from('profiles')
    .select()
    .eq('user_id', userId)
    .single();

// Get saved jobs (in TrackerScreen)
final response = await Supabase.instance.client
    .from('saved_jobs')
    .select()
    .order('created_at', ascending: false);

// Get jobs by status (grouped in app)
_jobs.where((j) => (j['status'] ?? 'Applied') == stage).toList()
```

---

## 7. Authentication & Authorization Flow

### **Auth Flow**

```
MyApp
  ↓
AuthGate (StreamBuilder on onAuthStateChange)
  ├─ session == null → AuthScreen (email/password form)
  │    ├─ Sign Up: supabase.auth.signUp(email, password)
  │    └─ Log In: supabase.auth.signInWithPassword(email, password)
  │
  └─ session != null → CvUploadScreen
       ├─ Check if profile exists
       ├─ If yes → MainShell
       └─ If no → Show upload UI
```

### **Session Management**
- **Provider**: Supabase Auth (JWT-based)
- **Token Storage**: Automatically handled by supabase_flutter package
- **Current User**: supabase.auth.currentUser?.id

### **Authorization**
- **Endpoint Protection**: Backend validates x-user-id header
- **Row-Level Security**: Supabase RLS policies (assumed on profiles & saved_jobs)
- **No Role-Based Access** (all users same permissions)

---

## 8. Important Dependencies

### **Key Packages**

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^3.3.2 | State management (provider pattern) |
| `supabase_flutter` | ^2.14.2 | Auth + Database (Postgres) |
| `file_picker` | ^11.0.2 | CV file selection (PDF) |
| `http` | ^1.6.0 | HTTP requests to backend |
| `cupertino_icons` | ^1.0.8 | iOS icons |
| `flutter_lints` | ^5.0.0 | Code quality (dev) |

### **No Local Database**
- ❌ Hive, SQLite, ObjectBox
- ✅ All data persisted to Supabase (cloud-first)

### **Plugin Dependencies**
- **Windows**: url_launcher_windows, app_links_plugin_c_api
- **Linux**: gtk, url_launcher_linux
- **Android/iOS**: app_links, url_launcher_windows

---

## 9. Coding Conventions

### **File Naming**
- ✅ `snake_case` for files: lib/screens/job_detail_screen.dart
- ✅ Classes: `PascalCase`: JobDetailScreen
- ✅ Constants: `camelCase`: _stages

### **Directory Structure**
```
lib/
  models/       # Data classes (immutable)
  services/     # API & external integrations
  screens/      # Full-page widgets (StatefulWidget usually)
  widgets/      # Reusable UI components
```

### **Widget Patterns**
```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});
  
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // Private members: _isLoading, _error, _data
  
  @override
  void initState() {
    super.initState();
    _load(); // Fetch data
  }
  
  @override
  Widget build(BuildContext context) {
    // Ternary chains for loading/error/content states
  }
}
```

### **Error Handling**
```dart
setState(() {
  _isLoading = true;
  _error = null;
});

try {
  final data = await someAsyncCall();
  setState(() => _data = data);
} catch (e) {
  setState(() => _error = 'User-friendly message');
} finally {
  setState(() => _isLoading = false);
}
```

### **Async Patterns**
- ✅ Explicit `Future<void>` method names: _loadMatch(), _search()
- ✅ Try-catch-finally blocks
- ✅ mounted checks before setState in async callbacks

---

## 10. Potential Technical Debt

### **🔴 High Priority**

1. **Riverpod Adoption**
   - Currently declared but barely used
   - Most state still in `setState`
   - **Action**: Migrate providers to replace StatefulWidget state

2. **Error Handling Inconsistency**
   - Some endpoints return plain text (cover letter), others JSON
   - No standardized error format
   - **Action**: Backend should return `{error: string}` for all failures

3. **API Response Handling**
   - Manual JSON decoding everywhere
   - No type-safe models for responses
   - **Action**: Create response DTOs (e.g., MatchResult, SearchJobsResponse)

### **🟡 Medium Priority**

4. **CV Data Structure**
   - Backend returns `cvData` as generic `Map<String, dynamic>`
   - Inconsistent field names (skills, experience vs extracted_skills)
   - **Action**: Create CvData model with factory constructor

5. **Missing Input Validation**
   - Job search allows empty title/location
   - No email format validation on auth
   - **Action**: Add form validation before API calls

6. **Hardcoded Values**
   - Base URL in lib/services/api_service.dart
   - Country code "gb" in backend (Adzuna)
   - Window size `1280x720` in Windows runner
   - **Action**: Move to config/constants file

7. **No Caching**
   - Every search/detail view fetches fresh data
   - Repeated API calls for same job
   - **Action**: Add in-memory or persistent cache layer

### **🟢 Low Priority**

8. **Test Coverage**
   - Only 1 example widget test (counter_increments_smoke_test)
   - No service layer tests
   - **Action**: Add unit tests for ApiService, integration tests for screens

9. **Logging**
   - Debug prints scattered throughout
   - No structured logging framework
   - **Action**: Use logger package for production-ready logging

10. **Linux/Windows Support**
    - Minimal testing on non-mobile platforms
    - Platform-specific bugs likely undiscovered
    - **Action**: Add CI/CD for multi-platform builds

---

## Summary

**This is a well-structured AI-powered job search application** with:

✅ **Strengths**:
- Clear separation (screens, services, models)
- Supabase integration for auth + DB
- Stateless API design (easy to test backend independently)
- Multi-platform support (Flutter + native runners)

⚠️ **Improvement Areas**:
- Replace `setState` with Riverpod providers
- Standardize API response handling
- Add input validation & error recovery
- Increase test coverage
- Remove hardcoded values

**Ready to discuss any specific architectural questions or help implement improvements!**
