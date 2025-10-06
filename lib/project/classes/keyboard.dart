import 'package:flutter/material.dart';
 import '../utils/responsive_extensions.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../localization/methods.dart';
import 'constants.dart';

class CustomKeyboard extends StatelessWidget {
  CustomKeyboard(
      {required this.panelController,
      this.mainFocus,
      this.nextFocus,
      required this.onTextInput,
      required this.onBackspace,
      required this.page});
  final PanelController panelController;
  final FocusNode? mainFocus;
  final FocusNode? nextFocus;
  final VoidCallback onBackspace;
  final ValueSetter<String> onTextInput;
  final Widget page;
  List<TextKey> generatedKeys() {
    List<TextKey> keys = [];
    for (String i in [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      ''
    ]) {
      keys.add(
        TextKey(
          text: i,
          onTextInput: onTextInput,
          onBackspace: onBackspace,
        ),
      );
    }
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
      child: Padding(
          padding: EdgeInsets.only(bottom: 25.h),
          child: Column(children: [
            SizedBox(
              // height: 52.h,
              child: Padding(
                padding: EdgeInsets.only(left: 5.w, right: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        panelController.close();
                        FocusScope.of(context).requestFocus(nextFocus);
                      },
                      child: SizedBox(
                        height: 35.h,
                        width: 60.w,
                        child: Icon(Icons.keyboard_arrow_down,
                            size: 25.sp, color: Colors.blueGrey),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        panelController.close();
                        mainFocus!.unfocus();
                      },
                      child: Text(
                        getTranslated(context, 'Done')!,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Wrap(
              children: generatedKeys(),
            ),
          ])),
    );
  }
}

class TextKey extends StatelessWidget {
  const TextKey({
    required this.text,
    this.onBackspace,
    this.onTextInput,
  });
  final VoidCallback? onBackspace;
  final String text;
  final ValueSetter<String>? onTextInput;

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: white,
      width: MediaQuery.of(context).size.width / 3,
      height: 55.h,
      child: Material(
        color: white,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            text.isEmpty
                ? onBackspace?.call()
                : onTextInput?.call(text);
          },
          child: Center(
              child: text.isEmpty
                  ? Icon(
                      Icons.backspace_outlined,
                      color: red,
                    )
                  : Text(
                      text,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    )),
        ),
      ),
    );
  }
}
