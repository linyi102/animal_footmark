import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import 'package:oktoast/oktoast.dart';

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
        title: const Text(
          "常规设置",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          // ListTile(
          //     title: Text("默认开关",
          //         style: TextStyle(color: ThemeUtil.getPrimaryColor()))),
          ListTile(
            title: const Text("重置完成最后一集时提示移动清单的对话框"),
            onTap: () {
              SPUtil.remove("autoMoveToFinishedTag"); // 总是
              SPUtil.remove("showModifyChecklistDialog"); // 不再提示
              SPUtil.remove("selectedFinishedTag"); // 存放已完成动漫的清单
              showToast("重置成功");
            },
          ),
          const Divider(),
          ListTile(
              title: Text("时间显示",
                  style: TextStyle(color: ThemeUtil.getPrimaryColor()))),
          ListTile(
            title: const Text("精确到时分"),
            subtitle: Text(TimeShowUtil.getHumanReadableDateTimeStr(
                beforeCurYearTimeExample)),
            trailing: _buildToggle(TimeShowUtil.showPreciseTime),
            onTap: () {
              TimeShowUtil.turnShowPreciseTime();
              setState(() {});
            },
          ),
          ListTile(
            title: const Text("显示昨天/今天"),
            subtitle: Text(
                TimeShowUtil.getHumanReadableDateTimeStr(todayTimeExample)),
            trailing: _buildToggle(TimeShowUtil.showYesterdayAndToday),
            onTap: () {
              TimeShowUtil.turnShowYesterdayAndToday();
              setState(() {});
            },
          ),
          ListTile(
            title: const Text("今年时间隐藏年份"),
            subtitle: Text(
                TimeShowUtil.getHumanReadableDateTimeStr(curYearTimeExample)),
            trailing: _buildToggle(!TimeShowUtil.showCurYear),
            onTap: () {
              TimeShowUtil.turnShowCurYear();
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  Icon _buildToggle(bool toggleOn) {
    return toggleOn
        ? Icon(Icons.toggle_on, color: ThemeUtil.getPrimaryIconColor())
        : const Icon(Icons.toggle_off);
  }
}