import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_animated_switcher.dart';
import 'package:flutter_test_future/components/empty_data_hint.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';

import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/file_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:webdav_client/webdav_client.dart';
import 'package:flutter_test_future/utils/log.dart';

class BackUpFileListPage extends StatefulWidget {
  const BackUpFileListPage({Key? key}) : super(key: key);

  @override
  State<BackUpFileListPage> createState() => _BackUpFileListPageState();
}

class _BackUpFileListPageState extends State<BackUpFileListPage> {
  List<File> files = [];
  bool _loadOk = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _initData() async {
    Log.info("获取备份文件中");
    String backupDir = await WebDavUtil.getRemoteDirPath();
    if (backupDir.isEmpty) {
      Log.info("远程备份路径为空");
      _loadOk = true;
      if (mounted) setState(() {});
      return;
    }

    String autoDir = await WebDavUtil.getRemoteAutoDirPath(backupDir);
    files.addAll(await WebDavUtil.client.readDir(backupDir));
    files.addAll(await WebDavUtil.client.readDir(autoDir));

    // 去除目录
    files.removeWhere(
        (element) => element.isDir ?? element.path?.endsWith("/") ?? false);

    Log.info("获取完毕，共${files.length}个文件");
    files.sort((a, b) => b.mTime.toString().compareTo(a.mTime.toString()));
    _loadOk = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("备份 (${files.length})"),
        ),
        body: FadeAnimatedSwitcher(
          loadOk: _loadOk,
          destWidget: _buildFileList(),
          specifiedLoadingWidget:
              const Center(child: CircularProgressIndicator()),
        ));
  }

  _buildFileList() {
    if (files.isEmpty) return emptyDataHint(msg: "没有备份。");
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: files.length,
        itemBuilder: (context, index) {
          return _buildFileItem(context, index);
        },
      ),
    );
  }

  _buildFileItem(BuildContext context, int index) {
    Log.info("index=$index");
    String fileName = "";
    File file = files[index];
    // 获取文件名
    if (file.path != null) {
      fileName = file.path!.split("/").last;
    }
    // 去除秒后面的.000
    String createdTime = file.mTime.toString().split(".")[0];

    // KB
    // ignore: non_constant_identifier_names
    String KBSize = FileUtil.getReadableFileSize(file.size ?? 0);
    String backupWay = file.path!.contains("automatic") ? "自动备份" : "手动备份";

    return ListTile(
      title: Text("${index + 1}. $fileName"),
      subtitle: Text("$createdTime $KBSize $backupWay"),
      trailing: IconButton(
          onPressed: () => _showDeleteDialog(context, file, index),
          icon: const Icon(Icons.delete_outline)),
      onTap: () => _showRestoreDialog(context, file),
    );
  }

  Future<dynamic> _showDeleteDialog(
      BuildContext context, File file, int index) {
    return showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("删除"),
            content: const Text("确定删除该备份吗？"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("取消")),
              TextButton(
                  onPressed: () {
                    if (file.path != null) {
                      BackupUtil.deleteRemoteFile(file.path!);
                    }
                    Navigator.of(dialogContext).pop();
                    // 从列表中删除
                    files.removeAt(index);
                    setState(() {});
                  },
                  child: const Text(
                    "删除",
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          );
        });
  }

  Future<dynamic> _showRestoreDialog(BuildContext context, File file) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("还原"),
          content: const Text("这会覆盖已有的数据，确定还原吗？"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("取消")),
            TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  ToastUtil.showLoading(
                    msg: "还原数据中",
                    task: () {
                      return BackupUtil.restoreFromWebDav(file);
                    },
                    onTaskComplete: (taskValue) {
                      taskValue as Result;
                      ToastUtil.showText(taskValue.msg);
                    },
                  );
                },
                child: const Text("确定")),
          ],
        );
      },
    );
  }
}
