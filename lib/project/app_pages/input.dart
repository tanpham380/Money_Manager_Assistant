import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_material_pickers/helpers/show_date_picker.dart';
 import '../utils/responsive_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:icofont_flutter/icofont_flutter.dart';
import '../classes/app_bar.dart';
import '../classes/category_item.dart';
import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../classes/keyboard.dart';
import '../classes/saveOrSaveAndDeleteButtons.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider/form_provider.dart';
import '../provider/transaction_provider.dart';
import 'expense_category.dart';
import 'income_category.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';

class AddInput extends StatefulWidget {
  @override
  _AddInputState createState() => _AddInputState();
}

class _AddInputState extends State<AddInput> {
  static final _formKey1 = GlobalKey<FormState>(debugLabel: '_formKey1'),
      _formKey2 = GlobalKey<FormState>(debugLabel: '_formKey2');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasFocus || !currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: DefaultTabController(
          initialIndex: 0,
          length: 2,
          child: Scaffold(
              backgroundColor: blue1,
              appBar: InExAppBar(true),
              body: TabBarView(
                children: [
                  AddEditInput(
                    type: 'Expense',
                    formKey: _formKey2,
                  ),
                  AddEditInput(
                    type: 'Income',
                    formKey: _formKey1,
                  )
                ],
              ))),
    );
  }
}

class PanelForKeyboard extends StatelessWidget {
  const PanelForKeyboard(
    this.body, {
    required this.formProvider,
    Key? key,
  }) : super(key: key);

  final Widget body;
  final FormProvider formProvider;

  @override
  Widget build(BuildContext context) {
    // Luôn sử dụng provider được truyền vào
    final provider = formProvider;

    return SlidingUpPanel(
        controller: provider.panelController,
        minHeight: 0,
        maxHeight: 300.h,
        parallaxEnabled: true,
        isDraggable: false,
        panelSnapping: true,
        panel: CustomKeyboard(
          panelController: provider.panelController,
          mainFocus: provider.amountFocusNode,
          nextFocus: provider.descriptionFocusNode,
          onTextInput: provider.insertAmountText,
          onBackspace: provider.backspaceAmount,
          page: provider.model.type == 'Income'
              ? IncomeCategory()
              : ExpenseCategory(),
        ),
        body: body);
  }
}

