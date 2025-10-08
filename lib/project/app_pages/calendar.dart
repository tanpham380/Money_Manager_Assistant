import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../classes/app_bar.dart';
import '../classes/constants.dart';
import '../classes/daily_transaction_group.dart';
import '../classes/input_model.dart';
import '../classes/state_widgets.dart';
import '../localization/methods.dart';
import '../provider/calendar_provider.dart';
import '../provider/transaction_provider.dart';
import '../provider/navigation_provider.dart';
import '../utils/date_format_utils.dart';

class Calendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use the TransactionProvider from the ancestor (Home widget)
    return ChangeNotifierProxyProvider<TransactionProvider, CalendarProvider>(
      create: (context) => CalendarProvider(
        context.read<TransactionProvider>(),
        context.read<NavigationProvider>(),
      ),
      update: (context, transactionProvider, previous) {
        // Reuse previous CalendarProvider if it exists
        if (previous != null) {
          return previous;
        }
        return CalendarProvider(transactionProvider, context.read<NavigationProvider>());
      },
      child: Scaffold(
        backgroundColor: blue1,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: BasicAppBar(getTranslated(context, 'Calendar')!),
        ),
        body: Consumer<CalendarProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return LoadingStateWidget(
                message: getTranslated(context, 'Loading calendar') ?? 'Loading calendar...',
              );
            }
            
            if (provider.errorMessage != null) {
              return ErrorStateWidget(
                message: provider.errorMessage,
                onRetry: () => provider.refreshData(),
              );
            }
            
            return _CalendarContent();
          },
        ),
      ),
    );
  }
}

