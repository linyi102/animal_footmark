import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../controllers/anime_display_controller.dart';

SliverGridDelegate getAnimeGridDelegate() {
  final AnimeDisplayController _animeDisplayController = Get.find();

  return SliverGridDelegateWithFixedCrossAxisCount(
    // 横轴数量
    crossAxisCount: _animeDisplayController.gridColumnCnt.value,
    // 横轴距离
    crossAxisSpacing: 3,
    // 竖轴距离
    mainAxisSpacing: 6,
    // 每个网格的比例(如果不显示名字或名字显示在封面内部，则使用31/45，否则31/56)
    childAspectRatio: _animeDisplayController.showNameBelowCover ? 31 / 56 : 31 / 43,
  );
}