import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_dialog.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

dialogSelectChecklist(
  setState,
  context,
  Anime anime, {
  bool onlyShowChecklist = false, // 只显示清单列表
  bool enableClimbDetailInfo = true, // 开启爬取详细信息
  void Function(Anime newAnime)? callback,
}) {
  List<Widget> items = [];
  if (!anime.isCollected() && !onlyShowChecklist) {
    items.add(ListTile(title: Text(anime.animeName)));
  }
  for (int i = 0; i < tags.length; ++i) {
    items.add(
      ListTile(
        title: Text(tags[i]),
        leading: tags[i] == anime.tagName
            ? Icon(Icons.radio_button_on_outlined,
                color: Theme.of(context).primaryColor)
            : const Icon(Icons.radio_button_off_outlined),
        onTap: () async {
          // 不能只传入tagName，需要把对象的引用传进来，然后修改就会生效
          // 如果起初没有收藏，则说明是新增，否则修改
          if (!anime.isCollected()) {
            anime.tagName = tags[i];

            // 不管怕不爬取详细页，都先关闭选择清单框
            Navigator.pop(context);

            // 爬取详细页
            if (enableClimbDetailInfo) {
              ToastUtil.showLoading(
                msg: "获取详细信息中",
                task: () async {
                  // 爬取详细页
                  anime = await ClimbAnimeUtil.climbAnimeInfoByUrl(anime,
                      showMessage: false);
                },
                onTaskComplete: (taskValue) async {
                  // 插入数据库
                  anime.animeId = await SqliteUtil.insertAnime(anime);
                  // 更新父级页面
                  setState(() {});
                  Log.info("收藏成功！");
                  if (callback != null) callback(anime);
                },
              );
            }
          } else {
            SqliteUtil.updateTagByAnimeId(anime.animeId, tags[i]);
            anime.tagName = tags[i];
            Log.info("修改成功！");
            setState(() {});

            // 关闭选择清单框
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: const Text("选择清单"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: items,
      ),
    ),
  );
}
