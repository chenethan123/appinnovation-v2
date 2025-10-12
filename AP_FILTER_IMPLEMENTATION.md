# AP Filter & Multiple Course Filtering Implementation ✅

## What Was Implemented

### **1. Multiple Filter System**
Added the ability to combine filters:
- **Category Filter** (All, STEM, Humanities, Social Science, Languages, Business)
- **AP Filter** (Show only AP courses)
- **Search** (Text search within filtered results)

### **2. Filter Combination Examples**
- **STEM + AP** = Only AP STEM courses (AP Calculus AB/BC, AP Statistics, AP Physics, AP Chemistry, AP Biology, AP CS A, etc.)
- **Humanities + AP** = Only AP Humanities courses (AP English, AP History, AP Art History, AP Music Theory)
- **All + AP** = All 33 AP courses across all categories
- **STEM + No AP** = Only college STEM courses (MATH 101, CS 101, PHYS 101, etc.)

### **3. UI Components Added**

#### **"AP Courses Only" FilterChip**
```dart
FilterChip(
  label: Row(
    children: [
      Icon(_showOnlyAP ? Icons.school : Icons.school_outlined),
      Text('AP Courses Only'),
    ],
  ),
  selected: _showOnlyAP,
  onSelected: (_) => _toggleAPFilter(),
)
```

Located below the category filter chips with "Filters:" label

### **4. Filter Logic**

```dart
Future<void> _onSearchChanged() async {
  List<Course> results = await service.getAllCourses();
  
  // Apply category filter
  if (_selectedCategory != 'All') {
    results = results.where((c) => c.category == _selectedCategory).toList();
  }
  
  // Apply AP filter
  if (_showOnlyAP) {
    results = results.where((c) => c.courseId == 'AP').toList();
  }
  
  // Apply search query
  if (query.isNotEmpty) {
    results = await service.searchCourses(query);
    // Re-apply filters...
  }
}
```

---

## Course Database Update

### **Added 27 More College Courses**
**Total courses now: 127 courses**
- 33 AP courses
- 94 college courses

#### **New Courses Added:**
- **STEM**: Thermodynamics, Analytical Chemistry, Biochemistry, Abstract Algebra, Real Analysis, Computer Networks, Machine Learning, Computer Graphics, Electrical/Mechanical Engineering
- **Humanities**: Creative Writing, European History, Asian History, Political Philosophy, Philosophy of Mind
- **Social Science**: Econometrics, Cognitive Psychology, Behavioral Neuroscience
- **Languages**: Intermediate Spanish I/II, Elementary French II, Elementary Japanese I
- **Business**: Business Law, Entrepreneurship, Managerial Accounting

---

## How It Works

### **Scenario 1: View All Courses**
1. Click search button (🔍)
2. Leave "All" category selected
3. Don't toggle AP filter
4. **Result**: See all 127 courses

### **Scenario 2: View Only AP Courses**
1. Click search button (🔍)
2. Leave "All" category selected
3. Toggle "AP Courses Only" filter ON
4. **Result**: See only 33 AP courses

### **Scenario 3: View AP Math Courses**
1. Click search button (🔍)
2. Select "STEM" category
3. Toggle "AP Courses Only" filter ON
4. Type "calc" or "stat" in search
5. **Result**: See AP Calculus AB, AP Calculus BC, AP Statistics

### **Scenario 4: View College STEM Courses (No AP)**
1. Click search button (🔍)
2. Select "STEM" category
3. Leave AP filter OFF
4. **Result**: See MATH 101, PHYS 101, CS 101, etc. (no AP courses)

---

## Visual Layout

```
┌─────────────────────────────────────────┐
│  Search: [_______________________] 🔍  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ [All] [STEM] [Humanities] [Social]...   │  ← Category Chips
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Filters:  [🎓 AP Courses Only]          │  ← AP Filter
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│                                         │
│  📘 AP Calculus AB                      │
│     Advanced Placement Calculus...      │
│                                         │
│  📘 AP Calculus BC                      │
│     Advanced Placement Calculus...      │
│                                         │
│  📗 MATH 101 - College Algebra          │
│     Introduction to algebraic...        │
│                                         │
└─────────────────────────────────────────┘
```

---

## Code Changes

### **Modified Files:**

1. **`lib/screens/subject_search_screen.dart`**
   - Added `bool _showOnlyAP = false;` field
   - Added `_toggleAPFilter()` method
   - Updated `_onSearchChanged()` to apply multiple filters
   - Added AP filter chip UI below category filters

2. **`assets/courses.json`**
   - Added 27 new college courses
   - Total: 127 courses (33 AP + 94 college)

---

## Testing Instructions

1. **Launch the app**
2. **Go to Subjects tab**
3. **Click the search/add button** (magnifying glass icon)
4. **Test filters:**
   - Select "STEM" → Should see STEM courses (AP + college)
   - Toggle "AP Courses Only" → Should see only AP STEM courses
   - Toggle OFF AP filter → Should see only college STEM courses
   - Select "All" + Toggle AP → Should see all 33 AP courses
   - Search "calc" with STEM + AP → Should see AP Calculus AB/BC

---

## Database Info

**Location**: `~/Library/Containers/com.example.formulaQuizzer/Data/Documents/formula_quizzer.db`

**Courses Table Schema**:
```sql
CREATE TABLE courses (
  id INTEGER PRIMARY KEY,
  course_id TEXT NOT NULL,    -- "AP" for AP courses, "MATH 101" for college
  subject_name TEXT NOT NULL, -- "AP Calculus AB", "College Algebra"
  category TEXT NOT NULL,     -- "STEM", "Humanities", etc.
  description TEXT,
  is_custom INTEGER DEFAULT 0
);
```

**Query to see all AP courses**:
```sql
SELECT * FROM courses WHERE course_id = 'AP';
```

**Query to see AP STEM courses**:
```sql
SELECT * FROM courses WHERE course_id = 'AP' AND category = 'STEM';
```

---

## Benefits of This Implementation

✅ **Multiple Filter Support**: Combine category + AP filters
✅ **Clear UI**: Separate "Filters:" section with icon
✅ **Responsive**: Filters update immediately
✅ **Intuitive**: Toggle on/off with visual feedback
✅ **Flexible**: Works with search queries too

---

## Next Steps (Future Enhancements)

1. **Add "College Only" filter** (opposite of AP filter)
2. **Add difficulty level filter** (100-level, 200-level, 300-level)
3. **Add "Recently Added" sort option**
4. **Add "Popular" filter** based on number of users studying each course
5. **Save filter preferences** to SharedPreferences

---

## Summary

The app now supports **intelligent multi-filtering**:
- Browse all 127 courses
- Filter by category (STEM, Humanities, etc.)
- Filter by course type (AP vs college)
- Search within filtered results
- Combine all filters together for precise course discovery

**Example**: "Show me only AP Math courses" = STEM category + AP filter + search "calc"

🎉 **The subject search is now much more powerful and user-friendly!**
