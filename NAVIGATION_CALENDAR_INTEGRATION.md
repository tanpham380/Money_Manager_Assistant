# Tích Hợp Analysis → Calendar Navigation

## 📋 Tổng quan

Thay vì tạo `CategoryDetailSheet` riêng, giải pháp này **tái sử dụng màn hình Calendar** đã có sẵn để hiển thị chi tiết giao dịch theo danh mục khi người dùng tap vào biểu đồ trong Analysis screen.

## 🎯 Ý tưởng chính

Khi người dùng tap vào một phần của biểu đồ (donut slice hoặc bar column):
1. App tự động **chuyển sang tab Calendar**
2. Calendar **tự động lọc** hiển thị chỉ các giao dịch của category đó
3. Hiển thị visual indicator để người dùng biết đang xem filtered view
4. Có button để clear filter và quay về view tất cả giao dịch

## 🏗️ Kiến trúc Implementation

### 1. NavigationProvider (State Management)

**File**: `lib/project/provider/navigation_provider.dart`

```dart
class NavigationProvider with ChangeNotifier {
  // Tab index hiện tại
  int _currentTabIndex = 0;
  
  // Filter state
  String? _filterType;      // 'Income' hoặc 'Expense'
  String? _filterCategory;  // Tên category (e.g., 'Food', 'Transportation')
  IconData? _filterIcon;    // Icon của category
  Color? _filterColor;      // Màu của category
  
  // Methods
  void changeTab(int index)
  void navigateToCalendarWithFilter(...)
  void clearFilter()
  bool get hasActiveFilter
}
```

**Chức năng**:
- Quản lý tab hiện tại trong BottomNavigationBar
- Lưu trữ filter state để Calendar có thể đọc
- Cung cấp methods để navigate + set filter atomically

### 2. Home Screen Integration

**File**: `lib/project/home.dart`

**Thay đổi**:
```dart
// TRƯỚC
class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  // Quản lý state local
}

// SAU
class _HomeState extends State<Home> {
  // Sử dụng NavigationProvider
  return Consumer<NavigationProvider>(
    builder: (context, navProvider, child) {
      return Scaffold(
        body: IndexedStack(
          index: navProvider.currentTabIndex,
          children: _pages,
        ),
      );
    },
  );
}
```

**Provider Setup** (`real_main.dart`):
```dart
runApp(
  ChangeNotifierProvider(
    create: (_) => NavigationProvider(),
    child: MyApp(),
  ),
);
```

### 3. Analysis Screen Chart Callback

**File**: `lib/project/app_pages/analysis.dart`

**Flow**:
```dart
Widget _buildChart(AnalysisProvider provider, List<CategorySummary> summaries) {
  void handleSelection(int index) {
    final summary = summaries[index];
    
    // 1. Highlight chart selection
    provider.updateSelectedIndex(index);
    
    // 2. Navigate to Calendar with filter
    final navProvider = context.read<NavigationProvider>();
    navProvider.navigateToCalendarWithFilter(
      type: widget.type,           // 'Income' or 'Expense'
      category: summary.category,   // 'Food', 'Transportation', etc.
      icon: summary.icon,
      color: summary.color,
    );
  }
  
  // Pass callback to chart widgets
  return DonutChartAnalysis(
    summaries: summaries,
    onSelection: handleSelection,
  );
}
```

### 4. Calendar Screen (Cần cập nhật)

**File**: `lib/project/app_pages/calendar.dart`

**Cần thêm**:

#### A. Đọc filter từ NavigationProvider

```dart
class _CalendarBodyState extends State<CalendarBody> {
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return FutureBuilder<List<InputModel>>(
          future: DB.inputModelList(),
          builder: (context, snapshot) {
            // Lấy filter
            final filterType = navProvider.filterType;
            final filterCategory = navProvider.filterCategory;
            
            // Áp dụng filter nếu có
            List<InputModel> filteredData = snapshot.data ?? [];
            if (navProvider.hasActiveFilter) {
              filteredData = filteredData.where((t) {
                return t.type == filterType && 
                       t.category == filterCategory;
              }).toList();
            }
            
            // Build calendar với filtered data
            return _buildCalendar(filteredData, navProvider);
          },
        );
      },
    );
  }
}
```

