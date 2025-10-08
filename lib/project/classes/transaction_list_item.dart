import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';
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
    final Color categoryColor = isIncome ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error; // Use theme colors
    
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
          color: Theme.of(context).colorScheme.error, // Use theme error color
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
          color: Theme.of(context).colorScheme.primary, // Use theme primary color
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent để phù hợp với SwipeActionCell
          borderRadius: BorderRadius.circular(16.r), // Tăng bo tròn cho đẹp hơn
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r), // Đồng nhất với Container
          splashColor: categoryColor.withValues(alpha: 0.1),
          highlightColor: categoryColor.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9), // Màu trắng nhạt để phù hợp với group
              // borderRadius: BorderRadius.circular(16.r), // Bo tròn đồng nhất
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), // Padding
            child: Row(
              children: [
                // Icon Category - Thu nhỏ hơn
                CircleAvatar(
                  radius: 20.r, // Giảm từ 24.r xuống 20.r
                  backgroundColor: categoryColor.withValues(alpha: 0.15),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor.withValues(alpha: 0.8), // Làm nhạt màu icon
                    size: 24.sp, // Giảm từ 28.sp xuống 24.sp
                  ),
                ),
                
                SizedBox(width: 10.w), // Giảm từ 12.w xuống 10.w
                
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
                          fontSize: 14.sp, // Giảm từ 16.sp xuống 14.sp
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface, // Use theme onSurface
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 1.h), // Giảm từ 2.h xuống 1.h
                      
                      // Description
                      if (transaction.description != null &&
                          transaction.description!.isNotEmpty)
                        Text(
                          transaction.description!,
                          style: TextStyle(
                            fontSize: 12.sp, // Giảm từ 13.sp xuống 12.sp
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), // Use theme onSurface with alpha
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // Time
                      if (transaction.time != null)
                        Padding(
                          padding: EdgeInsets.only(top: 1.h), // Giảm từ 2.h xuống 1.h
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 11.sp, // Giảm từ 12.sp xuống 11.sp
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), // Use theme onSurface with alpha
                              ),
                              SizedBox(width: 3.w), // Giảm từ 4.w xuống 3.w
                              Text(
                                transaction.time!,
                                style: TextStyle(
                                  fontSize: 10.sp, // Giảm từ 11.sp xuống 10.sp
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), // Use theme onSurface with alpha
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(width: 6.w), // Giảm từ 8.w xuống 6.w
                
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
                          fontSize: 14.sp, // Giảm từ 16.sp xuống 14.sp
                          fontWeight: FontWeight.bold,
                          color: categoryColor.withValues(alpha: 0.8), // Làm nhạt màu amount
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h), // Giảm từ 2.h xuống 1.h
                    Text(
                      currency,
                      style: TextStyle(
                        fontSize: 11.sp, // Giảm từ 12.sp xuống 11.sp
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), // Use theme onSurface with alpha
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
