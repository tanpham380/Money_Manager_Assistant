import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../classes/app_bar.dart';
import '../classes/constants.dart';
import '../classes/daily_transaction_group.dart';
import '../classes/input_model.dart';
import '../classes/state_widgets.dart';
import '../localization/methods.dart';
import '../provider/calendar_provider.dart';
import '../provider/transaction_provider.dart';
import '../provider/navigation_provider.dart';

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

class _CalendarContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Hiển thị thanh filter nếu có filter active
            if (navProvider.hasActiveFilter)
              _buildFilterStatusBar(context, navProvider),
            
            _buildCalendar(context, provider),
            SizedBox(height: 8.h),
            
            // Danh sách giao dịch
            _buildTransactionList(context, provider, navProvider, 
              Provider.of<TransactionProvider>(context, listen: false)),
          ],
        );
      },
    );
  }
  
  /// Widget hiển thị thanh trạng thái filter
  Widget _buildFilterStatusBar(BuildContext context, NavigationProvider navProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: (navProvider.filterColor ?? blue3).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: (navProvider.filterColor ?? blue3).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon của category
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: (navProvider.filterColor ?? blue3).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              navProvider.filterIcon ?? Icons.filter_list,
              color: navProvider.filterColor ?? blue3,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          
          // Thông tin filter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated(context, 'Filtered by') ?? 'Filtered by',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${getTranslated(context, navProvider.filterType ?? '')} - ${getTranslated(context, navProvider.filterCategory ?? '')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: navProvider.filterColor ?? blue3,
                    fontSize: 15.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Nút clear filter
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                navProvider.clearFilter();
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.close_rounded,
                  size: 22.sp,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
  
  /// Nhóm giao dịch theo ngày (sắp xếp từ mới đến cũ)
  List<MapEntry<DateTime, List<InputModel>>> _groupTransactionsByDate(
    CalendarProvider provider,
    NavigationProvider navProvider,
    TransactionProvider transactionProvider,
  ) {
    final Map<DateTime, List<InputModel>> grouped = {};
    
    // Lấy tất cả giao dịch từ selectedDay hoặc focusedMonth
    final allTransactions = <InputModel>[];
    
    // Nếu có ngày được chọn, chỉ hiển thị transactions của ngày đó
    if (provider.selectedDay != null) {
      allTransactions.addAll(provider.getEventsForDay(provider.selectedDay!));
    } else {
      // Nếu không có ngày được chọn, lấy transactions theo filter thời gian
      final baseTransactions = navProvider.hasActiveFilter 
        ? transactionProvider.allTransactions.where((tx) {
            if (navProvider.filterType != null && tx.type != navProvider.filterType) {
              return false;
            }
            if (navProvider.filterCategory != null && tx.category != navProvider.filterCategory) {
              return false;
            }
            return true;
          }).toList()
        : transactionProvider.allTransactions;
      
      // Filter theo khoảng thời gian từ NavigationProvider (nếu có)
      List<InputModel> timeFilteredTransactions = baseTransactions;
      if (navProvider.filterStartDate != null || navProvider.filterEndDate != null) {
        timeFilteredTransactions = baseTransactions.where((tx) {
          if (tx.date == null) return false;
          try {
            // Parse from ISO format (yyyy-MM-dd)
            final txDate = DateFormat('yyyy-MM-dd').parse(tx.date!);
            final normalizedTxDate = DateTime(txDate.year, txDate.month, txDate.day);
            
            if (navProvider.filterStartDate != null) {
              final startDate = DateTime(
                navProvider.filterStartDate!.year,
                navProvider.filterStartDate!.month,
                navProvider.filterStartDate!.day,
              );
              if (normalizedTxDate.isBefore(startDate)) return false;
            }
            
            if (navProvider.filterEndDate != null) {
              final endDate = DateTime(
                navProvider.filterEndDate!.year,
                navProvider.filterEndDate!.month,
                navProvider.filterEndDate!.day,
              );
              if (normalizedTxDate.isAfter(endDate)) return false;
            }
            
            return true;
          } catch (e) {
            return false;
          }
        }).toList();
      } else {
        // Nếu không có filter thời gian từ NavigationProvider, filter theo calendar format
        switch (provider.calendarFormat) {
          case CalendarFormat.month:
            // Hiển thị transactions trong tháng hiện tại
            timeFilteredTransactions = baseTransactions.where((tx) {
              if (tx.date == null) return false;
              try {
                // Parse from ISO format (yyyy-MM-dd)
                final txDate = DateFormat('yyyy-MM-dd').parse(tx.date!);
                return txDate.year == provider.focusedDay.year && 
                       txDate.month == provider.focusedDay.month;
              } catch (e) {
                return false;
              }
            }).toList();
            break;
            
          case CalendarFormat.twoWeeks:
          case CalendarFormat.week:
            // Tính ngày bắt đầu tuần (thứ 2) của tuần chứa focusedDay
            final startOfCurrentWeek = provider.focusedDay.subtract(Duration(days: provider.focusedDay.weekday - 1));
            
            DateTime startDate, endDate;
            if (provider.calendarFormat == CalendarFormat.week) {
              // Tuần hiện tại: từ thứ 2 đến chủ nhật
              startDate = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);
              endDate = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day + 6, 23, 59, 59);
            } else {
              // 2 tuần: từ thứ 2 tuần trước đến chủ nhật tuần hiện tại
              startDate = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day - 7);
              endDate = DateTime(startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day + 6, 23, 59, 59);
            }
            
            timeFilteredTransactions = baseTransactions.where((tx) {
              if (tx.date == null) return false;
              try {
                // Parse from ISO format (yyyy-MM-dd)
                final txDate = DateFormat('yyyy-MM-dd').parse(tx.date!);
                final normalizedTxDate = DateTime(txDate.year, txDate.month, txDate.day);
                return !normalizedTxDate.isBefore(startDate) && !normalizedTxDate.isAfter(endDate);
              } catch (e) {
                return false;
              }
            }).toList();
            break;
        }
      }
      
      allTransactions.addAll(timeFilteredTransactions);
    }
    
    // Nhóm theo ngày
    for (final transaction in allTransactions) {
      if (transaction.date == null) continue;
      
      try {
        // Parse from ISO format (yyyy-MM-dd)
        final date = DateFormat('yyyy-MM-dd').parse(transaction.date!);
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
          return DailyTransactionGroup(
            date: entry.key,
            transactions: entry.value,
          );
        },
      ),
    );
  }
}
