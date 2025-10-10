import 'package:flutter/material.dart';
import '../utils/responsive_extensions.dart';

import 'package:provider/provider.dart';

import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider.dart';
import '../services/alert_service.dart';
import 'category_item.dart';
import 'constants.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback? onSave;
  final bool isLoading; // Thêm loading state

  const SaveButton({
    Key? key,
    this.onSave,
    this.isLoading = false, // Default false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: isLoading
            ? null
            : onSave,
        style: ElevatedButton.styleFrom(
          foregroundColor: white,
          backgroundColor: const Color.fromRGBO(236, 158, 66, 1),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
          disabledForegroundColor: grey.withValues(alpha: 0.38),
          disabledBackgroundColor: grey.withValues(alpha: 0.12),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0.r),
          ),
        ),
        label: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(white),
                ),
              )
            : Text(
                getTranslated(context, 'Save')!,
                style: TextStyle(fontSize: 25.sp),
              ),
        icon: isLoading
            ? SizedBox(width: 25.sp) // Placeholder để giữ spacing
            : Icon(
                Icons.save,
                size: 25.sp,
              ),
      ),
    );
  }
}

class SaveAndDeleteButton extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final bool isLoading; // Thêm trạng thái loading

  const SaveAndDeleteButton({
    Key? key,
    required this.onSave,
    required this.onDelete,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
            onPressed: onDelete,
            style: ElevatedButton.styleFrom(
                foregroundColor: red,
                backgroundColor: white,
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
                disabledForegroundColor: grey.withValues(alpha: 0.38),
                disabledBackgroundColor: grey.withValues(alpha: 0.12),
                side: BorderSide(
                  color: red,
                  width: 2.h,
                ),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0.r),
                )),
            icon: Icon(
              Icons.delete,
              size: 25.sp,
            ),
            label: Text(
              getTranslated(context, 'Delete')!,
              style: TextStyle(fontSize: 25.sp),
            )),
        SaveButton(
          onSave: onSave,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

Future<void> deleteCategoryFunction(
    {required BuildContext context,
    required String categoryName,
    String? parentExpenseItem,
    BuildContext? contextEx,
    contextExEdit,
    contextIn,
    contextInEdit}) async {
  void onDeletion() {
    if (contextInEdit != null) {
      List<CategoryItem> incomeItems = sharedPrefs.getItems('income items');
      incomeItems.removeWhere((item) => item.text == categoryName);
      sharedPrefs.saveItems('income items', incomeItems);
      Provider.of<ChangeIncomeItemEdit>(contextInEdit, listen: false)
          .getIncomeItems();
      if (contextIn != null) {
        Provider.of<ChangeIncomeItem>(contextIn, listen: false)
            .getIncomeItems();
      }
    } else {
      if (parentExpenseItem == null) {
        sharedPrefs.removeItem(categoryName);
        var parentExpenseItemNames = sharedPrefs.parentExpenseItemNames;
        parentExpenseItemNames.removeWhere(
            (parentExpenseItemName) => categoryName == parentExpenseItemName);
        sharedPrefs.parentExpenseItemNames = parentExpenseItemNames;
      } else {
        List<CategoryItem> expenseItems =
            sharedPrefs.getItems(parentExpenseItem);
        expenseItems.removeWhere((item) => item.text == categoryName);
        sharedPrefs.saveItems(parentExpenseItem, expenseItems);
      }
      Provider.of<ChangeExpenseItem>(contextEx!, listen: false)
          .getAllExpenseItems();
      Provider.of<ChangeExpenseItemEdit>(contextExEdit!, listen: false)
          .getAllExpenseItems();
    }
    Navigator.pop(context);
    AlertService.show(
      context,
      type: NotificationType.success,
      message: 'Category has been deleted',
    );
  }

  final confirmed = await AlertService.show(
    context,
    type: NotificationType.delete,
    title: 'Delete Category',
    message: 'Are you sure you want to delete this category?',
    actionText: 'Delete',
    cancelText: 'Cancel',
  );

  if (confirmed == true) {
    onDeletion();
  }
}
