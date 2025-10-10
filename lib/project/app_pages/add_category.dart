import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../classes/app_bar.dart';
import '../classes/category_item.dart';
import '../classes/constants.dart';
import '../classes/saveOrSaveAndDeleteButtons.dart';
import '../database_management/shared_preferences_services.dart';
import '../localization/methods.dart';
import '../provider.dart';
import '../services/alert_service.dart';
import '../utils/responsive_extensions.dart';
import 'parent_category.dart';
import 'select_icon.dart';

// REFACTORED: Chuyển AddCategory thành StatefulWidget để quản lý Controllers và FormKey
class AddCategory extends StatefulWidget {
  final BuildContext? contextEx, contextExEdit, contextInEdit, contextIn;
  final String type, appBarTitle;
  final String? categoryName, description;
  final IconData? categoryIcon;
  final CategoryItem? parentItem;

  AddCategory({
    super.key,
    this.contextExEdit,
    this.contextEx,
    this.contextInEdit,
    this.contextIn,
    required this.type,
    required this.appBarTitle,
    this.categoryName,
    this.categoryIcon,
    this.parentItem,
    this.description,
  });

  @override
  State<AddCategory> createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _categoryNameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // FIX: Khởi tạo controller trong initState, không dùng static
    _categoryNameController = TextEditingController(text: widget.categoryName ?? '');
    _descriptionController = TextEditingController(text: widget.description ?? '');
  }

  @override
  void dispose() {
    // FIX: Huỷ controller trong dispose để tránh memory leak
    _categoryNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _unFocusNode(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }

  // REFACTORED: Toàn bộ logic lưu được đưa vào đây
  void _saveCategory(BuildContext providerContext) {
    _unFocusNode(context);

    if (!_formKey.currentState!.validate()) {
      AlertService.show(
        context,
        type: NotificationType.error,
        message: 'Please check the form fields and try again',
      );
      return;
    }

    try {
      final changeCategoryProvider = providerContext.read<ChangeCategory>();
      final String finalCategoryName = _categoryNameController.text.trim();
      final String finalDescription = _descriptionController.text.trim();
      final IconData finalCategoryIcon =
          changeCategoryProvider.selectedCategoryIcon ?? widget.categoryIcon ?? Icons.category_outlined;
      final CategoryItem? finalParent = changeCategoryProvider.parentItem;

      CategoryItem newCategoryItem = CategoryItem(
        finalCategoryIcon.codePoint,
        finalCategoryIcon.fontPackage,
        finalCategoryIcon.fontFamily,
        finalCategoryName,
        finalDescription,
      );

      if (widget.type == 'Income') {
        _saveIncomeCategory(newCategoryItem);
      } else {
        _saveExpenseCategory(newCategoryItem, finalParent);
      }

      AlertService.show(
        context,
        type: NotificationType.success,
        message: 'Category saved successfully',
      );

      // ADDED: Trả về true để màn hình trước có thể refresh
      Navigator.pop(context, true);

    } catch (e) {
      AlertService.show(
        context,
        type: NotificationType.error,
        message: 'Error saving category: $e',
      );
    }
  }

  void _saveIncomeCategory(CategoryItem newItem) {
    var incomeItemsList = sharedPrefs.getItems('income items');
    // Trường hợp sửa
    if (widget.categoryName != null) {
      incomeItemsList.removeWhere((item) => item.text == widget.categoryName);
    }
    incomeItemsList.add(newItem);
    sharedPrefs.saveItems('income items', incomeItemsList);

    // Refresh providers
    if (widget.contextInEdit != null) {
      Provider.of<ChangeIncomeItemEdit>(widget.contextInEdit!, listen: false).getIncomeItems();
    }
    if (widget.contextIn != null) {
      Provider.of<ChangeIncomeItem>(widget.contextIn!, listen: false).getIncomeItems();
    }
  }

  void _saveExpenseCategory(CategoryItem newItem, CategoryItem? finalParent) {
    // Trường hợp Thêm mới
    if (widget.categoryName == null) {
      if (finalParent == null || finalParent.text == getTranslated(context, 'Parent category')) {
        // Thêm một danh mục cha mới
        sharedPrefs.saveItems(newItem.text, [newItem]);
        var parentNames = sharedPrefs.parentExpenseItemNames;
        parentNames.add(newItem.text);
        sharedPrefs.parentExpenseItemNames = parentNames;
      } else {
        // Thêm một danh mục con vào danh mục cha đã có
        var items = sharedPrefs.getItems(finalParent.text);
        items.add(newItem);
        sharedPrefs.saveItems(finalParent.text, items);
      }
    }
    // Trường hợp Sửa
    else {
      // Sửa danh mục cha
      if (widget.parentItem == null) {
        var items = sharedPrefs.getItems(widget.categoryName!);
        items.removeAt(0);
        items.insert(0, newItem);
        sharedPrefs.saveItems(newItem.text, items);

        if (newItem.text != widget.categoryName) {
           var parentNames = sharedPrefs.parentExpenseItemNames;
           int index = parentNames.indexOf(widget.categoryName!);
           if (index != -1) {
             parentNames[index] = newItem.text;
             sharedPrefs.parentExpenseItemNames = parentNames;
           }
        }
      }
      // Sửa danh mục con
      else {
        // Xóa khỏi danh mục cha cũ
        var oldParentItems = sharedPrefs.getItems(widget.parentItem!.text);
        oldParentItems.removeWhere((item) => item.text == widget.categoryName);
        sharedPrefs.saveItems(widget.parentItem!.text, oldParentItems);

        // Thêm vào danh mục cha mới (có thể giống hoặc khác cha cũ)
        var newParentItems = sharedPrefs.getItems(finalParent!.text);
        newParentItems.add(newItem);
        sharedPrefs.saveItems(finalParent.text, newParentItems);
      }
    }

    // Refresh providers
    if (widget.contextExEdit != null) {
      Provider.of<ChangeExpenseItemEdit>(widget.contextExEdit!, listen: false).getAllExpenseItems();
    }
    if (widget.contextEx != null) {
      Provider.of<ChangeExpenseItem>(widget.contextEx!, listen: false).getAllExpenseItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _unFocusNode(context),
      child: Scaffold(
        backgroundColor: blue1,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: BasicAppBar(widget.appBarTitle),
        ),
        body: Form(
          key: _formKey,
          child: ChangeNotifierProvider<ChangeCategory>(
            create: (context) => ChangeCategory(),
            // SỬ DỤNG BUILDER ĐỂ LẤY CONTEXT MỚI
            child: Builder(
              builder: (providerContext) { // <-- providerContext này "nhìn thấy" provider
                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
                  children: [
                    CategoryName(
                      type: widget.type,
                      categoryName: widget.categoryName,
                      categoryIcon: widget.categoryIcon,
                      controller: _categoryNameController, // Truyền controller vào
                    ),
                    SizedBox(height: 20.h),
                    if (widget.type != 'Income' && !(widget.categoryName != null && widget.parentItem == null))
                      ParentCategoryCard(widget.parentItem),
                    SizedBox(height: 20.h),
                    Description(
                      description: widget.description,
                      controller: _descriptionController, // Truyền controller vào
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 90.h),
                      child: widget.categoryName == null
                          ? SaveButton(onSave: () => _saveCategory(providerContext)) // <-- Truyền context mới
                          : SaveAndDeleteButton(
                              onSave: () => _saveCategory(providerContext), // <-- Truyền context mới
                              // Đưa logic gọi hàm xóa vào đây
                              onDelete: () {
                                deleteCategoryFunction(
                                  context: context,
                                  categoryName: widget.categoryName!,
                                  parentExpenseItem: widget.parentItem?.text,
                                  contextEx: widget.contextEx,
                                  contextExEdit: widget.contextExEdit,
                                  contextIn: widget.contextIn,
                                  contextInEdit: widget.contextInEdit,
                                );
                              },
                              // Hiện tại chưa có state loading cho category, nên để false
                              isLoading: false,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryName extends StatelessWidget {
  final String type;
  final String? categoryName;
  final IconData? categoryIcon;
  final TextEditingController controller; // FIX: Nhận controller từ bên ngoài

  const CategoryName({
    super.key,
    required this.type,
    this.categoryName,
    this.categoryIcon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 7,
      child: Padding(
        padding: EdgeInsets.only(left: 10.w, top: 8.h, bottom: 8.h),
        child: TextFormField(
          controller: controller, // FIX: Sử dụng controller được truyền vào
          maxLines: 1,
          cursorColor: blue1,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          validator: (value) {
            final categoryNameInput = value?.trim();
            if (categoryNameInput == null || categoryNameInput.isEmpty) {
              return getTranslated(context, 'Please fill a category name');
            }

            bool isDuplicate = false;
            if (categoryNameInput != categoryName) {
              if (type == 'Income') {
                isDuplicate = sharedPrefs.getItems('income items').any((item) => item.text == categoryNameInput);
              } else {
                isDuplicate = sharedPrefs.getAllExpenseItemsLists().expand((list) => list).any((item) => item.text == categoryNameInput);
              }
            }
            if (isDuplicate) {
              return getTranslated(context, 'Category already exists');
            }
            return null;
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: getTranslated(context, 'Category name'),
            hintStyle: TextStyle(
              fontSize: 22.sp,
              color: grey,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.normal,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: controller.clear,
            ),
            icon: Consumer<ChangeCategory>( // Sử dụng Consumer thay vì Selector khi UI phức tạp
              builder: (context, provider, child) {
                return GestureDetector(
                  onTap: () async {
                    _unFocusNode(context);
                    IconData? selectedIcon = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SelectIcon(type)),
                    );
                    if (selectedIcon != null) {
                      provider.changeCategoryIcon(selectedIcon);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: const Color.fromRGBO(215, 223, 231, 1),
                        child: Icon(
                          provider.selectedCategoryIcon ?? categoryIcon ?? Icons.category_outlined,
                          size: 25.sp,
                          color: type == 'Income' ? green : red,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        getTranslated(context, 'select icon') ?? 'select icon',
                        style: TextStyle(fontSize: 11.sp, color: Colors.blueGrey),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _unFocusNode(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }
}

class ParentCategoryCard extends StatelessWidget {
  final CategoryItem? parentItem;
  const ParentCategoryCard(this.parentItem, {super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChangeCategory>(
      builder: (context, provider, child) {
        final selectedParentItem = provider.parentItem ?? parentItem ??
            categoryItem(
                Icons.category_outlined,
                getTranslated(context, 'Parent category') ??
                    'Parent category');
        
        // Cập nhật provider nếu chưa có
        WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.parentItem ??= selectedParentItem;
        });

        return GestureDetector(
          onTap: () async {
            FocusScope.of(context).unfocus();
            CategoryItem? newParentItem = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ParentCategoryList()),
            );
            if (newParentItem != null) {
              provider.changeParentItem(newParentItem);
            }
          },
          child: Card(
            elevation: 7,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: const Color.fromRGBO(215, 223, 231, 1),
                    child: Icon(iconData(selectedParentItem), size: 25.sp, color: red),
                  ),
                  SizedBox(width: 28.w),
                  Expanded(
                    child: Text(
                      getTranslated(context, selectedParentItem.text) ?? selectedParentItem.text,
                      style: selectedParentItem.text == (getTranslated(context, 'Parent category') ?? 'Parent category')
                          ? TextStyle(
                              fontSize: 22.sp,
                              color: grey,
                              fontStyle: FontStyle.italic,
                            )
                          : TextStyle(
                              fontSize: 22.sp,
                              color: red,
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 22.sp),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class Description extends StatelessWidget {
  final String? description;
  final TextEditingController controller; // FIX: Nhận controller từ bên ngoài

  const Description({
    super.key,
    this.description,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 7,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
        child: TextFormField(
          controller: controller, // FIX: Sử dụng controller được truyền vào
          maxLines: null,
          minLines: 1,
          cursorColor: blue1,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 22.sp),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: getTranslated(context, 'Description') ?? 'Description',
            hintStyle: GoogleFonts.cousine(
              fontSize: 21.5.sp,
              fontStyle: FontStyle.italic,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: controller.clear,
            ),
            icon: Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: Icon(
                Icons.description_outlined,
                size: 35.sp,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// SIMPLIFIED: Save và SaveAndDeleteButton đã có sẵn, chỉ cần gọi đúng hàm onSave
// Không cần tạo widget Save riêng nữa.
