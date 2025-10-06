/// Package import
import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

/// Chart import

import '../classes/alert_dialog.dart';
import '../classes/app_bar.dart';
import '../classes/constants.dart';
import '../classes/dropdown_box.dart';
import '../classes/input_model.dart';
import '../database_management/shared_preferences_services.dart';
import '../database_management/sqflite_services.dart';
import '../localization/methods.dart';
import '../provider.dart';
import '../services/alert_service.dart';
import 'edit.dart';

var year = todayDT.year;

class Report extends StatefulWidget {
  final String type;
  final String category;
  final String selectedDate;
  final IconData icon;
  const Report({
    required this.type,
    required this.category,
    required this.selectedDate,
    required this.icon,
  });

  @override
  _ReportState createState() => _ReportState();
}

class _ReportState extends State<Report> {
  @override
  Widget build(BuildContext context) {
    Color color = widget.type == getTranslated(context, 'Income') ? green : red;

    return Scaffold(
      backgroundColor: white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: BasicAppBar(getTranslated(context, 'Report')!),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 17.h,
              bottom: 15.h,
              left: 7.w,
              right: 7.w,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 15.w),
                  child: Icon(widget.icon, size: 30.sp, color: color),
                ),
                Flexible(
                  child: Text(
                    '${getTranslated(context, widget.category) ?? widget.category} ($year)',
                    style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: ReportBody(widget.type, widget.category, widget.selectedDate,
                color, widget.icon),
          )
        ],
      ),
    );
  }
}

class ReportBody extends StatefulWidget {
  final String type;
  final String category;
  final String selectedDate;
  final Color color;
  final IconData icon;
  ReportBody(
      this.type, this.category, this.selectedDate, this.color, this.icon);
  @override
  _ReportBodyState createState() => _ReportBodyState();
}

