import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<String?> selectFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result != null) {
    PlatformFile file = result.files.first;
    debugPrint("选择的文件：${file.name}");
    return file.path;
  } else {
    // 未选择文件
    return null;
  }
}

Future<String?> selectDirectory() async {
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  if (selectedDirectory != null) {
    debugPrint("选择的目录：$selectedDirectory");
    return selectedDirectory;
  } else {
    // 未选择目录
    return null;
  }
}