class AddEditInput extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final InputModel? inputModel;
  final String? type;
  final IconData? categoryIcon;
  const AddEditInput({
    required this.formKey,
    this.inputModel,
    this.type,
    this.categoryIcon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the TransactionProvider from the ancestor (Home widget)
    return ChangeNotifierProxyProvider<TransactionProvider, FormProvider>(
      create: (context) {
        // Don't access TransactionProvider here - it will be provided in update
        // Create a temporary FormProvider that will be replaced by update
        return FormProvider(
          input: inputModel,
          type: type,
          categoryIcon: categoryIcon,
          transactionProvider: context.read<TransactionProvider>(),
        );
      },
      update: (context, transactionProvider, previous) {
        // If previous exists and has the same input, reuse it
        if (previous != null && 
            previous.model.id == inputModel?.id &&
            previous.model.type == (type ?? inputModel?.type)) {
          return previous;
        }
        // Otherwise create new FormProvider with the TransactionProvider
        return FormProvider(
          input: inputModel,
          type: type,
          categoryIcon: categoryIcon,
          transactionProvider: transactionProvider,
        );
      },
      child: Consumer<FormProvider>(
        builder: (context, provider, child) {
          return PanelForKeyboard(
            formProvider: provider, // Truyền provider vào
            ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              children: [
                // Card cho AmountCard
                Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0.w),
                    child: const AmountCard(),
                  ),
                ),

                // Smart Suggestions
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0.h),
                  child: Consumer<FormProvider>(
                    builder: (context, provider, child) {
                      // Chỉ hiển thị gợi ý cho tab 'Expense'
                      if (provider.model.type != 'Expense') {
                        return const SizedBox.shrink();
                      }

                      return Wrap(
                        spacing: 8.0.w,
                        runSpacing: 4.0.h,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.free_breakfast_outlined,
                                size: 18),
                            label: Text(
                              getTranslated(context, 'Breakfast') ??
                                  'Breakfast',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onPressed: () {
                              final p = context.read<FormProvider>();
                              p.descriptionController.text =
                                  getTranslated(context, 'Breakfast') ??
                                      'Breakfast';
                              p.updateCategory(
                                  categoryItem(MdiIcons.food, 'Food'));
                            },
                          ),
                          ActionChip(
                            avatar:
                                const Icon(Icons.restaurant_outlined, size: 18),
                            label: Text(
                              getTranslated(context, 'Lunch') ?? 'Lunch',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onPressed: () {
                              final p = context.read<FormProvider>();
                              p.descriptionController.text =
                                  getTranslated(context, 'Lunch') ?? 'Lunch';
                              p.updateCategory(
                                  categoryItem(MdiIcons.food, 'Food'));
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.dinner_dining_outlined,
                                size: 18),
                            label: Text(
                              getTranslated(context, 'Dinner') ?? 'Dinner',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onPressed: () {
                              final p = context.read<FormProvider>();
                              p.descriptionController.text =
                                  getTranslated(context, 'Dinner') ?? 'Dinner';
                              p.updateCategory(
                                  categoryItem(MdiIcons.food, 'Food'));
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.coffee_outlined, size: 18),
                            label: Text(
                              getTranslated(context, 'Coffee') ?? 'Coffee',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onPressed: () {
                              final p = context.read<FormProvider>();
                              p.descriptionController.text =
                                  getTranslated(context, 'Coffee') ?? 'Coffee';
                              p.updateCategory(
                                  categoryItem(Icons.coffee, 'Coffee'));
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.wifi_outlined, size: 18),
                            label: Text(
                              getTranslated(context, 'Internet') ?? 'Internet',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onPressed: () {
                              final p = context.read<FormProvider>();
                              p.descriptionController.text =
                                  getTranslated(context, 'Internet') ??
                                      'Internet';
                              p.updateCategory(
                                  categoryItem(IcoFontIcons.globe, 'Internet'));
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.shopping_cart_outlined,
                                size: 18),
                            label: Text(
                              getTranslated(context, 'Daily Necessities') ??
                                  'Daily Necessities',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onPressed: () {
                              final p = context.read<FormProvider>();
                              p.descriptionController.text =
                                  getTranslated(context, 'Daily Necessities') ??
                                      'Daily Necessities';
                              p.updateCategory(categoryItem(
                                  Icons.add_shopping_cart,
                                  'Daily Necessities'));
                            },
                          ),
                          ActionChip(
                            avatar:
                                const Icon(Icons.local_gas_station, size: 18),
                            label: Text(
                              getTranslated(context, 'Fuel') ?? 'Fuel',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onPressed: () {
                              final p = context.read<FormProvider>();
                              p.descriptionController.text =
                                  getTranslated(context, 'Fuel') ?? 'Fuel';
                              p.updateCategory(categoryItem(
                                  Icons.local_gas_station, 'Fuel'));
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.movie_outlined, size: 18),
                            label: Text(
                              getTranslated(context, 'Movies') ?? 'Movies',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onPressed: () {
                              final p = context.read<FormProvider>();
                              p.descriptionController.text =
                                  getTranslated(context, 'Movies') ?? 'Movies';
                              p.updateCategory(
                                  categoryItem(Icons.movie_filter, 'Movies'));
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16.0),

                // Card cho nhóm Category, Description, Date
                Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0.r),
                  ),
                  child: Column(
                    children: [
                      const CategoryCard(),
                      Divider(height: 1, indent: 16.w, endIndent: 16.w),
                      const DescriptionCard(),
                      Divider(height: 1, indent: 16.w, endIndent: 16.w),
                      const DateCard(),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(vertical: 70.h),
                  child: inputModel != null
                      ? SaveAndDeleteButton(
                          saveAndDeleteInput: true,
                          formKey: formKey,
                          onSave: () =>
                              provider.saveInput(context, isNewInput: false),
                          onDelete: () => _showDeleteDialog(context, provider),
                        )
                      : SaveButton(
                          saveInput: true,
                          onSave: () =>
                              provider.saveInput(context, isNewInput: true),
                          isLoading: provider.isLoading,
                        ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context, FormProvider provider) async {
    // deleteInput đã có confirmation built-in
    await provider.deleteInput(context);
  }
}

class AmountCard extends StatelessWidget {
  const AmountCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FormProvider>(
      builder: (context, provider, child) {
        final colorMain = provider.model.type == 'Income' ? green : red;
        final amountController = provider.amountController;

        return Padding(
          padding:
              EdgeInsets.only(top: 5.h, bottom: 15.h, right: 20.w, left: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${getTranslated(context, 'Amount')}',
                style: TextStyle(
                  fontSize: 22.sp,
                ),
              ),
              TextFormField(
                controller: amountController,
                readOnly: true,
                showCursor: true,
                maxLines: null,
                minLines: 1,
                onTap: () {
                  // Request focus và mở panel bàn phím
                  provider.amountFocusNode.requestFocus();

                  // Mở panel nếu chưa mở
                  if (!provider.panelController.isPanelOpen) {
                    provider.panelController.open();
                  }
                },
                cursorColor: colorMain,
                style: GoogleFonts.aBeeZee(
                    color: colorMain,
                    fontSize: 35.sp,
                    fontWeight: FontWeight.bold),
                focusNode: provider.amountFocusNode,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.aBeeZee(
                      color: colorMain,
                      fontSize: 35.sp,
                      fontWeight: FontWeight.bold),
                  icon: Padding(
                    padding: EdgeInsets.only(right: 5.w),
                    child: Icon(
                      Icons.monetization_on,
                      size: 30.sp,
                      color: colorMain,
                    ),
                  ),
                  suffixIcon: amountController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 24.sp,
                          ),
                          onPressed: amountController.clear)
                      : const SizedBox(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FormProvider>(
      builder: (context, provider, child) {
        final categoryItem = provider.selectedCategory;
        final isDefaultCategory = categoryItem.text == 'Category';

        return GestureDetector(
          onTap: () async {
            CategoryItem? newCategoryItem = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => provider.model.type == 'Income'
                      ? IncomeCategory()
                      : ExpenseCategory()),
            );

            if (newCategoryItem != null) {
              provider.updateCategory(newCategoryItem);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              // Highlight màu đỏ nhạt nếu chưa chọn category
              color: isDefaultCategory
                  ? Colors.red.withValues(alpha: 0.05)
                  : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isDefaultCategory ? Colors.red : Colors.transparent,
                  width: 4.w,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                  left: 20.w, right: 20.w, top: 20.h, bottom: 21.h),
              child: Row(
                children: [
                  // Icon(
                  //   iconData(categoryItem),
                  //   size: 40.sp,
                  //   color: isDefaultCategory
                  //       ? Colors.grey
                  //       : (provider.model.type == 'Income' ? green : red),
                  // ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 31.w),
                      child: Text(
                        getTranslated(context, categoryItem.text) ??
                            categoryItem.text,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: isDefaultCategory ? Colors.grey : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 20.sp,
                    color: isDefaultCategory ? Colors.red : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DescriptionCard extends StatelessWidget {
  const DescriptionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FormProvider>(
      builder: (context, provider, child) {
        final descriptionController = provider.descriptionController;
        final colorMain = provider.model.type == 'Income' ? green : red;

        return Column(
          children: [
            // Input field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.5.h),
              child: TextFormField(
                controller: descriptionController,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.text,
                keyboardAppearance: Brightness.light,
                cursorColor: colorMain,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 20.sp),
                focusNode: provider.descriptionFocusNode,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  // Đóng keyboard khi nhấn Done
                  provider.descriptionFocusNode.unfocus();
                },
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: getTranslated(context, 'Description'),
                    hintStyle: GoogleFonts.cousine(
                      fontSize: 22.sp,
                      fontStyle: FontStyle.italic,
                    ),
                    suffixIcon: descriptionController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 20.sp,
                            ),
                            onPressed: descriptionController.clear)
                        : const SizedBox(),
                    icon: Padding(
                      padding: EdgeInsets.only(right: 15.w),
                      child: Icon(
                        Icons.description_outlined,
                        size: 40.sp,
                        color: Colors.blueGrey,
                      ),
                    )),
              ),
            ),

            // Keyboard control bar - hiển thị khi focus
            if (provider.descriptionFocusNode.hasFocus)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back to Amount button - nhỏ hơn
                    TextButton.icon(
                      icon: Icon(Icons.arrow_upward,
                          size: 16.sp, color: colorMain),
                      label: Text(
                        getTranslated(context, 'Amount') ?? 'Amount',
                        style: TextStyle(fontSize: 13.sp, color: colorMain),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                      ),
                      onPressed: () {
                        provider.descriptionFocusNode.unfocus();
                        Future.delayed(Duration(milliseconds: 100), () {
                          provider.amountFocusNode.requestFocus();
                          if (!provider.panelController.isPanelOpen) {
                            provider.panelController.open();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class DateCard extends StatelessWidget {
  const DateCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FormProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: EdgeInsets.only(
              left: 20.w, right: 20.w, top: 17.5.h, bottom: 19.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  showMaterialDatePicker(
                    headerColor: blue3,
                    headerTextColor: Colors.black,
                    backgroundColor: white,
                    buttonTextColor: const Color.fromRGBO(80, 157, 253, 1),
                    cancelText: getTranslated(context, 'CANCEL'),
                    confirmText: getTranslated(context, 'OK') ?? 'OK',
                    maxLongSide: 450.w,
                    maxShortSide: 300.w,
                    title: getTranslated(context, 'Select a date'),
                    context: context,
                    firstDate: DateTime(1990, 1, 1),
                    lastDate: DateTime(2100, 12, 31),
                    selectedDate:
                        DateFormat('dd/MM/yyyy').parse(provider.model.date!),
                    onChanged: (value) {
                      provider.updateDate(value);
                    },
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 30.w),
                      child: Icon(
                        Icons.event,
                        size: 40.sp,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      DateFormat(sharedPrefs.dateFormat).format(
                          DateFormat('dd/MM/yyyy').parse(provider.model.date!)),
                      style: GoogleFonts.aBeeZee(
                        fontSize: 21.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // Sử dụng currentTime từ provider
                  final currentTime = Time(
                    hour: provider.currentTime.hour,
                    minute: provider.currentTime.minute,
                  );

                  Navigator.of(context).push(
                    showPicker(
                        cancelText:
                            getTranslated(context, 'Cancel') ?? 'Cancel',
                        okText: getTranslated(context, 'Ok') ?? 'Ok',
                        unselectedColor: grey,
                        dialogInsetPadding: EdgeInsets.symmetric(
                            horizontal: 50.w, vertical: 30.0.h),
                        elevation: 12,
                        context: context,
                        value: currentTime,
                        is24HrFormat: true,
                        onChange: (value) {
                          provider.updateTime(value);
                        }),
                  );
                },
                child: Text(
                  provider.getFormattedTime(context),
                  style: GoogleFonts.aBeeZee(
                    fontSize: 21.5.sp,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
