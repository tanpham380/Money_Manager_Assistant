import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:google_fonts/google_fonts.dart';
import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../localization/methods.dart';
import '../database_management/shared_preferences_services.dart';
import '../utils/category_icon_helper.dart';

/// Widget hiển thị một giao dịch trong danh sách với swipe actions
class TransactionListItem extends StatelessWidget {
  final InputModel transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  
  const TransactionListItem({
    Key? key,
    required this.transaction,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == 'Income';
    final Color categoryColor = isIncome ? Colors.lightGreen : red;
    
    // Lấy icon từ category name
    final IconData categoryIcon = CategoryIconHelper.getIconForCategory(
      transaction.category ?? 'Unknown',
    );
    
    return SwipeActionCell(
      key: ObjectKey(transaction),
      firstActionWillCoverAllSpaceOnDeleting: true,
      trailingActions: <SwipeAction>[
        // Delete action
        SwipeAction(
          title: getTranslated(context, 'Delete') ?? 'Delete',
          onTap: (CompletionHandler handler) async {
            await handler(true);
            onDelete();
          },
          color: red,
          content: Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24.sp,
          ),
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Duplicate action
        SwipeAction(
          title: getTranslated(context, 'Duplicate') ?? 'Duplicate',
          onTap: (CompletionHandler handler) async {
            await handler(false);
            onDuplicate();
          },
          color: Color.fromRGBO(255, 183, 121, 1),
          content: Icon(
            Icons.content_copy,
            color: Colors.white,
            size: 24.sp,
          ),
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
      child: Card(
        elevation: 3.0,
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          splashColor: categoryColor.withOpacity(0.1),
          highlightColor: categoryColor.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                // Icon Category
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: categoryColor.withOpacity(0.15),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 28.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // Category, Description, Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category name
                      Text(
                        getTranslated(context, transaction.category ?? 'Unknown') ??
                            transaction.category ??
                            'Unknown',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 2.h),
                      
                      // Description
                      if (transaction.description != null &&
                          transaction.description!.isNotEmpty)
                        Text(
                          transaction.description!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // Time
                      if (transaction.time != null)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12.sp,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                transaction.time!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(width: 8.w),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${isIncome ? '+' : '-'} ${format(transaction.amount ?? 0)}',
                        style: GoogleFonts.aBeeZee(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      currency,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