class _ReportBodyState extends State<ReportBody> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => InputModelList(),
        builder: (context, child) {
          return FutureBuilder<List<InputModel>>(
              initialData: [],
              future: Provider.of<InputModelList>(context).inputModelList,
              builder: (BuildContext context,
                  AsyncSnapshot<List<InputModel>> snapshot) {
                connectionUI(snapshot);
                if (snapshot.data == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox();
                } else {
                  double yearAmount = 0;
                  DateTime date(int duration) =>
                      startOfThisYear.add(Duration(days: duration));
                  bool isLeapYear(int year) {
                    return (year % 4 == 0) && (year % 100 != 0) ||
                        (year % 400 == 0);
                  }

                  // widget.transactions.sort((a, b) => a.date!.compareTo(b.date!));
                  List<InputModel> sortByCategory(
                      List<InputModel> data, String type) {
                    return data
                        .map((data) {
                          if (data.type == type &&
                              data.category == widget.category) {
                            return inputModel(data);
                          }
                        })
                        .where((element) => element != null)
                        .toList()
                        .cast<InputModel>();
                  }

                  List<InputModel> transactions = widget.type == 'Income'
                      ? sortByCategory(snapshot.data!, 'Income')
                      : sortByCategory(snapshot.data!, 'Expense');

                  List<InputModel> transactionsYearly = transactions
                          .map((data) {
                            DateTime dateSelectedDT =
                                DateFormat('dd/MM/yyyy').parse(data.date!);

                            if (dateSelectedDT.isAfter(startOfThisYear
                                    .subtract(Duration(days: 1))) &&
                                dateSelectedDT
                                    .isBefore(DateTime(todayDT.year, 12, 31))) {
                              return inputModel(data);
                            }
                          })
                          .where((element) => element != null)
                          .toList()
                      .cast<InputModel>();

                  if (transactionsYearly.isNotEmpty) {
                    for (InputModel? transaction in transactionsYearly) {
                      yearAmount = yearAmount + transaction!.amount!;
                    }
                  }

                  MonthAmount monthBasedTransaction(
                      String month, DateTime date, int days) {
                    double monthAmount = 0;
                    for (InputModel transaction in transactionsYearly) {
                      DateTime dateSelectedDT =
                          DateFormat('dd/MM/yyyy').parse(transaction.date!);

                      if (dateSelectedDT.isAfter(date) &&
                          dateSelectedDT.isBefore(
                              startOfThisYear.add(Duration(days: days)))) {
                        transaction.amount ??= 0;
                        monthAmount = monthAmount + transaction.amount!;
                      }
                    }
                    return MonthAmount(month, monthAmount);
                  }

                  List<MonthAmount>? monthBasedTransactionList =
                      isLeapYear(year)
                          ? [
                              monthBasedTransaction(
                                  getTranslated(context, 'Jan') ?? 'Jan',
                                  startOfThisYear.subtract(Duration(days: 1)),
                                  30),
                              monthBasedTransaction(getTranslated(context, 'Feb') ?? 'Feb', date(30), 59),
                              monthBasedTransaction(getTranslated(context, 'Mar') ?? 'Mar', date(59), 90),
                              monthBasedTransaction(getTranslated(context, 'Apr') ?? 'Apr', date(90), 120),
                              monthBasedTransaction(getTranslated(context, 'May') ?? 'May', date(120), 151),
                              monthBasedTransaction(getTranslated(context, 'Jun') ?? 'Jun', date(151), 181),
                              monthBasedTransaction(getTranslated(context, 'Jul') ?? 'Jul', date(181), 212),
                              monthBasedTransaction(getTranslated(context, 'Aug') ?? 'Aug', date(212), 243),
                              monthBasedTransaction(getTranslated(context, 'Sep') ?? 'Sep', date(243), 273),
                              monthBasedTransaction(getTranslated(context, 'Oct') ?? 'Oct', date(273), 303),
                              monthBasedTransaction(getTranslated(context, 'Nov') ?? 'Nov', date(303), 334),
                              monthBasedTransaction(getTranslated(context, 'Dec') ?? 'Dec', date(334), 365),
                            ]
                          : [
                              monthBasedTransaction(
                                  getTranslated(context, 'Jan') ?? 'Jan',
                                  startOfThisYear.subtract(Duration(days: 1)),
                                  30),
                              monthBasedTransaction(getTranslated(context, 'Feb') ?? 'Feb', date(30), 58),
                              monthBasedTransaction(getTranslated(context, 'Mar') ?? 'Mar', date(58), 89),
                              monthBasedTransaction(getTranslated(context, 'Apr') ?? 'Apr', date(89), 119),
                              monthBasedTransaction(getTranslated(context, 'May') ?? 'May', date(119), 150),
                              monthBasedTransaction(getTranslated(context, 'Jun') ?? 'Jun', date(150), 180),
                              monthBasedTransaction(getTranslated(context, 'Jul') ?? 'Jul', date(180), 211),
                              monthBasedTransaction(getTranslated(context, 'Aug') ?? 'Aug', date(211), 242),
                              monthBasedTransaction(getTranslated(context, 'Sep') ?? 'Sep', date(242), 272),
                              monthBasedTransaction(getTranslated(context, 'Oct') ?? 'Oct', date(272), 302),
                              monthBasedTransaction(getTranslated(context, 'Nov') ?? 'Nov', date(302), 333),
                              monthBasedTransaction(getTranslated(context, 'Dec') ?? 'Dec', date(333), 364),
                            ];

                  double maximumMonthAmount =
                      monthBasedTransactionList[0].amount;
                  for (int i = 0; i < monthBasedTransactionList.length; i++) {
                    if (monthBasedTransactionList[i].amount >
                        maximumMonthAmount) {
                      maximumMonthAmount = monthBasedTransactionList[i].amount;
                    }
                  }

                  return Column(
                    children: [
                      //                   Padding(
                      //                     padding: EdgeInsets.only(right: 8.0.w),
                      //                     child: SizedBox(
                      //                       height: 280.h,
                      //                       child: SfCartesianChart(
                      //                         primaryXAxis: CategoryAxis(
                      //                             // placeLabelsNearAxisLine: true,
                      //                             // edgeLabelPlacement: EdgeLabelPlacement.none,
                      //                             // majorTickLines: MajorTickLines(size: 5, width: 1),
                      //                             axisLine: AxisLine(
                      //                               width: 3.h,
                      //                             ),
                      //                             labelPlacement: LabelPlacement.onTicks,
                      //                             isVisible: true,
                      //                             labelRotation: -45,
                      //                             rangePadding: ChartRangePadding.none,
                      //                             majorGridLines: MajorGridLines(width: 0)),
                      //                         // tooltipBehavior: _tooltipBehavior,
                      //                         primaryYAxis: NumericAxis(
                      //                             majorGridLines: MajorGridLines(width: 0),
                      //                             minimum: 0,
                      //                             maximum: maximumMonthAmount,
                      //                             labelFormat: '{value}',
                      //                             axisLine: AxisLine(
                      //                               width: 4.h,
                      //                             ),
                      //                             majorTickLines: MajorTickLines(size: 5.sp)),
                      //          series: _getGradientAreaSeries(
                      // this.widget.type, monthBasedTransactionList),

                      //                         onMarkerRender: (MarkerRenderArgs args) {
                      //                           if (this.widget.type == 'Income') {
                      //                             if (args.pointIndex == 0) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(9, 110, 16, 1);
                      //                             } else if (args.pointIndex == 1) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(19, 134, 13, 1);
                      //                             } else if (args.pointIndex == 2) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(55, 171, 49, 1);
                      //                             } else if (args.pointIndex == 3) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(77, 213, 70, 1);
                      //                             } else if (args.pointIndex == 4) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(134, 213, 70, 1);
                      //                             } else if (args.pointIndex == 5) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(156, 222, 103, 1);
                      //                             } else if (args.pointIndex == 6) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(153, 249, 172, 1);
                      //                             } else if (args.pointIndex == 7) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(189, 235, 120, 1);
                      //                             } else if (args.pointIndex == 8) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(177, 249, 191, 1);
                      //                             } else if (args.pointIndex == 9) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(217, 241, 179, 1);
                      //                             } else if (args.pointIndex == 10) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(235, 246, 199, 1);
                      //                             } else if (args.pointIndex == 11) {
                      //                               args.color = Colors.white;
                      //                             }
                      //                           } else {
                      //                             if (args.pointIndex == 0) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(159, 16, 32, 1);
                      //                             } else if (args.pointIndex == 1) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(197, 71, 84, 1);
                      //                             } else if (args.pointIndex == 2) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(207, 124, 168, 1);
                      //                             } else if (args.pointIndex == 3) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(219, 128, 161, 1);
                      //                             } else if (args.pointIndex == 4) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(213, 143, 151, 1);
                      //                             } else if (args.pointIndex == 5) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(226, 157, 126, 1);
                      //                             } else if (args.pointIndex == 6) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(230, 168, 138, 1);
                      //                             } else if (args.pointIndex == 7) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(221, 176, 108, 1);
                      //                             } else if (args.pointIndex == 8) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(222, 187, 97, 1);
                      //                             } else if (args.pointIndex == 9) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(250, 204, 160, 1);
                      //                             } else if (args.pointIndex == 10) {
                      //                               args.color =
                      //                                   const Color.fromRGBO(248, 219, 191, 1);
                      //                             } else if (args.pointIndex == 11) {
                      //                               args.color = Colors.white;
                      //                             }
                      //                           }
                      //                         },
                      //                       ),
                      //                     ),
                      //                   ),
                      Text(
                        '${getTranslated(context, 'This year')}: ${format(yearAmount.toDouble())} $currency',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 17.5.sp, fontWeight: FontWeight.bold),
                      ),
                      ChangeNotifierProvider<ChangeSelectedDate>(
                          create: (context) => ChangeSelectedDate(),
                          child: Selector<ChangeSelectedDate, String?>(
                              selector: (_, changeSelectedDate) =>
                                  changeSelectedDate.selectedReportDate,
                              builder: (context, selectedAnalysisDate, child) {
                                selectedAnalysisDate ??= widget.selectedDate;

                                //selectedTransactions is data sorted by category and selectedDate
                                List<InputModel> selectedTransactions =
                                    filterData(context, transactions,
                                        selectedAnalysisDate);
                                double totalAmount = 0;
                                if (selectedTransactions.isNotEmpty) {
                                  for (InputModel? transaction
                                      in selectedTransactions) {
                                    totalAmount =
                                        totalAmount + transaction!.amount!;
                                  }
                                }
                                return Expanded(
                                  child: Column(
                                    children: [
                                      // selectedTransactions = selectedTransactions.reversed.toList();
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left:
                                                totalAmount.toString().length <
                                                        16
                                                    ? 10.w
                                                    : 6.w,
                                            right:
                                                totalAmount.toString().length <
                                                        15
                                                    ? 20.h
                                                    : 10.h,
                                            top: 25.h),
                                        child: Row(
                                          children: [
                                            DropDownBox(
                                                false, selectedAnalysisDate),
                                            Spacer(),
                                            Text(
                                              '${format(totalAmount.toDouble())} $currency',
                                              style: GoogleFonts.aBeeZee(
                                                  fontSize: format(totalAmount
                                                                  .toDouble())
                                                              .toString()
                                                              .length >
                                                          18
                                                      ? 14.sp
                                                      : format(totalAmount
                                                                      .toDouble())
                                                                  .toString()
                                                                  .length >
                                                              14
                                                          ? 17.sp
                                                          : 20.sp,
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.bold,
                                                  color: widget.color),
                                            )
                                          ],
                                        ),
                                      ),

                                      Divider(
                                        thickness: 0.5.h,
                                        height: 25.h,
                                        color: grey,
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount:
                                                selectedTransactions.length,
                                            itemBuilder: (context, index) {
                                              return GestureDetector(
                                                behavior:
                                                    HitTestBehavior.translucent,
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              Edit(
                                                                inputModel:
                                                                    selectedTransactions[
                                                                        index],
                                                                categoryIcon:
                                                                    widget.icon,
                                                              ))).then(
                                                      (value) => Provider.of<
                                                                  InputModelList>(
                                                              context,
                                                              listen: false)
                                                          .changeInputModelList());
                                                },
                                                child: SwipeActionCell(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  key: ObjectKey(
                                                      selectedTransactions[
                                                          index]),
                                                  firstActionWillCoverAllSpaceOnDeleting:
                                                      true,
                                                  trailingActions: <SwipeAction>[
                                                    SwipeAction(
                                                        title: getTranslated(
                                                                context,
                                                                'Delete') ??
                                                            'Delete',
                                                        onTap:
                                                            (CompletionHandler
                                                                handler) async {
                                                          Platform.isIOS
                                                              ? await iosDialog(
                                                                  context,
                                                                  'Are you sure you want to delete this transaction?',
                                                                  'Delete',
                                                                  () async {
                                                                  await DB.delete(
                                                                      selectedTransactions[
                                                                              index]
                                                                          .id!);
                                                                  await handler(
                                                                      true);
                                                                  Provider.of<InputModelList>(
                                                                          context,
                                                                          listen:
                                                                              false)
                                                                      .changeInputModelList();
                                                                  AlertService.show(
                                                                    context,
                                                                    type: NotificationType.success,
                                                                    message: getTranslated(context, 'Transaction has been deleted') ?? 'Transaction has been deleted',
                                                                  );
                                                                })
                                                              : await androidDialog(
                                                                  context,
                                                                  'Are you sure you want to delete this transaction?',
                                                                  'Delete',
                                                                  () async {
                                                                  await DB.delete(
                                                                      selectedTransactions[
                                                                              index]
                                                                          .id!);
                                                                  await handler(
                                                                      true);
                                                                  Provider.of<InputModelList>(
                                                                          context,
                                                                          listen:
                                                                              false)
                                                                      .changeInputModelList();
                                                                  AlertService.show(
                                                                    context,
                                                                    type: NotificationType.success,
                                                                    message: getTranslated(context, 'Transaction has been deleted') ?? 'Transaction has been deleted',
                                                                  );
                                                                });
                                                        },
                                                        color: red),
                                                    SwipeAction(
                                                        title: getTranslated(
                                                                context,
                                                                'Add') ??
                                                            'Add',
                                                        onTap:
                                                            (CompletionHandler
                                                                handler) {
                                                          var model =
                                                              selectedTransactions[
                                                                  index];
                                                          model.id = null;
                                                          DB.insert(model);
                                                          Provider.of<InputModelList>(
                                                                  context,
                                                                  listen: false)
                                                              .changeInputModelList();
                                                          AlertService.show(
                                                            context,
                                                            type: NotificationType.success,
                                                            message: getTranslated(context, 'Transaction has been updated') ?? 'Transaction has been updated',
                                                          );
                                                        },
                                                        color: Color.fromRGBO(
                                                            255, 183, 121, 1)),
                                                  ],
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 15.w,
                                                        right: 15.w,
                                                        top: 7.h),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          // Sử dụng Expanded thay vì Flexible
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text: DateFormat(
                                                                          sharedPrefs
                                                                              .dateFormat)
                                                                      .format(DateFormat(
                                                                              'dd/MM/yyyy')
                                                                          .parse(
                                                                              selectedTransactions[index].date!)),
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        17.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                    text: '\n'),
                                                                TextSpan(
                                                                  text: selectedTransactions[
                                                                          index]
                                                                      .description!,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        17.sp,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Spacer(), // Đẩy phần tử tiếp theo về phía cuối dòng
                                                        Text(
                                                          '${format(selectedTransactions[index].amount!)} $currency',
                                                          style: TextStyle(
                                                              fontSize:
                                                                  18.5.sp),
                                                        ),
                                                        SizedBox(
                                                            width: 5
                                                                .w), // Khoảng cách giữa số tiền và biểu tượng ">"
                                                        Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                          size: 17.sp,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                      )
                                    ],
                                  ),
                                );
                              }))
                    ],
                  );
                }
              });
        });
  }
}

class MonthAmount {
  final String month;
  final double amount;
  const MonthAmount(this.month, this.amount);
}
