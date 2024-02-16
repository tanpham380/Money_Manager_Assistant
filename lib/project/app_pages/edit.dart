import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../classes/app_bar.dart';
import '../classes/constants.dart';
import '../classes/input_model.dart';
import '../localization/methods.dart';
import 'input.dart';

class Edit extends StatelessWidget {
  static final _formKey3 = GlobalKey<FormState>(debugLabel: '_formKey3');
  final InputModel? inputModel;
  final IconData categoryIcon;
  const Edit({
    this.inputModel,
    required this.categoryIcon,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: BasicAppBar(getTranslated(context, 'Edit')!),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: PanelForKeyboard(AddEditInput(
          formKey: _formKey3,
          inputModel: this.inputModel,
          categoryIcon: this.categoryIcon,
        ),)
      ),
    );
  }
}
