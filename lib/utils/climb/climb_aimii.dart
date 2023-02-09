import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_filter.dart';
import 'package:flutter_test_future/utils/climb/climb.dart';
import 'package:flutter_test_future/utils/climb/climb_omofun.dart';

import '../../models/params/page_params.dart';

// 艾米动漫
class ClimbAimi extends Climb {
  String baseUrl = "https://www.aimidm.com";

  @override
  Future<Anime> climbAnimeInfo(Anime anime, {bool showMessage = true}) async {
    anime = await ClimbOmofun()
        .climbAnimeInfo(anime, showMessage: showMessage, sourceName: "艾米动漫");
    return anime;
  }

  @override
  Future<List<Anime>> searchAnimeByKeyword(String keyword) async {
    String url = "$baseUrl/index.php/vod/search.html?wd=$keyword";
    List<Anime> climbAnimes = await ClimbOmofun().searchAnimeByKeyword(keyword,
        url: url, foreignBaseUrl: baseUrl, sourceName: "艾米动漫");
    return climbAnimes;
  }

  @override
  Future<List<Anime>> climbDirectory(
      AnimeFilter filter, PageParams pageParams) async {
    return [];
  }
}
