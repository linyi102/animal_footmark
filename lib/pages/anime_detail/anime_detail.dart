import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/anime_controller.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/app_bar.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/episode.dart';
import 'package:flutter_test_future/pages/anime_detail/widgets/info.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

class AnimeDetailPlus extends StatefulWidget {
  final Anime anime;

  const AnimeDetailPlus(
    this.anime, {
    Key? key,
  }) : super(key: key);

  @override
  _AnimeDetailPlusState createState() => _AnimeDetailPlusState();
}

class _AnimeDetailPlusState extends State<AnimeDetailPlus>
    with SingleTickerProviderStateMixin {
  late final AnimeController animeController; // 动漫详细页的动漫
  Anime get _anime => animeController.anime.value;
  final LabelsController labelsController = Get.find(); // 动漫详细页的标签

  bool hideNoteInAnimeDetail =
      SPUtil.getBool("hideNoteInAnimeDetail", defaultValue: false);

  // 选择显示的集范围
  int currentStartEpisodeNumber = 1;
  final int episodeRangeSize = 50;

  @override
  void initState() {
    super.initState();
    // 如果没有收藏，则不允许进入
    if (widget.anime.animeId <= 0) {
      Navigator.of(context).pop();
      showToast("无法进入未收藏动漫");
    }

    animeController = Get.put(
      AnimeController(),
      // 不能使用动漫id作为tag，因为可能会再次进入相同id的动漫详细页
      // tag: widget.anime.animeId.toString(),
      // tag: UniqueKey().toString(),
    );
    animeController.enterDetailPage();

    if (widget.anime.animeId > 0) {
      currentStartEpisodeNumber = SPUtil.getInt(
          "${widget.anime.animeId}-currentStartEpisodeNumber",
          defaultValue: 1);
      _loadData();
    } else {
      // 爬取详细信息
      _climbAnimeInfo();
    }
  }

  void _loadData() async {
    animeController
        .setAnime(widget.anime); // 信息不完全，先提前展示封面和名字，否则展示的是上次进入的动漫封面和名字
    // await Future.delayed(const Duration(seconds: 2));
    Anime anime = await SqliteUtil.getAnimeByAnimeId(
        widget.anime.animeId); // 一定要return，value才有值
    // 如果没有从数据库中找到，则直接退出该页面
    if (!anime.isCollected()) {
      Navigator.of(context).pop();
      showToast("无法进入未收藏动漫");
    }

    // 等待加载好动漫后，就可以确定当前动漫存在，于是根据id加载集信息、评价数量、标签等
    animeController.setAnime(anime);
  }

  // 用于传回到动漫列表页
  void _popPage() {
    _anime.checkedEpisodeCnt = 0;
    for (var episode in animeController.episodes) {
      if (episode.isChecked()) _anime.checkedEpisodeCnt++;
    }
    // SqliteUtil.updateDescByAnimeId(_anime.animeId, _anime.animeDesc);
    // SqliteUtil.updateAnimeNameByAnimeId(_anime.animeId, _anime.animeName);
    Navigator.pop(context, _anime);
  }

  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);

    return WillPopScope(
      onWillPop: () async {
        Log.info("按返回键，返回anime");
        _popPage();
        // 返回的_anime用到了id(列表页面和搜索页面)和name(爬取页面)
        // 完成集数因为切换到小的回顾号会导致不是最大回顾号完成的集数，所以那些页面会通过传回的id来获取最新动漫信息
        Log.info("返回true");
        return true;
      },
      child: Scaffold(
        body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: RefreshIndicator(
              onRefresh: () async {
                // 使用await后，只有当获取信息完成后，加载圈才会消失
                await _climbAnimeInfo();
              },
              child: Stack(children: [
                CustomScrollView(
                  slivers: [
                    // 封面背景
                    _buildSliverAppBar(context),
                    // 动漫信息
                    _buildAnimeInfo(context),
                    // 集信息
                    _buildSliverListBody()
                  ],
                ),
                _buildButtonsBarAboutEpisodeMulti()
              ]),
            )),
      ),
    );
  }

  // 构建动漫信息(名字、评分、其他信息)
  _buildAnimeInfo(BuildContext context) {
    return AnimeDetailInfo(animeController: animeController);
  }

  // 构建主体(集信息页)
  _buildSliverListBody() {
    return AnimeDetailEpisodeInfo(animeController: animeController);
  }

  _buildSliverAppBar(BuildContext context) {
    return AnimeDetailAppBar(
      animeController: animeController,
      popPage: _popPage,
      loadData: _loadData,
    );
  }

  /// 显示底部集多选操作栏
  _buildButtonsBarAboutEpisodeMulti() {
    return Obx(() => !animeController.multiSelected.value
        ? Container()
        : Container(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 8,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50))),
              // 圆角
              clipBehavior: Clip.antiAlias,
              // 设置抗锯齿，实现圆角背景
              margin: const EdgeInsets.fromLTRB(80, 20, 80, 20),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        if (animeController.mapSelected.length ==
                            animeController.episodes.length) {
                          // 全选了，点击则会取消全选
                          animeController.mapSelected.clear();
                        } else {
                          // 其他情况下，全选
                          for (int j = 0;
                              j < animeController.episodes.length;
                              ++j) {
                            animeController.mapSelected[j] = true;
                          }
                        }
                        setState(() {});
                      },
                      icon: const Icon(Icons.select_all_rounded),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () async {
                        await animeController.pickDateForEpisodes(
                            context: context);
                        // 退出多选模式
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.edit_calendar_rounded),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _quitMultiSelectState();
                      },
                      icon: const Icon(Icons.exit_to_app),
                    ),
                  ),
                ],
              ),
            ),
          ));
  }

  void _quitMultiSelectState() {
    // 清空选择的动漫(注意在修改数量之后)，并消除多选状态
    animeController.multiSelected.value = false;
    animeController.mapSelected.clear();
    setState(() {});
  }

  bool _climbing = false;

  Future<bool> _climbAnimeInfo() async {
    if (_anime.animeUrl.isEmpty) {
      if (_anime.isCollected()) showToast("不能更新自定义动漫");
      return false;
    }
    if (_climbing) {
      if (_anime.isCollected()) showToast("正在获取信息");
      return false;
    }
    // if (_anime.isCollected()) showToast("更新中...");
    _climbing = true;
    // oldAnime、newAnime、_anime引用的是同一个对象，修改后无法比较，因此需要先让oldAnime引用深拷贝的_anime
    // 因为更新时会用到oldAnime的id、tagName、animeEpisodeCnt，所以只深拷贝这些成员
    Anime oldAnime = _anime.copyWith();
    // 需要传入_anime，然后会修改里面的值，newAnime也会引用该对象
    Log.info("_anime.animeEpisodeCnt = ${_anime.animeEpisodeCnt}");
    Anime newAnime = await ClimbAnimeUtil.climbAnimeInfoByUrl(_anime);
    // 如果更新后动漫集数比原来的集数小，则不更新集数
    // 目的是解决一个bug：东京喰种PINTO手动设置集数为2后，更新动漫，获取的集数为0，集数更新为0后，此时再次手动修改集数，因为传入的初始值为0，即使按了取消，由于会返回初始值0，因此会导致集数变成了0
    // 因此，只要用户设置了集数，即使更新的集数小，也会显示用户设置的集数，只有当更新集数大时，才会更新。
    // 另一种解决方式：点击修改集数按钮时，传入此时_episodes的长度，而不是_anime.animeEpisodeCnt，这样就保证了传入给修改集数对话框的初始值为原来的集数，而不是更新的集数。
    Log.info("_anime.animeEpisodeCnt = ${_anime.animeEpisodeCnt}");
    if (newAnime.animeEpisodeCnt < _anime.animeEpisodeCnt) {
      newAnime.animeEpisodeCnt = _anime.animeEpisodeCnt;
    }
    SqliteUtil.updateAnime(oldAnime, newAnime).then((value) {
      // 如果集数变大，则重新加载页面。且插入到更新记录表中，然后重新获取所有更新记录，便于在更新记录页展示
      if (newAnime.animeEpisodeCnt > oldAnime.animeEpisodeCnt) {
        animeController.loadEpisode();
        animeController.updateAnimeEpisodeCnt(newAnime.animeEpisodeCnt);
        // 调用控制器，添加更新记录到数据库并更新内存数据
        final UpdateRecordController updateRecordController = Get.find();
        updateRecordController.updateSingaleAnimeData(oldAnime, newAnime);
      }
    });
    _climbing = false;
    // 播放状态无法实时更新
    animeController.setAnime(newAnime);
    // 手动更新
    animeController.updateAnimePlayStatus(newAnime.playStatus);
    return true;
  }

  _showReviewNumberIcon() {
    switch (_anime.reviewNumber) {
      case 1:
        return const Icon(Icons.looks_one_outlined);
      case 2:
        return const Icon(Icons.looks_two_outlined);
      case 3:
        return const Icon(Icons.looks_3_outlined);
      case 4:
        return const Icon(Icons.looks_4_outlined);
      case 5:
        return const Icon(Icons.looks_5_outlined);
      case 6:
        return const Icon(Icons.looks_6_outlined);
      default:
        return const Icon(Icons.error_outline_outlined);
    }
  }
}