#### B. Hiển thị Filter Banner

```dart
Widget _buildFilterBanner(NavigationProvider navProvider) {
  if (!navProvider.hasActiveFilter) return SizedBox.shrink();
  
  return Container(
    padding: EdgeInsets.all(12.w),
    color: navProvider.filterColor?.withOpacity(0.1),
    child: Row(
      children: [
        // Icon
        Icon(navProvider.filterIcon, color: navProvider.filterColor),
        SizedBox(width: 12.w),
        
        // Text
        Expanded(
          child: Text(
            'Filtering: ${navProvider.filterCategory} (${navProvider.filterType})',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        // Clear button
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () => navProvider.clearFilter(),
        ),
      ],
    ),
  );
}
```

#### C. Cập nhật UI Structure

```dart
return Column(
  children: [
    // 1. Filter banner (nếu có)
    _buildFilterBanner(navProvider),
    
    // 2. Calendar
    TableCalendar(...),
    
    // 3. Transaction list (đã filtered)
    Expanded(
      child: ValueListenableBuilder<List<InputModel>>(
        valueListenable: _selectedEvents,
        builder: (context, value, _) {
          return Column(children: [
            Expanded(child: Balance(value)),
            Expanded(child: buildEvents(value))
          ]);
        },
      ),
    )
  ],
);
```

## 🔄 User Flow

### Scenario 1: Tap vào Donut Chart

```
1. User ở Analysis tab
2. User tap vào slice "Food" trên donut chart
   
   ┌─────────────────────────────────┐
   │  Analysis                       │
   │  ┌─────────────┐                │
   │  │   Donut     │ ← TAP "Food"   │
   │  │   Chart     │                │
   │  └─────────────┘                │
   └─────────────────────────────────┘
                 ↓
                 ↓ navigateToCalendarWithFilter()
                 ↓
   ┌─────────────────────────────────┐
   │  Calendar                       │
   │  ┌───────────────────────────┐  │
   │  │ 🍔 Food (Expense)      ✖  │  │ ← Filter Banner
   │  └───────────────────────────┘  │
   │  ┌─────────────┐                │
   │  │  Calendar   │                │
   │  │   Grid      │                │
   │  └─────────────┘                │
   │  Only "Food" transactions       │
   └─────────────────────────────────┘
```

### Scenario 2: Clear Filter

```
User tap ✖ button
   ↓
navProvider.clearFilter()
   ↓
Calendar shows ALL transactions
```

### Scenario 3: Navigate Away

```
User taps another tab (e.g., Input)
   ↓
NavigationProvider keeps filter state
   ↓
User returns to Calendar
   ↓
Filter is still active ✓
```

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     App Startup                         │
│  real_main.dart                                         │
│  ├─ ChangeNotifierProvider<NavigationProvider>         │
│  └─ MyApp → Home                                        │
└─────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
     ┌─────────┐     ┌──────────┐   ┌─────────┐
     │  Input  │     │ Analysis │   │Calendar │
     └─────────┘     └──────────┘   └─────────┘
                           │               │
                           │ User taps     │
                           │ chart slice   │
                           ▼               │
                  ┌─────────────────┐      │
                  │ handleSelection │      │
                  └─────────────────┘      │
                           │               │
                           ▼               │
                  ┌─────────────────────────────────┐
                  │ NavigationProvider              │
                  │  .navigateToCalendarWithFilter()│
                  └─────────────────────────────────┘
                           │
                           ├─ Set _currentTabIndex = 2
                           ├─ Set _filterType
                           ├─ Set _filterCategory
                           ├─ Set _filterIcon
                           ├─ Set _filterColor
                           └─ notifyListeners()
                           │
                           ▼
                  ┌─────────────────┐
                  │ Home rebuilds   │
                  │ IndexedStack    │
                  │ shows Calendar  │
                  └─────────────────┘
                           │
                           ▼
                  ┌─────────────────────────┐
                  │ Calendar reads          │
                  │ NavigationProvider      │
                  │ and applies filter      │
                  └─────────────────────────┘
