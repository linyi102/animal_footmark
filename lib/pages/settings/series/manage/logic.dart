import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/anime_dao.dart';
import 'package:flutter_test_future/dao/series_dao.dart';
import 'package:flutter_test_future/models/series.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';

class SeriesManageLogic extends GetxController {
  // 所有系列
  List<Series> seriesList = [];
  bool loadingSeriesList = true;
  // 推荐创建的系列
  List<Series> recommendSeriesList = [];
  bool loadingRecommendSeriesList = true;

  var inputKeywordController = TextEditingController();
  String kw = "";

  int get recommendSeriesId => -1;
  int animeId;
  bool get enableSelectSeriesForAnime => animeId > 0;
  SeriesManageLogic(this.animeId);

  @override
  void onInit() {
    super.onInit();
    // 避免路由动画时查询数据库导致动画卡顿
    Future.delayed(const Duration(milliseconds: 100))
        .then((value) => getAllSeries());
  }

  @override
  void dispose() {
    inputKeywordController.dispose();
    super.dispose();
  }

  // 还原数据后，需要重新获取所有系列
  Future<void> getAllSeries() async {
    seriesList = await SeriesDao.getAllSeries();
    loadingSeriesList = false;
    // 动漫详情页进入系列页后，推荐还没生成，此时显示全部，推荐生成后会导致突然下移(闪烁)，所以此处不进行重绘
    // 而是等推荐系列生成完毕后一起显示
    // update();

    // 获取所有系列后，再根据所有系列生成推荐系列
    await getRecommendSeries();
    loadingRecommendSeriesList = false;
    update();
  }

  Future<void> getRecommendSeries() async {
    // 不要用clear，然后直接添加到recommendSeriesList
    // 因为在获取已创建的全部系列后会进行重绘，如果再重绘前清空了recommendSeriesList，会丢失滚动位置
    // 因此先存放到list，最终统一赋值给recommendSeriesList
    List<Series> list = [];

    if (enableSelectSeriesForAnime) {
      // 如果是动漫详情页进入的，则根据当前动漫生成推荐系列(只会生成1个)
      var anime = await SqliteUtil.getAnimeByAnimeId(animeId);
      String recommendSeriesName = _getRecommendSeriesName(anime.animeName);
      if (recommendSeriesName.isEmpty) {
        // 如果不是系列，则推荐根据动漫名字创建系列
        recommendSeriesName = anime.animeName;
      }
      int index = seriesList
          .indexWhere((_series) => _series.name == recommendSeriesName);
      // 先看所有系列中是否有，若有，但没有加入该系列，则显示加入，如还没有创建，则显示创建并加入

      if (index >= 0) {
        if (seriesList[index]
                .animes
                .indexWhere((_anime) => _anime.animeId == animeId) >=
            0) {
          // 该系列创建了，且已加入，那么什么都不做
        } else {
          // 该系列创建了，但没有加入，放到推荐中
          list.add(seriesList[index]);
        }
      } else {
        // 没有创建该系列，放到推荐中
        list.add(Series(recommendSeriesId, recommendSeriesName));
      }
    } else {
      // 否则根据收藏的所有动漫生成推荐系列
      var animes = await AnimeDao.getAllAnimes();
      for (var anime in animes) {
        String recommendSeriesName = _getRecommendSeriesName(anime.animeName);
        if (recommendSeriesName.isNotEmpty &&
            _isNotRecommended(recommendSeriesName, list)) {
          list.add(Series(recommendSeriesId, recommendSeriesName));
        }
      }
    }

    recommendSeriesList = list;
    update();
  }

  /// 还没推荐过(推荐系列中和所有系列中都没有)
  bool _isNotRecommended(
      String seriesName, List<Series> currentRecommentSeriesList) {
    return currentRecommentSeriesList
                .indexWhere((element) => element.name == seriesName) <
            0 &&
        seriesList.indexWhere((element) => element.name == seriesName) < 0;
  }

  /// 根据动漫名推出系列名
  String _getRecommendSeriesName(String name) {
    RegExp regExp =
        RegExp("(第.*(部|季|期)|ova|Ⅱ|oad|[1-9] |剧场版)", caseSensitive: false);
    var match = regExp.firstMatch(name);
    if (match == null || match[0] == null) return '';
    String seasonText = match[0]!;
    return name.substring(0, name.indexOf(seasonText)).trim();
  }
}
