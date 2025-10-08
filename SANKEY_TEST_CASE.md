# Test Case: Sankey Chart Date Change

## Mục đích
Verify rằng Sankey Chart vẽ flows chính xác khi thay đổi date option.

## Setup hiện tại

### Khi thay đổi date (ví dụ: Today → This week):

1. **AnalysisProvider.updateDateOption()** được gọi
2. **fetchData()** chạy → Tính toán data mới
3. **notifyListeners()** → Trigger rebuild
4. **analysis.dart** rebuild với `ValueKey('sankey_${newDateOption}')`
5. **Flutter dispose widget cũ** (gọi dispose())
6. **Flutter tạo widget MỚI** (gọi initState())

### Luồng hoạt động trong SankeyChartAnalysis:

```
Widget MỚI được tạo
  ↓
initState() chạy
  ↓
addPostFrameCallback → _updateItemPositions()
  ↓
Frame 1 render: build() tạo UI và GlobalKeys
  ↓
Frame callback chạy: _updateItemPositions()
  ↓
Kiểm tra painterRenderBox?
  - NULL hoặc !hasSize → retry
  ↓
Kiểm tra _incomeKeys & _expenseKeys?
  - EMPTY → retry (QUAN TRỌNG!)
  ↓
Frame 2: Keys đã được tạo bởi build
  ↓
_updateItemPositions() chạy lại
  ↓
Tính toán positions từ GlobalKeys
  ↓
setState() nếu có thay đổi
  ↓
Frame 3: SankeyPainter vẽ với positions mới
  ↓
XONG! ✅
```

## Các điểm quan trọng

### 1. ValueKey thay đổi → Widget mới
- ✅ Đúng: Đảm bảo state sạch hoàn toàn
- ✅ initState() được gọi mỗi lần date change
- ✅ didUpdateWidget() KHÔNG được gọi (vì widget khác nhau)

### 2. Retry logic trong _updateItemPositions()
```dart
// Kiểm tra 1: Painter ready chưa?
if (painterRenderBox == null || !painterRenderBox.hasSize) {
  // → Retry
  return;
}

// Kiểm tra 2: Có GlobalKeys chưa? (QUAN TRỌNG!)
if (_incomeKeys.isEmpty && _expenseKeys.isEmpty) {
  // → Retry (cho build() tạo keys trước)
  return;
}

// OK! Tính toán positions...
```

### 3. Không schedule trong build()
- ❌ TUYỆT ĐỐI KHÔNG làm điều này
- ✅ Logic retry tự động handle

## Test Steps

### Manual Testing:

1. **Launch app**
   - Mở màn hình Analysis
   - Chọn Sankey chart
   - Verify: Flows vẽ đúng

2. **Change date: Today → This week**
   - Tap dropdown
   - Chọn "This week"
   - Verify:
     - ✅ Data update (categories thay đổi)
     - ✅ Flows vẽ đúng vị trí NGAY LẬP TỨC
     - ✅ Không có flicker/lag

3. **Rapid changes**
   - Thay đổi nhanh: Today → This week → This month → All
   - Verify:
     - ✅ Mỗi lần đều vẽ đúng
     - ✅ Không crash
     - ✅ Smooth

4. **Edge cases**
   - Empty state (no transactions)
   - Only income (no expense)
   - Only expense (no income)
   - Many categories (>10)

### Debug Console Check:

Tìm các messages:
- ✅ OK: "Could not calculate position for ..." (1-2 lần đầu là bình thường)
- ❌ BAD: Nếu message này lặp lại liên tục → còn vòng lặp

### Performance Check:

1. **Frame count**: Flutter DevTools → Performance
   - ✅ Good: 2-3 frames để render hoàn chỉnh
   - ❌ Bad: >10 frames hoặc continuous rebuilding

2. **Widget rebuilds**: Flutter DevTools → Widget Inspector
   - ✅ Good: SankeyChartAnalysis rebuild 1 lần khi date change
   - ❌ Bad: Rebuild nhiều lần liên tục

## Expected Results

| Scenario | Expected | Current Status |
|----------|----------|----------------|
| Date change | Flows vẽ đúng ngay | ✅ (với retry logic) |
| No infinite loop | No continuous rebuilds | ✅ (không schedule trong build) |
| Empty → Data | Handle gracefully | ✅ (early return) |
| Many categories | All flows correct | ✅ (với fallback trong painter) |
| Rapid changes | Smooth, no crash | ✅ (dispose clean up) |

## Troubleshooting

### Nếu flows vẫn vẽ sai:

1. **Check console logs**
   ```
   "Could not calculate position for X"
   ```
   → RenderBox chưa attached hoặc positions không hợp lệ

2. **Add debug print** trong _updateItemPositions:
   ```dart
   debugPrint('Keys: income=${_incomeKeys.length}, expense=${_expenseKeys.length}');
   debugPrint('Positions: ${_itemPositions.length}');
   ```

3. **Verify GlobalKey assignment** trong _buildCategoryItem:
   ```dart
   debugPrint('Creating key for: ${summary.category}, type: $type');
   ```

### Nếu có infinite loop:

1. **Check build() method**
   - ❌ Có `addPostFrameCallback`?
   - ❌ Có `setState()`?
   - ✅ Chỉ build UI

2. **Check _updateItemPositions()**
   - ✅ Có `if (!mounted) return`?
   - ✅ Có kiểm tra positions khác nhau trước setState?

## Kết luận

Code hiện tại **SHOULD WORK** với các điều kiện:

1. ✅ Không schedule trong build()
2. ✅ Retry logic handle missing keys
3. ✅ Check positions thay đổi trước setState
4. ✅ ValueKey đảm bảo widget mới = state sạch

Nếu vẫn có vấn đề → cần check:
- SankeyPainter fallback logic
- GlobalKey creation timing
- Provider data update timing

---

**Date:** 2025-10-08  
**Status:** TESTING REQUIRED 🧪
