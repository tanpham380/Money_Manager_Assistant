import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../classes/app_bar.dart';
import '../classes/constants.dart';
import '../classes/daily_transaction_group.dart';
import '../classes/input_model.dart';
import '../localization/methods.dart';
import '../provider/calendar_provider.dart';
import 'daily_transaction_detail.dart';

class Calendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarProvider(),
      child: Scaffold(
        backgroundColor: blue1,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: BasicAppBar(getTranslated(context, 'Calendar')!),
        ),
        body: Consumer<CalendarProvider>(
          builder: (context, provider, child) {
            if (provider.state == CalendarState.loading) {
              return Center(
                child: CircularProgressIndicator(color: blue3),
              );
            }
            
            if (provider.state == CalendarState.error) {
              return Center(
                child: Text(
                  provider.errorMessage ?? 'An error occurred',
                  style: TextStyle(color: red, fontSize: 16.sp),
                ),
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
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildCalendar(context, provider),
            SizedBox(height: 8.h),
            if (provider.selectedDayEvents.isNotEmpty && provider.rangeStart == null)
            Expanded(
              child: _buildTransactionList(context, provider),
            ),
          ],
        );
      },
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
      rowHeight: 52.h,
      daysOfWeekHeight: 22.h,
      firstDay: DateTime.utc(2015, 01, 01),
      lastDay: DateTime.utc(2100, 01, 01),
      focusedDay: provider.focusedDay,
      calendarFormat: provider.calendarFormat,
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
      onDaySelected: provider.onDaySelected,
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
  
  Widget _buildTransactionList(BuildContext context, CalendarProvider provider) {
    // Kiểm tra xem có đang ở chế độ range selection không
    final isRangeMode = provider.rangeStart != null || provider.rangeEnd != null;
    
    // Nếu đang ở range mode, show empty state
    if (isRangeMode) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              getTranslated(context, 'Select a single day to view transactions') ??
                  'Select a single day to view transactions',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Nhóm giao dịch theo ngày từ tất cả các ngày có dữ liệu
    final groupedTransactions = _groupTransactionsByDate(provider);
    
    if (groupedTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              getTranslated(context, 'No transactions found') ??
                  'No transactions found',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: 8.h,
          bottom: 24.h,
          left: 4.w,
          right: 4.w,
        ),
        itemCount: groupedTransactions.length,
        itemBuilder: (context, index) {
          final entry = groupedTransactions[index];
          final date = entry.key;
          final transactions = entry.value;
          
          return DailyTransactionGroup(
            date: date,
            transactions: transactions,
            onTap: () {
              // Chuyển sang màn hình chi tiết
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DailyTransactionDetail(
                    date: date,
                    transactions: transactions,
                  ),
                ),
              ).then((_) {
                // Reload data khi quay lại
                provider.fetchTransactions();
              });
            },
          );
        },
      ),
    );
  }
  
  /// Nhóm giao dịch theo ngày (sắp xếp từ mới đến cũ)
  List<MapEntry<DateTime, List<InputModel>>> _groupTransactionsByDate(
    CalendarProvider provider,
  ) {
    final Map<DateTime, List<InputModel>> grouped = {};
    
    // Lấy tất cả giao dịch từ selectedDay hoặc focusedMonth
    final allTransactions = <InputModel>[];
    
    // Nếu có ngày được chọn, chỉ lấy giao dịch của ngày đó
    if (provider.selectedDay != null) {
      allTransactions.addAll(provider.getEventsForDay(provider.selectedDay!));
    } else {
      // Ngược lại, lấy tất cả giao dịch trong tháng hiện tại
      final firstDayOfMonth = DateTime(
        provider.focusedDay.year,
        provider.focusedDay.month,
        1,
      );
      final lastDayOfMonth = DateTime(
        provider.focusedDay.year,
        provider.focusedDay.month + 1,
        0,
      );
      
      // Lấy tất cả ngày trong tháng
      for (var day = firstDayOfMonth;
           day.isBefore(lastDayOfMonth.add(Duration(days: 1)));
           day = day.add(Duration(days: 1))) {
        final events = provider.getEventsForDay(day);
        if (events.isNotEmpty) {
          allTransactions.addAll(events);
        }
      }
    }
    
    // Nhóm theo ngày
    for (final transaction in allTransactions) {
      if (transaction.date == null) continue;
      
      try {
        final date = DateFormat('dd/MM/yyyy').parse(transaction.date!);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        
        if (!grouped.containsKey(normalizedDate)) {
          grouped[normalizedDate] = [];
        }
        grouped[normalizedDate]!.add(transaction);
      } catch (e) {
        // Bỏ qua giao dịch có format ngày không hợp lệ
      }
    }
    
    // Sắp xếp theo ngày (mới nhất trước)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    
    return sortedEntries;
  }
}
