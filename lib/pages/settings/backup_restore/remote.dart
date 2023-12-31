import 'dart:async';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/controllers/backup_service.dart';
import 'package:flutter_test_future/pages/anime_collection/checklist_controller.dart';

import 'package:flutter_test_future/pages/settings/backup_file_list.dart';
import 'package:flutter_test_future/pages/settings/backup_restore/login_form.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/widgets/setting_title.dart';

class RemoteBackupPage extends StatefulWidget {
  const RemoteBackupPage({
    Key? key,
    this.fromHome = false,
  }) : super(key: key);
  final bool fromHome;

  @override
  State<RemoteBackupPage> createState() => _RemoteBackupPageState();
}

class _RemoteBackupPageState extends State<RemoteBackupPage> {
  int autoBackupWebDavNumber =
      SPUtil.getInt("autoBackupWebDavNumber", defaultValue: 20);
  bool canManualBackup = true;

  BackupService get backupService => BackupService.to;

  @override
  void initState() {
    super.initState();
    // SPUtil.clear();
    // 获取最新情况，更新SP中的online
    WebDavUtil.pingWebDav().then((pingOk) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingTitle(title: 'WebDav备份'),
        ListTile(
          title: const Text("查看教程"),
          trailing: const Icon(EvaIcons.externalLink),
          onTap: () {
            LaunchUrlUtil.launch(
                context: context,
                uriStr: "https://help.jianguoyun.com/?p=2064");
          },
        ),
        ListTile(
          title: const Text("账号配置"),
          trailing: Icon(
            Icons.circle,
            size: 12,
            color: SPUtil.getBool("online")
                ? AppTheme.connectableColor
                : Colors.grey,
          ),
          onTap: () {
            _loginWebDav();
          },
        ),
        ListTile(
          title: const Text("立即备份"),
          subtitle: const Text("单击进行备份，备份目录为 /animetrace"),
          onTap: () async {
            if (!SPUtil.getBool("login")) {
              ToastUtil.showText("请先配置账号，再进行备份！");
              return;
            }

            if (!canManualBackup) {
              ToastUtil.showText("备份间隔为10s");
              return;
            }

            canManualBackup = false;
            Future.delayed(const Duration(seconds: 10))
                .then((value) => canManualBackup = true);

            ToastUtil.showText("正在备份");
            String remoteBackupDirPath = await WebDavUtil.getRemoteDirPath();
            if (remoteBackupDirPath.isNotEmpty) {
              BackupUtil.backup(remoteBackupDirPath: remoteBackupDirPath);
            }
          },
        ),
        if (!widget.fromHome)
          ListTile(
            title: const Text("自动备份"),
            subtitle: Text(backupService.curRemoteBackupMode.title),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text("自动备份"),
                  children: [
                    for (int i = 0; i < BackupMode.values.length; ++i)
                      RadioListTile(
                          title: Text(BackupMode.values[i].title),
                          value: BackupMode.values[i].name,
                          groupValue: backupService.curRemoteBackupModeName,
                          onChanged: (String? value) {
                            if (value == null) return;

                            backupService.setBackupMode(value);
                            // 关闭对话框
                            Navigator.pop(context);
                            // 重绘页面
                            setState(() {});
                          }),
                  ],
                ),
              );
            },
          ),
        // _buildOldAutoBackupSwitchTile(),
        if (!widget.fromHome)
          ListTile(
            title: const Text("自动备份数量"),
            subtitle: Text("$autoBackupWebDavNumber"),
            onTap: () async {
              int? number = await dialogSelectUint(context, "自动备份数量",
                  initialValue: autoBackupWebDavNumber,
                  minValue: 10,
                  maxValue: 20);
              if (number != null) {
                autoBackupWebDavNumber = number;
                SPUtil.setInt("autoBackupWebDavNumber", number);
                setState(() {});
              }
            },
          ),
        if (!widget.fromHome)
          SwitchListTile(
            title: const Text("自动还原"),
            subtitle: const Text("进入应用前还原最新备份文件\n若选择打开应用后自动备份，则该功能不会生效"),
            value: backupService.enableAutoRestoreFromRemote,
            onChanged: (value) {
              backupService.setAutoRestoreFromRemote(value);
              // 重绘页面
              setState(() {});
            },
          ),
        if (!widget.fromHome)
          SwitchListTile(
            title: const Text("下拉还原"),
            subtitle: const Text("动漫收藏页下拉时，会尝试还原最新备份文件"),
            value: SPUtil.getBool(pullDownRestoreLatestBackupInChecklistPage),
            onChanged: (value) {
              SPUtil.setBool(pullDownRestoreLatestBackupInChecklistPage, value);
              // 重绘页面
              setState(() {});
              // 重绘收藏页，以便于允许或取消下拉刷新
              ChecklistController.to.update();
            },
          ),
        ListTile(
          title: const Text("手动还原"),
          subtitle: const Text("点击查看所有备份文件"),
          onTap: () async {
            if (SPUtil.getBool("online")) {
              showModalBottomSheet(
                // 主页打开底部面板再次打开底部面板时，不再指定barrierColor颜色，避免不透明度加深
                barrierColor: widget.fromHome ? Colors.transparent : null,
                context: context,
                builder: (context) => const BackUpFileListPage(),
              ).then((value) {
                setState(() {});
              });
            } else {
              ToastUtil.showText("配置账号后才可以进行还原");
            }
          },
        ),
      ],
    );
  }

  void _loginWebDav() async {
    await showDialog(
      context: context,
      builder: (context) => const WebDavLoginForm(),
    );
    setState(() {});
  }
}