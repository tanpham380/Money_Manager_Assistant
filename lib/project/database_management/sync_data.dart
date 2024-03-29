import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:money_assistant/project/localization/methods.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../classes/input_model.dart';
import 'sqflite_services.dart';

class ImportExportScreen extends StatefulWidget {
  @override
  _ImportExportScreenState createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  late TextEditingController _fileNameController;
    Directory? documentsDirectory ;
    String documentsPath = "";
    List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    _checkStoragePermission();
    _getDocumentDirecttory();
    _fileNameController = TextEditingController();

    
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }
Future <void> _getDocumentDirecttory () async {
  documentsDirectory = await getExternalStorageDirectory();
  documentsPath = documentsDirectory!.path;
  files = await documentsDirectory!.listSync();
      setState(() {
    });
}


 Future<void> _checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();

    } 
     status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

Future<void> _exportData(BuildContext context, String fileName) async {

  if (fileName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(getTranslated(context, 'Please enter a file name') ?? 'Please enter a file name')  ),
    );
    return;
  }
  try {
    // Check storage access permission
    // var status = await Permission.storage.status;
    // if (!status.isGranted) {
    //   await Permission.storage.request();
    //   status = await Permission.storage.status;
    //   if (!status.isGranted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
          
    //     SnackBar(content: Text(getTranslated(context, 'App needs storage access to export data') ?? 'App needs storage access to export data')  ),

    //     );
    //     return;
    //   }




    // }
    
    var dbQuery = await DB.query();

    String csv = dbQuery.map((row) => row.values.join(',')).join('\n');

    String exportFilePath = '$documentsPath/$fileName.csv';
    File csvFile = File(exportFilePath);
    await csvFile.writeAsString(csv);
      setState(() {
      files = documentsDirectory!.listSync();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text( getTranslated(context, 'Data exported successfully' ) ?? 'Data exported successfully')),
    );

  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text( getTranslated(context, 'Failed to export data' ) ?? 'Failed to export data')),
    );
  }
}
Future<void> _importData(BuildContext context, String filePath) async {
  try {
    // Kiểm tra quyền truy cập vào bộ nhớ
    // var status = await Permission.storage.status;
    // if (!status.isGranted) {
    //   await Permission.storage.request();
    //   status = await Permission.storage.status;
    //   if (!status.isGranted) {
    //   SnackBar(content: Text( getTranslated(context, 'App needs storage access to import data' ) ?? 'App needs storage access to import data'));

        
    //     return;
    //   }
    // }
    
    File file = File(filePath);
    String csvData = await file.readAsString();

    List<String> lines = csvData.split('\n');
    for (var line in lines) {
      List<String> values = line.split(','); // Giả sử các giá trị được phân tách bằng dấu phẩy
      // Tạo một đối tượng InputModel từ dòng dữ liệu
      print(values[1]);
      InputModel model = InputModel(
        id : int.parse(values[0]),
        type: values[1],
        amount: double.parse(values[2]),
        category: values[3],
        description: values[4],
        date: values[5],
        time: values[6],
      );
      // Chèn đối tượng vào cơ sở dữ liệu SQLite
      await DB.insert(model);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text( getTranslated(context, 'Data imported successfully' ) ?? 'Data imported successfully')),
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text( getTranslated(context, 'Failed to import data' ) ?? 'Failed to import data')),

    );
  }
}


void _deleteFile(BuildContext context, String filePath) async {
  try {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Confirm Delete") ?? "Confirm Delete"),
          content: Text(getTranslated(context, "Are you sure you want to delete this file?") ?? "Are you sure you want to delete this file?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Do not delete
              },
              child: Text(getTranslated(context, "Cancel") ?? "Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Delete
              },
              child: Text(getTranslated(context, "Delete") ?? "Delete"),
            ),
          ],
        );
      },
    );

    if (confirmDelete != null && confirmDelete) {
      File file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        setState(() {
          files = documentsDirectory!.listSync();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getTranslated(context, 'File deleted successfully') ?? 'File deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getTranslated(context, 'File does not exist') ?? 'File does not exist')),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(getTranslated(context, 'An error occurred') ?? 'An error occurred: ')),
    );
  }
}



@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(getTranslated(context, 'Import/Export Data') ?? 'Import/Export Data'),
    ),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _fileNameController,
            decoration: InputDecoration(labelText: getTranslated(context, 'File Name') ?? 'File Name'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _exportData(context, _fileNameController.text),
            child: Text(getTranslated(context, 'Export Data') ?? 'Export Data'),
          ),
          ElevatedButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null) {
                String? filePath = result.files.single.path;
                if (filePath != null) {
                  _importData(context, filePath);
                }
              }
            },
            child: Text(getTranslated(context, 'Pick File to Import Data') ?? 'Pick File to Import Data'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                FileSystemEntity file = files[index];
                return ListTile(
                  title: Text("$index-" + file.path.split('/').last),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Gọi hàm để xử lý việc xóa file
                      _deleteFile(context, file.path);
                    },
                  ),
                  onTap: () {
                    _importData(context, file.path);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}



}