```

## ⚡ Performance Considerations

### Optimization 1: IndexedStack
```dart
// Home.dart sử dụng IndexedStack thay vì PageView
body: IndexedStack(
  index: navProvider.currentTabIndex,
  children: _pages,
)
```
**Lợi ích**: Các tab giữ state khi chuyển đổi, không rebuild lại

### Optimization 2: Lazy Loading trong Calendar
```dart
// Chỉ load transactions khi cần
FutureBuilder<List<InputModel>>(
  future: DB.inputModelList(),
  builder: (context, snapshot) {
    // Apply filter in memory, không query DB lại
  },
)
```

### Optimization 3: ValueListenableBuilder
```dart
// Calendar đã sử dụng ValueListenableBuilder
ValueListenableBuilder<List<InputModel>>(
  valueListenable: _selectedEvents,
  builder: (context, value, _) {
    // Chỉ rebuild khi _selectedEvents thay đổi
  },
)
```

## 🎨 UI/UX Enhancements

### Filter Banner Design

```
┌─────────────────────────────────────────────┐
│ 🍔 Food (Expense)                        ✖  │ ← Colored background
│ Showing 15 transactions                     │
└─────────────────────────────────────────────┘
```

**Features**:
- Background color matches category color (với opacity 0.1-0.2)
- Category icon
- Clear button (×)
- Transaction count
- Animated slide in/out

### Calendar Visual Indicators

```dart
// Highlight dates có filtered transactions
calendarBuilders: CalendarBuilders(
  markerBuilder: (context, date, events) {
    if (events.isNotEmpty && navProvider.hasActiveFilter) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: navProvider.filterColor,  // Use category color
        ),
      );
    }
  },
)
```

## 🧪 Testing Checklist

- [ ] Tap donut slice → Calendar shows filtered data
- [ ] Tap bar column → Calendar shows filtered data
- [ ] Filter banner displays correct info
- [ ] Clear filter button works
- [ ] Calendar dates show correct markers
- [ ] Switch to another tab → filter persists
- [ ] Return to Calendar → filter still active
- [ ] Navigate to Calendar manually → no filter
- [ ] App restart → filter resets (expected)

## 🔮 Future Enhancements

### 1. Persist Filter State
```dart
// Lưu filter vào SharedPreferences
class NavigationProvider {
  Future<void> saveFilterState() async {
    await sharedPrefs.setString('filter_category', _filterCategory);
  }
  
  Future<void> loadFilterState() async {
    _filterCategory = sharedPrefs.getString('filter_category');
  }
}
```

### 2. Multiple Filters
```dart
// Cho phép filter theo nhiều categories
Set<String> _filterCategories = {};

void addCategoryFilter(String category) {
  _filterCategories.add(category);
}
```

### 3. Date Range Filter
```dart
// Kết hợp category filter với date range
DateTime? _filterStartDate;
DateTime? _filterEndDate;
```

### 4. Quick Actions
```dart
// Thêm FAB trong Calendar để quick add transaction vào category đang filter
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddInput(
          prefilledCategory: navProvider.filterCategory,
          prefilledType: navProvider.filterType,
        ),
      ),
    );
  },
)
```

## 📝 Code Changes Summary

### Files Created
- ✅ `lib/project/provider/navigation_provider.dart` (NEW)

### Files Modified
- ✅ `lib/project/home.dart` - Use NavigationProvider
- ✅ `lib/project/real_main.dart` - Add Provider setup
- ✅ `lib/project/app_pages/analysis.dart` - Add navigation callback
- ⏳ `lib/project/app_pages/calendar.dart` - Add filter logic (TODO)

### Files Deleted
- ❌ CategoryDetailSheet (không cần nữa)

## 🎯 Kết luận

Giải pháp này:
- ✅ **Tái sử dụng** màn hình Calendar đã có
- ✅ **Không cần** tạo bottom sheet phức tạp
- ✅ **Cải thiện** user experience với navigation mượt mà
- ✅ **Maintain** state consistency
- ✅ **Scalable** - dễ mở rộng thêm features

**Ưu điểm chính**: Thay vì duplicate UI logic, ta leverage màn hình Calendar đầy đủ tính năng đã có (swipe actions, edit, delete, calendar view) chỉ bằng cách thêm filter layer!
