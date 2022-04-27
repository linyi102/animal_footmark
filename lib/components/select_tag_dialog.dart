import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';

dialogSelectTag(setState, context, Anime anime) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      List<Widget> radioList = [];
      for (int i = 0; i < tags.length; ++i) {
        radioList.add(
          ListTile(
            title: Text(tags[i]),
            leading: tags[i] == anime.tagName
                ? const Icon(
                    Icons.radio_button_on_outlined,
                    color: Colors.blue,
                  )
                : const Icon(
                    Icons.radio_button_off_outlined,
                  ),
            onTap: () {
              // 不能只传入tagName，需要把对象的引用传进来，然后修改就会生效
              // 如果起初没有收藏，则说明是新增，否则修改
              if (!anime.isCollected()) {
                anime.tagName = tags[i];
                SqliteUtil.insertAnime(anime).then((lastInsertId) {
                  showToast("收藏成功！");
                  // 修改id
                  anime.animeId = lastInsertId;
                });
              } else {
                SqliteUtil.updateTagByAnimeId(anime.animeId, tags[i]);
                anime.tagName = tags[i];
                showToast("修改成功！");
              }
              setState(() {});
              Navigator.pop(context);
            },
          ),
        );
      }
      return AlertDialog(
        title: const Text('选择标签'),
        content: AspectRatio(
          aspectRatio: 0.9 / 1,
          child: ListView(
            children: radioList,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text("取消收藏"),
            onPressed: () {
              if (anime.isCollected()) {
                SqliteUtil.deleteAnimeByAnimeId(anime.animeId);
                anime.animeId = 0;
              }
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("取消"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
