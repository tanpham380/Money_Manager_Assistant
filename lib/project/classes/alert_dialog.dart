import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
 import 'package:money_assistant/project/classes/constants.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

import '../localization/methods.dart';

Future<void> iosDialog(BuildContext context, String content, String action,
        Function onAction) =>
    showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Padding(
              padding: EdgeInsets.only(
                bottom: scale(8),
              ),
              child: Text(
                getTranslated(context, 'Please Confirm') ?? 'Please Confirm',
                style: TextStyle(fontSize: scale(21)),
              ),
            ),
            content: Text(getTranslated(context, content) ?? content,
                style: TextStyle(fontSize: scale(15.5))),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: scale(6), horizontal: scale(3)),
                  child: Text(getTranslated(context, 'Cancel') ?? 'Cancel',
                      style: TextStyle(
                          fontSize: scale(19.5), fontWeight: FontWeight.w600)),
                ),
                isDefaultAction: false,
                isDestructiveAction: false,
              ),
              CupertinoDialogAction(
                onPressed: () {
                  onAction();
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: scale(6), horizontal: scale(3)),
                  child: Text(getTranslated(context, action) ?? action,
                      style: TextStyle(
                          fontSize: scale(19.5), fontWeight: FontWeight.w600)),
                ),
                isDefaultAction: true,
                isDestructiveAction: true,
              )
            ],
          );
        });

Future<void> androidDialog(BuildContext context, String content, String action,
        Function onAction) =>
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: blue1,
            title: Text(getTranslated(context, 'Please Confirm')!),
            content: Text(getTranslated(context, content) ?? content),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(getTranslated(context, 'Cancel') ?? 'Cancel')),
              TextButton(
                  onPressed: () {
                    onAction();
                    Navigator.pop(context);
                  },
                  child: Text(getTranslated(context, action) ?? action))
            ],
          );
        });