class _CalendarContent extends StatefulWidget {
  @override
  State<_CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<_CalendarContent> {
  bool _isFilterExpanded = false; // Default: collapsed
  
  /// Build filter display text based on active filters
  String _buildFilterDisplayText(BuildContext context, NavigationProvider navProvider) {
    final hasType = navProvider.filterType != null && navProvider.filterType!.isNotEmpty;
    final hasCategory = navProvider.filterCategory != null && navProvider.filterCategory!.isNotEmpty;
    
    if (navProvider.isOthersCategory) {
      // "Others" category
      if (hasType) {
        return '${getTranslated(context, navProvider.filterType!) ?? navProvider.filterType!} - ${getTranslated(context, 'Others') ?? 'Others'}';
      } else {
        return '${getTranslated(context, 'All') ?? 'All'} - ${getTranslated(context, 'Others') ?? 'Others'}';
      }
    } else if (hasType && hasCategory) {
      // Both type and category
      return '${getTranslated(context, navProvider.filterType!) ?? navProvider.filterType!} - ${getTranslated(context, navProvider.filterCategory!) ?? navProvider.filterCategory!}';
    } else if (hasCategory) {
      // Category only (no type = All types)
      return '${getTranslated(context, 'All') ?? 'All'} - ${getTranslated(context, navProvider.filterCategory!) ?? navProvider.filterCategory!}';
    } else if (hasType) {
      // Type only
      return getTranslated(context, navProvider.filterType!) ?? navProvider.filterType!;
    }
    
    return '';
  }
  
  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        
        return Column(
          children: [
            // Unified Filter Section with toggle
            _buildQuickFilterChips(context, navProvider, transactionProvider),
            
            _buildCalendar(context, provider),
            SizedBox(height: 8.h),
            
            // Danh sách giao dịch
            _buildTransactionList(context, provider, navProvider, transactionProvider),
          ],
        );
      },
    );
  }
  
  /// Widget hiển thị Quick Filter Chips cho Type và Category
  Widget _buildQuickFilterChips(BuildContext context, NavigationProvider navProvider, TransactionProvider transactionProvider) {
    // Lấy danh sách categories unique từ transactions
    final categories = <String>{};
    for (final tx in transactionProvider.allTransactions) {
      if (tx.category != null && tx.category!.isNotEmpty) {
        categories.add(tx.category!);
      }
    }
    final sortedCategories = categories.toList()..sort();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: blue1,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with toggle button and active filter status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: navProvider.hasActiveFilter 
                  ? (navProvider.filterColor ?? blue3).withValues(alpha: 0.08)
                  : Colors.transparent,
              border: navProvider.hasActiveFilter 
                  ? Border(
                      bottom: BorderSide(
                        color: (navProvider.filterColor ?? blue3).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Filter icon and title
                Icon(
                  Icons.filter_alt_outlined, 
                  size: 18.sp, 
                  color: navProvider.hasActiveFilter 
                      ? (navProvider.filterColor ?? blue3)
                      : Colors.grey[600],
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getTranslated(context, 'Filters') ?? 'Filters',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      // Show active filter info
                      if (navProvider.hasActiveFilter) ...[
                        SizedBox(height: 2.h),
                        Text(
                          _buildFilterDisplayText(context, navProvider),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: navProvider.filterColor ?? blue3,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Clear filter button (if active)
                if (navProvider.hasActiveFilter) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => navProvider.clearFilter(),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                ],
                
                // Toggle expand/collapse button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isFilterExpanded = !_isFilterExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      child: AnimatedRotation(
                        turns: _isFilterExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Animated filter chips section
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isFilterExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 8.h),
                      
                      // Type Filters Row
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Row(
                          children: [
                            Icon(Icons.compare_arrows, size: 14.sp, color: Colors.grey[600]),
                            SizedBox(width: 6.w),
                            Text(
                              getTranslated(context, 'Type') ?? 'Type',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            FilterChip(
                              label: Text(getTranslated(context, 'All') ?? 'All'),
                              labelStyle: TextStyle(fontSize: 11.sp),
                              selected: navProvider.filterType == null,
                              onSelected: (_) {
                                navProvider.clearFilter();
                              },
                              selectedColor: blue3.withValues(alpha: 0.2),
                              checkmarkColor: blue3,
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            SizedBox(width: 6.w),
                            FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_downward, size: 11.sp, color: navProvider.filterType == 'Income' ? blue3 : null),
                                  SizedBox(width: 4.w),
                                  Text(getTranslated(context, 'Income') ?? 'Income'),
                                ],
                              ),
                              labelStyle: TextStyle(fontSize: 11.sp),
                              selected: navProvider.filterType == 'Income',
                              onSelected: (selected) {
                                if (selected) {
                                  navProvider.navigateToCalendarWithFilter(
                                    type: 'Income',
                                    category: navProvider.filterCategory ?? '',
                                    icon: navProvider.filterIcon,
                                    color: blue3, // Đổi từ green thành blue3
                                  );
                                } else {
                                  navProvider.clearFilter();
                                }
                              },
                              selectedColor: blue3.withValues(alpha: 0.2), // Đổi từ green thành blue3
                              checkmarkColor: blue3, // Đổi từ green thành blue3
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            SizedBox(width: 6.w),
                            FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_upward, size: 11.sp, color: navProvider.filterType == 'Expense' ? blue2 : null), // Đổi từ red thành blue2
                                  SizedBox(width: 4.w),
                                  Text(getTranslated(context, 'Expense') ?? 'Expense'),
                                ],
                              ),
                              labelStyle: TextStyle(fontSize: 11.sp),
                              selected: navProvider.filterType == 'Expense',
                              onSelected: (selected) {
                                if (selected) {
                                  navProvider.navigateToCalendarWithFilter(
                                    type: 'Expense',
                                    category: navProvider.filterCategory ?? '',
                                    icon: navProvider.filterIcon,
                                    color: blue2, // Đổi từ red thành blue2
                                  );
                                } else {
                                  navProvider.clearFilter();
                                }
                              },
                              selectedColor: blue2.withValues(alpha: 0.2), // Đổi từ red thành blue2
                              checkmarkColor: blue2, // Đổi từ red thành blue2
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 8.h),
                      
                      // Category Filters Row (Scrollable)
                      if (sortedCategories.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Row(
                            children: [
                              Icon(Icons.category_outlined, size: 14.sp, color: Colors.grey[600]),
                              SizedBox(width: 6.w),
                              Text(
                                getTranslated(context, 'Category') ?? 'Category',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          height: 36.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            itemCount: sortedCategories.length,
                            itemBuilder: (context, index) {
                              final category = sortedCategories[index];
                              final isSelected = navProvider.filterCategory == category;
                              final categoryColor = _getCategoryColor(category, index);
                              
                              return Padding(
                                padding: EdgeInsets.only(right: 6.w),
                                child: FilterChip(
                                  label: Text(
                                    getTranslated(context, category) ?? category,
                                    style: TextStyle(fontSize: 11.sp),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      // Nếu chọn category: giữ nguyên type filter hiện tại (có thể là null = "All")
                                      navProvider.navigateToCalendarWithFilter(
                                        type: navProvider.filterType ?? '', // Empty string means no type filter
                                        category: category,
                                        icon: Icons.category,
                                        color: categoryColor,
                                      );
                                    } else {
                                      // If deselecting, clear only category filter, keep type filter
                                      if (navProvider.filterType != null && navProvider.filterType!.isNotEmpty) {
                                        navProvider.navigateToCalendarWithFilter(
                                          type: navProvider.filterType!,
                                          category: '',
                                          icon: navProvider.filterIcon,
                                          color: navProvider.filterColor,
                                        );
                                      } else {
                                        navProvider.clearFilter();
                                      }
                                    }
                                  },
                                  selectedColor: categoryColor.withValues(alpha: 0.2),
                                  checkmarkColor: categoryColor,
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 8.h),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
  
  /// Helper để lấy màu cho category
  Color _getCategoryColor(String category, int index) {
    // Sử dụng màu từ constants.dart hoặc generate based on index
    final colors = [
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFF44336), // Red
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF795548), // Brown
    ];
    return colors[index % colors.length];
  }
  
  Widget _buildCalendar(BuildContext context, CalendarProvider provider) {
    return TableCalendar(
      locale: Localizations.localeOf(context).languageCode,
      availableCalendarFormats: {
        CalendarFormat.month: getTranslated(context, 'Month')!,
        CalendarFormat.twoWeeks: getTranslated(context, '2 weeks')!,
        CalendarFormat.week: getTranslated(context, 'Week')!,
      },
      rowHeight: 40.h, // Giảm từ 52.h xuống 40.h để calendar nhỏ hơn
      daysOfWeekHeight: 22.h,
      firstDay: DateTime.utc(2015, 01, 01),
      lastDay: DateTime.utc(2100, 01, 01),
      focusedDay: provider.focusedDay,
      calendarFormat: provider.calendarFormat, // Sẽ đổi mặc định thành week ở CalendarProvider
      selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
      rangeStartDay: provider.rangeStart,
      rangeEndDay: provider.rangeEnd,
      rangeSelectionMode: provider.rangeSelectionMode,
      eventLoader: provider.getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: blue3,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16.sp,
        ),
        todayDecoration: BoxDecoration(
          color: blue2,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16.sp,
        ),
        defaultTextStyle: TextStyle(fontSize: 15.sp),
        weekendTextStyle: TextStyle(fontSize: 15.sp, color: red),
        outsideTextStyle: TextStyle(fontSize: 15.sp, color: Colors.grey),
        markerDecoration: BoxDecoration(
          color: Color.fromRGBO(67, 125, 229, 1),
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
        formatButtonTextStyle: TextStyle(
          fontSize: 15.sp,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        formatButtonDecoration: BoxDecoration(
          color: blue2,
          borderRadius: BorderRadius.circular(25.r),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isNotEmpty) {
            return Positioned(
              bottom: 4.h,
              child: _buildEventsMarker(events),
            );
          }
          return null;
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        provider.onDaySelected(selectedDay, focusedDay);
      },
      onRangeSelected: provider.onRangeSelected,
      onFormatChanged: provider.onFormatChanged,
      onPageChanged: provider.onPageChanged,
      pageJumpingEnabled: true,
    );
  }
  
  Widget _buildEventsMarker(List events) {
    double width = events.length < 100 ? 18.w : 28.w;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Color.fromRGBO(67, 125, 229, 1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      width: width,
      height: 16.h,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle(
            color: white,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  /// Tính toán khoảng thời gian dựa trên calendar format và focusedDay
  Map<String, DateTime> _calculateDateRange(CalendarProvider provider) {
    final focusedDay = provider.focusedDay;
    DateTime startDate, endDate;
    
    switch (provider.calendarFormat) {
      case CalendarFormat.week:
        // Tuần hiện tại: từ thứ 2 đến chủ nhật
        final startOfWeek = focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6);
        break;
        
      case CalendarFormat.twoWeeks:
        // 2 tuần: từ thứ 2 tuần trước đến chủ nhật tuần hiện tại
        final startOfCurrentWeek = focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
        startDate = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day - 7);
        endDate = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day + 6);
        break;
        
      case CalendarFormat.month:
        // Tháng hiện tại: từ ngày 1 đến cuối tháng
        startDate = DateTime(focusedDay.year, focusedDay.month, 1);
        endDate = DateTime(focusedDay.year, focusedDay.month + 1, 0);
        break;
    }
    
    return {'start': startDate, 'end': endDate};
  }
  
  /// Filter transactions theo khoảng thời gian
  List<InputModel> _filterTransactionsByDateRange(
    List<InputModel> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    return transactions.where((tx) {
      if (tx.date == null) return false;
      try {
        final txDate = DateFormatUtils.parseInternalDate(tx.date!);
        final normalizedTxDate = DateTime(txDate.year, txDate.month, txDate.day);
        final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
        final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
        
        // So sánh: startDate <= txDate <= endDate (inclusive both ends)
        return !normalizedTxDate.isBefore(normalizedStart) && !normalizedTxDate.isAfter(normalizedEnd);
      } catch (e) {
        return false;
      }
    }).toList();
  }
  
  /// Nhóm giao dịch theo ngày (sắp xếp từ mới đến cũ)
  List<MapEntry<DateTime, List<InputModel>>> _groupTransactionsByDate(
    CalendarProvider provider,
    NavigationProvider navProvider,
    TransactionProvider transactionProvider,
  ) {
    final Map<DateTime, List<InputModel>> grouped = {};
    final allTransactions = <InputModel>[];
    
    // Lấy base transactions
    var baseTransactions = transactionProvider.allTransactions;
    
    // Áp dụng filter type và category nếu có
    if (navProvider.hasActiveFilter) {
      baseTransactions = baseTransactions.where((tx) {
        // Filter by type - Only filter if type is not empty
        if (navProvider.filterType != null && 
            navProvider.filterType!.isNotEmpty && 
            tx.type != navProvider.filterType) {
          return false;
        }
        
        // Filter by category - Special handling for "Others"
        if (navProvider.filterCategory != null && 
            navProvider.filterCategory!.isNotEmpty && 
            !navProvider.isOthersCategory) {
          if (tx.category != navProvider.filterCategory) {
            return false;
          }
        }
        // If it's "Others" category, we show ALL transactions (filtered by type only)
        // This is because "Others" is a grouping of small categories, not a real category
        
        return true;
      }).toList();
    }
    
    // CASE 1: Nếu có ngày được chọn cụ thể VÀ KHÔNG CÓ FILTER
    // → Chỉ hiển thị transactions của ngày đó
    if (provider.selectedDay != null && !navProvider.hasActiveFilter) {
      allTransactions.addAll(provider.getEventsForDay(provider.selectedDay!));
    } 
    // CASE 2 & 3: Hiển thị theo calendar format hoặc date range từ filter
    else {
      
      // CASE 2: Nếu có filter date range từ Analysis screen
      if (navProvider.filterStartDate != null || navProvider.filterEndDate != null) {
        final startDate = navProvider.filterStartDate ?? DateTime(1990, 1, 1);
        final endDate = navProvider.filterEndDate ?? DateTime(2100, 12, 31);
        allTransactions.addAll(_filterTransactionsByDateRange(baseTransactions, startDate, endDate));
      } 
      // CASE 3: Filter theo calendar format (Week/2Weeks/Month)
      else {
        final dateRange = _calculateDateRange(provider);
        allTransactions.addAll(_filterTransactionsByDateRange(
          baseTransactions, 
          dateRange['start']!, 
          dateRange['end']!,
        ));
      }
    }
    
    // Nhóm theo ngày
    for (final transaction in allTransactions) {
      if (transaction.date == null) continue;
      
      try {
        // Parse from ISO format (yyyy-MM-dd)
        final date = DateFormatUtils.parseInternalDate(transaction.date!);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        
        if (!grouped.containsKey(normalizedDate)) {
          grouped[normalizedDate] = [];
        }
        grouped[normalizedDate]!.add(transaction);
      } catch (e) {
        // Bỏ qua giao dịch có format ngày không hợp lệ
      }
    }
    
    // Sắp xếp theo ngày: ưu tiên ngày hiện tại ở trên đầu, rồi các ngày khác theo thứ tự mới nhất
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        // Ngày hiện tại luôn ở trên đầu
        final aIsToday = a.key.year == today.year && a.key.month == today.month && a.key.day == today.day;
        final bIsToday = b.key.year == today.year && b.key.month == today.month && b.key.day == today.day;
        
        if (aIsToday && !bIsToday) return -1;
        if (!aIsToday && bIsToday) return 1;
        
        // Các ngày khác sắp xếp theo thứ tự mới nhất trước
        return b.key.compareTo(a.key);
      });
    
    return sortedEntries;
  }
  
  /// Xây dựng danh sách giao dịch nhóm theo ngày
  Widget _buildTransactionList(
    BuildContext context,
    CalendarProvider provider,
    NavigationProvider navProvider,
    TransactionProvider transactionProvider,
  ) {
    final groupedTransactions = _groupTransactionsByDate(provider, navProvider, transactionProvider);
    
    if (groupedTransactions.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 64.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16.h),
              Text(
                getTranslated(context, 'No transactions found') ?? 'No transactions found',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                getTranslated(context, 'Add some transactions to see them here') ?? 
                'Add some transactions to see them here',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Expanded(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        itemCount: groupedTransactions.length,
        itemBuilder: (context, index) {
          final entry = groupedTransactions[index];
          // Auto-expand first group (today or most recent)
          final isFirstGroup = index == 0;
          return DailyTransactionGroup(
            date: entry.key,
            transactions: entry.value,
            initiallyExpanded: isFirstGroup,
          );
        },
      ),
    );
  }
}
