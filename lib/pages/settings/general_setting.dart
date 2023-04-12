import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/models/page_switch_animation.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:get/get.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class GeneralSettingPage extends StatefulWidget {
  const GeneralSettingPage({Key? key}) : super(key: key);

  @override
  State<GeneralSettingPage> createState() => _GeneralSettingPageState();
}

class _GeneralSettingPageState extends State<GeneralSettingPage> {
  String beforeCurYearTimeExample = ""; // 今年之前的年份
  String curYearTimeExample = ""; // 今年
  String todayTimeExample = ""; // 今天

  bool showModifyChecklistDialog =
      SPUtil.getBool("showModifyChecklistDialog", defaultValue: true);

  @override
  void initState() {
    super.initState();

    DateTime now = DateTime.now();
    beforeCurYearTimeExample = DateTime(2000).toString();
    // 今年要和今天或昨天区分出来，但也不能改到去年了
    DateTime tmpDT = now.add(const Duration(days: -2)); // 前天
    if (tmpDT.year != now.year) {
      // 如果前天在去年，则改为明天
      tmpDT = now.add(const Duration(days: 1));
    }
    curYearTimeExample = tmpDT.toString();
    todayTimeExample = now.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("常规设置"),
      ),
      body: ListView(
        children: [
          ListTile(
              title: Text("偏好",
                  style: TextStyle(color: Theme.of(context).primaryColor))),
          ListTile(
            title: const Text("选择页面切换动画"),
            onTap: () {
              ThemeController themeController = Get.find();
              showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      children: PageSwitchAnimation.values
                          .map((e) => ListTile(
                                title: Text(e.title),
                                trailing: e ==
                                        themeController
                                            .pageSwitchAnimation.value
                                    ? const Icon(Icons.check)
                                    : null,
                                onTap: () {
                                  themeController.pageSwitchAnimation.value = e;
                                  SpProfile.savePageSwitchAnimationId(e.id);
                                  Navigator.pop(context);
                                },
                              ))
                          .toList(),
                    );
                  });
            },
          ),
          ListTile(
            title: const Text("重置完成最后一集时提示移动清单的对话框"),
            onTap: () {
              SPUtil.remove("autoMoveToFinishedTag"); // 总是
              SPUtil.remove("showModifyChecklistDialog"); // 不再提示
              SPUtil.remove("selectedFinishedTag"); // 存放已完成动漫的清单
              ToastUtil.showText("重置成功");
            },
          ),
          const Divider(),
          ListTile(
              title: Text("时间显示",
                  style: TextStyle(color: Theme.of(context).primaryColor))),
          SwitchListTile(
            title: const Text("精确到时分"),
            subtitle: Text(
                TimeUtil.getHumanReadableDateTimeStr(beforeCurYearTimeExample)),
            value: TimeUtil.showPreciseTime,
            onChanged: (bool value) {
              TimeUtil.turnShowPreciseTime();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text("显示昨天/今天"),
            subtitle:
                Text(TimeUtil.getHumanReadableDateTimeStr(todayTimeExample)),
            value: TimeUtil.showYesterdayAndToday,
            onChanged: (bool value) {
              TimeUtil.turnShowYesterdayAndToday();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text("今年时间隐藏年份"),
            subtitle:
                Text(TimeUtil.getHumanReadableDateTimeStr(curYearTimeExample)),
            value: TimeUtil.showCurYear,
            onChanged: (bool value) {
              TimeUtil.turnShowCurYear();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
