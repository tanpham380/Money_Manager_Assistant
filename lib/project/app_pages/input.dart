import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_pickers/helpers/show_date_picker.dart';
import '../utils/responsive_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/Provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:icofont_flutter/icofont_flutter.dart';
import '../classes/app_bar.dart';
import '../classes/category_item.dart';
import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../classes/saveOrSaveAndDeleteButtons.dart';
import '../localization/methods.dart';
import '../provider/form_provider.dart';
import '../provider/transaction_provider.dart';
import '../utils/date_format_utils.dart';
import 'expense_category.dart';
import 'income_category.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import '../utils/amount_formatter.dart';
import 'dart:async';

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
              body: Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  return TabBarView(
                    children: [
                      AddEditInput(
                        type: 'Expense',
                        formKey: _formKey2,
                        transactionProvider: transactionProvider,
                      ),
                      AddEditInput(
                        type: 'Income',
                        formKey: _formKey1,
                        transactionProvider: transactionProvider,
                      )
                    ],
                  );
                },
              ))),
    );
  }
}

// PanelForKeyboard đã bị XÓA - Sử dụng native keyboard thay thế

class AddEditInput extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final InputModel? inputModel;
  final String? type;
  final IconData? categoryIcon;
  final TransactionProvider transactionProvider;
  const AddEditInput({
    required this.formKey,
    this.inputModel,
    this.type,
    this.categoryIcon,
    required this.transactionProvider,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ĐÃ ĐƠN GIẢN HÓA - Sử dụng ChangeNotifierProvider trực tiếp
    return ChangeNotifierProvider(
      create: (context) => FormProvider(
        input: inputModel,
        type: type,
        categoryIcon: categoryIcon,
        transactionProvider: transactionProvider,
      ),
      child: Consumer<FormProvider>(
        builder: (context, provider, child) {
          return GestureDetector(
            onTap: () {
              // Ẩn keyboard khi tap ra ngoài
              FocusScope.of(context).unfocus();
            },
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              children: [
                // CARD DUY NHẤT - Merge tất cả các trường vào một Card
                // Smart Suggestions
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0.h),
                  child: Consumer<FormProvider>(
                    builder: (context, provider, child) {
                      // Hiển thị gợi ý cho cả Expense và Income
                      if (provider.model.type != 'Expense' &&
                          provider.model.type != 'Income') {
                        return const SizedBox.shrink();
                      }

                      if (provider.model.type == 'Expense') {
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
                              avatar: const Icon(Icons.restaurant_outlined,
                                  size: 18),
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
                                    getTranslated(context, 'Dinner') ??
                                        'Dinner';
                                p.updateCategory(
                                    categoryItem(MdiIcons.food, 'Food'));
                              },
                            ),
                            ActionChip(
                              avatar:
                                  const Icon(Icons.coffee_outlined, size: 18),
                              label: Text(
                                getTranslated(context, 'Coffee') ?? 'Coffee',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text =
                                    getTranslated(context, 'Coffee') ??
                                        'Coffee';
                                p.updateCategory(
                                    categoryItem(Icons.coffee, 'Coffee'));
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.wifi_outlined, size: 18),
                              label: Text(
                                getTranslated(context, 'Internet') ??
                                    'Internet',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text =
                                    getTranslated(context, 'Internet') ??
                                        'Internet';
                                p.updateCategory(categoryItem(
                                    IcoFontIcons.globe, 'Internet'));
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
                                p.descriptionController.text = getTranslated(
                                        context, 'Daily Necessities') ??
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
                              avatar:
                                  const Icon(Icons.movie_outlined, size: 18),
                              label: Text(
                                getTranslated(context, 'Movies') ?? 'Movies',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text =
                                    getTranslated(context, 'Movies') ??
                                        'Movies';
                                p.updateCategory(
                                    categoryItem(Icons.movie_filter, 'Movies'));
                              },
                            ),
                          ],
                        );
                      } else {
                        // Income suggestions
                        return Wrap(
                          spacing: 8.0.w,
                          runSpacing: 4.0.h,
                          children: [
                            ActionChip(
                              avatar: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 18),
                              label: Text(
                                getTranslated(context, 'Salary') ?? 'Salary',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text =
                                    getTranslated(context, 'Monthly Salary') ??
                                        'Monthly Salary';
                                p.updateCategory(categoryItem(
                                    MdiIcons.accountCash, 'Salary'));
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.business_center_outlined,
                                  size: 18),
                              label: Text(
                                getTranslated(context, 'Bonus') ?? 'Bonus',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text =
                                    getTranslated(context, 'Year-end Bonus') ??
                                        'Year-end Bonus';
                                p.updateCategory(categoryItem(
                                    IcoFontIcons.moneyBag, 'Bonus'));
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.trending_up_outlined,
                                  size: 18),
                              label: Text(
                                getTranslated(context, 'InvestmentIncome') ??
                                    'Investment Income',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text =
                                    getTranslated(context, 'Stock Dividend') ??
                                        'Stock Dividend';
                                p.updateCategory(categoryItem(
                                    Icons.business_center_rounded,
                                    'InvestmentIncome'));
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.work_outline, size: 18),
                              label: Text(
                                getTranslated(context, 'Side job') ??
                                    'Side job',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text = getTranslated(
                                        context, 'Freelance Project') ??
                                    'Freelance Project';
                                p.updateCategory(categoryItem(
                                    IcoFontIcons.searchJob, 'Side job'));
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.card_giftcard_outlined,
                                  size: 18),
                              label: Text(
                                getTranslated(context, 'GiftsIncome') ??
                                    'Gifts',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text =
                                    getTranslated(context, 'Birthday Gift') ??
                                        'Birthday Gift';
                                p.updateCategory(categoryItem(
                                    IcoFontIcons.gift, 'GiftsIncome'));
                              },
                            ),
                            ActionChip(
                              avatar:
                                  const Icon(Icons.receipt_outlined, size: 18),
                              label: Text(
                                getTranslated(context, 'Tax Refund') ??
                                    'Tax Refund',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              onPressed: () {
                                final p = context.read<FormProvider>();
                                p.descriptionController.text =
                                    getTranslated(context, 'Tax Refund') ??
                                        'Tax Refund';
                                p.updateCategory(categoryItem(
                                    IcoFontIcons.money, 'Tax Refund'));
                              },
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),

                Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0.r),
                  ),
                  child: Column(
                    children: [
                      // Amount Field
                      const AmountCard(),
                      Divider(height: 1, indent: 16.w, endIndent: 16.w),
                      // Category Field
                      const CategoryCard(),
                      Divider(height: 1, indent: 16.w, endIndent: 16.w),
                      // Description Field
                      const DescriptionCard(),
                      Divider(height: 1, indent: 16.w, endIndent: 16.w),
                      // Date & Time Field
                      const DateCard(),
                    ],
                  ),
                ),

                // Save/Delete Buttons
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 70.h),
                  child: inputModel != null
                      ? SaveAndDeleteButton(
                          onSave: () =>
                              provider.saveInput(context, isNewInput: false),
                          onDelete: () => _showDeleteDialog(context, provider),
                          isLoading: provider.isLoading, // Truyền trạng thái loading vào
                        )
                      : SaveButton(
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

class AmountCard extends StatefulWidget {
  const AmountCard({Key? key}) : super(key: key);

  @override
  State<AmountCard> createState() => _AmountCardState();
}

class _AmountCardState extends State<AmountCard> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onAmountChanged(String value, TextEditingController controller) {
    // Cancel previous debounce timer
    _debounce?.cancel();

    // Don't format if empty or currently typing
    if (value.isEmpty) return;

    // Debounce formatting để improve UX (wait 50ms after user stops typing)
    _debounce = Timer(const Duration(milliseconds: 50), () {
      // Remove existing commas for parsing
      final numericValue = value.replaceAll(',', '');
      if (numericValue.isEmpty) return;

      try {
        final number = double.parse(numericValue);
        final formatted = AmountFormatter.format(number);

        // Only update if different to avoid cursor jump
        if (formatted != value) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      } catch (e) {
        // Ignore invalid input
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FormProvider>(
      builder: (context, provider, child) {
        final colorMain = provider.model.type == 'Income'
            ? Theme.of(context)
                .colorScheme
                .secondary // Use secondary for Income (green)
            : Theme.of(context)
                .colorScheme
                .error; // Use error for Expense (red)
        final amountController = provider.amountController;

        return Semantics(
          label: getTranslated(context, 'Amount input section'),
          child: Padding(
            padding: EdgeInsets.only(
                top: 5.h, bottom: 15.h, right: 20.w, left: 20.w),
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
                  // SỬ DỤNG BÀN PHÍM NATIVE
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  showCursor: true,
                  maxLines: 1,
                  autofocus: false,
                  onChanged: (value) =>
                      _onAmountChanged(value, amountController),
                  onFieldSubmitted: (_) {
                    // Format immediately before saving
                    _debounce?.cancel();
                    _onAmountChanged(amountController.text, amountController);

                    // Thực hiện lưu trực tiếp khi nhấn Done trên bàn phím
                    Future.delayed(const Duration(milliseconds: 350), () {
                      final isNew =
                          context.read<FormProvider>().model.id == null;
                      context
                          .read<FormProvider>()
                          .saveInput(context, isNewInput: isNew);
                    });
                  },
                  // Chỉ cho phép nhập số
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  cursorColor: colorMain,
                  style: GoogleFonts.aBeeZee(
                      color: colorMain,
                      fontSize: 35.sp,
                      fontWeight: FontWeight.bold),
                  focusNode: provider.amountFocusNode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.aBeeZee(
                        color: colorMain.withValues(alpha: 0.5),
                        fontSize: 35.sp,
                        fontWeight: FontWeight.bold),
                    icon: Padding(
                      padding: EdgeInsets.only(right: 5.w),
                      child: Icon(
                        Icons.monetization_on,
                        size: 30.sp,
                        color: colorMain,
                        semanticLabel: getTranslated(context, 'Amount icon'),
                      ),
                    ),
                    suffixIcon: amountController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 24.sp,
                              semanticLabel:
                                  getTranslated(context, 'Clear amount'),
                            ),
                            onPressed: amountController.clear)
                        : const SizedBox(),
                    semanticCounterText:
                        getTranslated(context, 'Amount input field'),
                  ),
                ),
              ],
            ),
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

        return Semantics(
          label: getTranslated(context, 'Category selection section'),
          child: GestureDetector(
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
                    ? Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.05) // Use error color
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isDefaultCategory
                        ? Theme.of(context).colorScheme.error
                        : Colors.transparent, // Use error color
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
                            color: isDefaultCategory
                                ? Colors.grey
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface, // Use onSurface
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_outlined,
                      size: 20.sp,
                      color: isDefaultCategory
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey, // Use error color
                      semanticLabel: getTranslated(context, 'Select category'),
                    ),
                  ],
                ),
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
        final colorMain = provider.model.type == 'Income'
            ? Theme.of(context)
                .colorScheme
                .secondary // Use secondary for Income (green)
            : Theme.of(context)
                .colorScheme
                .error; // Use error for Expense (red)

        return Semantics(
          label: getTranslated(context, 'Description input section'),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.5.h),
            child: TextFormField(
              controller: descriptionController,
              maxLines: 5, // Constrain to 5 lines to prevent UI overflow
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
                            semanticLabel:
                                getTranslated(context, 'Clear description'),
                          ),
                          onPressed: descriptionController.clear)
                      : const SizedBox(),
                  icon: Padding(
                    padding: EdgeInsets.only(right: 15.w),
                    child: Icon(
                      Icons.description_outlined,
                      size: 40.sp,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7), // Use onSurface with alpha
                      semanticLabel: getTranslated(context, 'Description icon'),
                    ),
                  ),
                  semanticCounterText:
                      getTranslated(context, 'Description input field')),
            ),
          ),
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
        return Semantics(
          label: getTranslated(context, 'Date and time selection section'),
          child: Padding(
            padding: EdgeInsets.only(
                left: 20.w, right: 20.w, top: 17.5.h, bottom: 19.h),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showMaterialDatePicker(
                      headerColor: Theme.of(context)
                          .colorScheme
                          .primary, // Use primary color
                      headerTextColor: Theme.of(context)
                          .colorScheme
                          .onSurface, // Use onSurface
                      backgroundColor:
                          Theme.of(context).colorScheme.surface, // Use surface
                      buttonTextColor:
                          Theme.of(context).colorScheme.primary, // Use primary
                      cancelText: getTranslated(context, 'CANCEL'),
                      confirmText: getTranslated(context, 'OK') ?? 'OK',
                      maxLongSide: 450.w,
                      maxShortSide: 300.w,
                      title: getTranslated(context, 'Select a date'),
                      context: context,
                      firstDate: DateTime(1990, 1, 1),
                      lastDate: DateTime(2100, 12, 31),
                      selectedDate: DateFormatUtils.parseInternalDate(
                          provider.model.date!),
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
                          color: Theme.of(context)
                              .colorScheme
                              .primary, // Use primary color
                          semanticLabel:
                              getTranslated(context, 'Date picker icon'),
                        ),
                      ),
                      Text(
                        DateFormatUtils.formatUserDate(
                            DateFormatUtils.parseInternalDate(
                                provider.model.date!)),
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
                          unselectedColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(
                                  alpha: 0.5), // Use onSurface with alpha
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
          ),
        );
      },
    );
  }
}
