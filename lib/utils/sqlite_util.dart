// ignore_for_file: avoid_print
import 'package:flutter_test_future/classes/anime.dart';
import 'package:flutter_test_future/classes/episode.dart';
import 'package:flutter_test_future/classes/history_plus.dart';
import 'package:flutter_test_future/classes/record.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteUtil {
  // 单例模式
  static SqliteUtil? _instance;

  SqliteUtil._();

  static Future<SqliteUtil> getInstance() async {
    _database = await _initDatabase();
    return _instance ??= SqliteUtil._();
  }

  static const sqlFileName = 'mydb.db';
  static late Database _database;
  static late String dbPath;

  static _initDatabase() async {
    dbPath = "${(await getExternalStorageDirectory())!.path}/$sqlFileName";
    // String path = "${await getDatabasesPath()}/$sqlFileName";

    print("👉path=$dbPath");
    await deleteDatabase(dbPath); // 删除数据库
    return await openDatabase(
      dbPath,
      onCreate: (Database db, int version) {
        Future(() {
          _createInitTable(db); // 只会在数据库创建时才会创建表，记得传入的是db，而不是databse
        }).then((value) => _insertInitData(db));
      },
      version: 1, // onCreate must be null if no version is specified
    );
  }

  static void _createInitTable(Database db) async {
    await db.execute('''
      CREATE TABLE tag (
          tag_id    INTEGER PRIMARY KEY AUTOINCREMENT,
          tag_name  TEXT    NOT NULL,
          tag_order INTEGER
          -- UNIQUE(tag_name)
      );
      ''');
    await db.execute('''
      CREATE TABLE anime (
          anime_id            INTEGER PRIMARY KEY AUTOINCREMENT,
          anime_name          TEXT    NOT NULL,
          anime_episode_cnt   INTEGER NOT NULL,
          anime_desc          TEXT, -- 描述
          tag_name            TEXT,
          last_mode_tag_time  TEXT, -- 最后一次修改标签的时间，可以实现新移动的在列表上面
          FOREIGN KEY (
              tag_name
          )
          REFERENCES tag (tag_name) 
      );
      ''');
    await db.execute('''
      CREATE TABLE history (
          history_id     INTEGER PRIMARY KEY AUTOINCREMENT,
          date           TEXT,
          anime_id       INTEGER NOT NULL,
          episode_number INTEGER NOT NULL,
          FOREIGN KEY (
              anime_id
          )
          REFERENCES anime (anime_id) 
      );
      ''');
    await db.execute('''
      CREATE INDEX index_anime_name ON anime (anime_name);
      '''); // 不知道为啥放在创建history语句前就会导致history表还没创建就插入数据，从而导致错误
  }

  static void _insertInitData(Database db) async {
    await db.rawInsert('''
      insert into tag(tag_name, tag_order)
      -- values('拾'), ('途'), ('终'), ('搁'), ('弃');
      values('收集', 0), ('旅途', 1), ('终点', 2);
    ''');
    for (int i = 0; i < 1; ++i) {
      await db.rawInsert('''
      insert into anime(anime_name, anime_episode_cnt, tag_name, last_mode_tag_time)
      values('进击的巨人第一季', '24', '收集', '2021-12-10 20:23:22'), -- 手动添加是一定注意是两位数表示月日，否则会出错，比如6月>12月，因为6>1
          ('JOJO的奇妙冒险第六季 石之海', '12', '收集', '2021-12-09 20:23:22'),
          ('刀剑神域第一季', '24', '收集', '2021-12-08 20:23:22'),
          ('进击的巨人第二季', '12', '收集', '2021-12-07 20:23:22'),
          ('在下坂本，有何贵干？', '12', '终点', '2021-12-06 20:23:22');
    ''');
    }
    for (int i = 0; i < 1; ++i) {
      await db.rawInsert('''
      insert into history(date, anime_id, episode_number)
      values('2021-12-15 20:17:58', 2, 1),
          ('2021-12-15 20:23:22', 2, 3),
          ('2020-06-24 15:20:12', 1, 1),
          ('2021-12-04 14:11:27', 4, 2),
          ('2021-11-07 13:13:13', 3, 1),
          ('2021-10-07 12:12:12', 5, 2);
    ''');
    }
  }

  static void updateAnime(Anime oldAnime, Anime newAnime) async {
    print("sql: updateAnime");
    String datetime = DateTime.now().toString();
    print(
        "oldAnime.tagName=${oldAnime.tagName}, newAnime.tagName=${newAnime.tagName}");
    if (oldAnime.tagName != newAnime.tagName) {
      await _database.rawUpdate('''
      update anime
      set anime_name = '${newAnime.animeName}',
          anime_episode_cnt = ${newAnime.animeEpisodeCnt},
          tag_name = '${newAnime.tagName}',
          last_mode_tag_time = '$datetime' -- 更新最后修改标签的时间
      where anime_id = ${oldAnime.animeId};
      ''');
      print("last_mode_tag_time: $datetime");
    } else {
      await _database.rawUpdate('''
      update anime
      set anime_name = '${newAnime.animeName}',
          anime_episode_cnt = ${newAnime.animeEpisodeCnt}
      where anime_id = ${oldAnime.animeId};
      ''');
    }
  }

  static void insertAnime(Anime anime) async {
    print("sql: insertAnime");
    String datetime = DateTime.now().toString();
    await _database.rawInsert('''
    insert into anime(anime_name, anime_episode_cnt, tag_name, last_mode_tag_time)
    values('${anime.animeName}', '${anime.animeEpisodeCnt}', '${anime.tagName}', '$datetime');
    ''');
  }

  static void insertHistoryItem(
      int animeId, int episodeNumber, String date) async {
    print("sql: insertHistoryItem");
    await _database.rawInsert('''
    insert into history(date, anime_id, episode_number)
    values('$date', $animeId, $episodeNumber);
    ''');
  }

  static void deleteHistoryItem(
      String? date, int animeId, int episodeNumber) async {
    print("sql: deleteHistoryItem");
    await _database.rawDelete('''
    delete from history
    where date = '$date' and anime_id = $animeId and episode_number = $episodeNumber;
    ''');
  }

  static void insertTagName(String tagName, int tagOrder) async {
    print("sql: insertTagName");
    await _database.rawInsert('''
    insert into tag(tag_name, tag_order)
    values('$tagName', $tagOrder);
    ''');
  }

  static void updateTagName(String oldTagName, String newTagName) async {
    print("sql: updateTagNameByTagId");
    await _database.rawUpdate('''
    update tag
    set tag_name = '$newTagName'
    where tag_name = '$oldTagName';
    ''');
  }

  static Future<bool> updateTagOrder(List<String> tagNames) async {
    print("sql: updateTagOrder");
    // 错误：把表中标签的名字和list中对应起来即可。这样会导致动漫标签不匹配
    // 应该重建一个order列，从0开始
    for (int i = 0; i < tagNames.length; ++i) {
      await _database.rawUpdate('''
      update tag
      set tag_order = $i 
      where tag_name = '${tagNames[i]}';
      ''');
    }
    return true;
  }

  static void deleteTagByTagName(String tagName) async {
    print("sql: deleteTagByTagName");
    await _database.rawDelete('''
    delete from tag
    where tag_name = '$tagName';
    ''');
  }

  static Future<List<String>> getAllTags() async {
    print("sql: getAllTags");
    var list = await _database.rawQuery('''
    select tag_name
    from tag
    order by tag_order
    ''');
    List<String> res = [];
    for (var item in list) {
      res.add(item["tag_name"] as String);
    }
    return res;
  }

  static Future<Anime> getAnimeByAnimeId(int animeId) async {
    print("sql: getAnimeByAnimeId");
    var list = await _database.rawQuery('''
    select anime_name, anime_episode_cnt, tag_name
    from anime
    where anime_id = $animeId;
    ''');
    Anime anime = Anime(
        animeId: animeId,
        animeName: list[0]['anime_name'] as String,
        animeEpisodeCnt: list[0]['anime_episode_cnt'] as int,
        tagName: list[0]['tag_name'] as String);
    return anime;
  }

  static Future<int> getAnimeLastId() async {
    print("sql: getAnimeLastId");
    var list = await _database.rawQuery('''
    select last_insert_rowid() as last_id
    from anime;
    ''');
    int lastId = list[0]["last_id"] as int;
    print("sql: getAnimeLastId=$lastId");
    return lastId;
  }

  static Future<String> getTagNameByAnimeId(int animeId) async {
    print("sql: getTagNameByAnimeId");
    var list = await _database.rawQuery('''
    select tag_name
    from anime
    where anime.anime_id = $animeId;
    ''');
    return list[0]['tag_name'] as String;
  }

  static Future<List<Episode>> getAnimeEpisodeHistoryById(Anime anime) async {
    print("sql: getAnimeEpisodeHistoryById");
    int animeEpisodeCnt = anime.animeEpisodeCnt;

    var list = await _database.rawQuery('''
    select date, episode_number
    from anime inner join history
        on anime.anime_id = ${anime.animeId} and anime.anime_id = history.anime_id;
    ''');
    // print("查询结果：$list");
    List<Episode> episodes = [];
    for (int episodeNumber = 1;
        episodeNumber <= animeEpisodeCnt;
        ++episodeNumber) {
      episodes.add(Episode(episodeNumber));
    }
    // 遍历查询结果，每个元素都是一个键值对(列名-值)
    for (var element in list) {
      int episodeNumber = element['episode_number'] as int;
      episodes[episodeNumber - 1].dateTime = element['date'] as String;
    }
    return episodes;
  }

  static Future<int> getAnimesCntBytagName(String tagName) async {
    print("sql: getAnimesCntBytagName");
    var list = await _database.rawQuery('''
    select count(anime.anime_id) cnt
    from anime
    where anime.tag_name = '$tagName';
    ''');
    return list[0]["cnt"] as int;
  }

  static Future<List<Anime>> getAllAnime() async {
    print("sql: getAllAnime");

    var list = await _database.rawQuery('''
    select anime_id, anime_name, anime_episode_cnt
    from anime
    '''); // 按anime_id倒序，保证最新添加的动漫在最上面

    List<Anime> res = [];
    for (var element in list) {
      var checkedEpisodeCntList = await _database.rawQuery('''
      select count(anime.anime_id) cnt
      from anime inner join history
          on anime.anime_id = ${element['anime_id']} and anime.anime_id = history.anime_id;
      ''');
      int checkedEpisodeCnt = checkedEpisodeCntList[0]["cnt"] as int;

      res.add(Anime(
        animeId: element['anime_id'] as int, // 进入详细页面后需要该id
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: element['anime_episode_cnt'] as int,
        checkedEpisodeCnt: checkedEpisodeCnt,
      ));
    }
    return res;
  }

  static Future<List<Anime>> getAnimesBySearch(String keyWord) async {
    print("sql: getAnimesBySearch");

    var list = await _database.rawQuery('''
    select anime_id, anime_name, anime_episode_cnt
    from anime
    where anime_name LIKE '%$keyWord%';
    ''');

    List<Anime> res = [];
    for (var element in list) {
      var checkedEpisodeCntList = await _database.rawQuery('''
      select count(anime.anime_id) cnt
      from anime inner join history
          on anime.anime_id = ${element['anime_id']} and anime.anime_id = history.anime_id;
      ''');
      int checkedEpisodeCnt = checkedEpisodeCntList[0]["cnt"] as int;

      res.add(Anime(
        animeId: element['anime_id'] as int, // 进入详细页面后需要该id
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: element['anime_episode_cnt'] as int,
        checkedEpisodeCnt: checkedEpisodeCnt,
      ));
    }
    return res;
  }

  static getAllAnimeBytagName(String tagName, int offset, int number) async {
    print("sql: getAllAnimeBytagName");

    var list = await _database.rawQuery('''
    select anime_id, anime_name, anime_episode_cnt, tag_name
    from anime
    where tag_name = '$tagName'
    order by last_mode_tag_time desc -- 按最后修改标签时间倒序排序，保证最新修改标签在列表上面
    limit $number offset $offset;
    '''); // 按anime_id倒序，保证最新添加的动漫在最上面

    List<Anime> res = [];
    for (var element in list) {
      var checkedEpisodeCntList = await _database.rawQuery('''
      select count(anime.anime_id) cnt
      from anime inner join history
          on anime.anime_id = ${element['anime_id']} and anime.anime_id = history.anime_id;
      ''');
      int checkedEpisodeCnt = checkedEpisodeCntList[0]["cnt"] as int;

      res.add(Anime(
        animeId: element['anime_id'] as int, // 进入详细页面后需要该id
        animeName: element['anime_name'] as String,
        animeEpisodeCnt: element['anime_episode_cnt'] as int,
        tagName: tagName, // 必要：用于和从详细页面返回的新标签比较，看是否需要移动位置
        checkedEpisodeCnt: checkedEpisodeCnt,
      ));
    }
    return res;
  }

  static getAnimeCntPerTag() async {
    print("sql: getAnimeCntPerTag");

    var list = await _database.rawQuery('''
    select count(anime_id) as anime_cnt, tag.tag_name, tag.tag_order
    from tag left outer join anime -- sqlite只支持左外联结
        on anime.tag_name = tag.tag_name
    group by tag.tag_name -- 应该按照tag的tag_name分组
    order by tag.tag_order; -- 按照用户调整的顺序排序，否则会导致数量与实际不符
    ''');

    List<int> res = [];
    for (var item in list) {
      print('${item['tag_name']}-${item['anime_cnt']}-${item['tag_order']}');
      res.add(item['anime_cnt'] as int);
    }
    return res;
  }

  static Future<List<HistoryPlus>> getAllHistoryPlus() async {
    print("sql: getAllHistoryPlus");
    String earliestDate;
    // earliestDate = SPUtil.getString("earliest_date", defaultValue: "");
    // if (earliestDate.isEmpty) {
    var list = await _database.rawQuery('''
      select min(date) min_date
      from history;
      ''');
    if (list[0]['min_date'] == null) return []; // 还没有历史，直接返回，否则强制转为String会报错
    earliestDate = list[0]['min_date'] as String;
    //   SPUtil.setString("earliest_date", earliestDate);
    // }
    print("最早日期为：$earliestDate");
    DateTime earliestDateTime = DateTime.parse(earliestDate);
    int earliestYear = earliestDateTime.year;
    int earliestMonth = earliestDateTime.month;

    // 先找到该月看的所有动漫id，然后根据动漫id去重，再根据动漫id得到当月看的最小值和最大值
    List<HistoryPlus> history = [];
    DateTime now = DateTime.now();
    int curMonth = now.month;
    int curYear = now.year;
    for (int year = curYear; year >= earliestYear; --year) {
      int month = curMonth;
      int border = 1;
      if (year != curYear) month = 12;
      if (year == earliestYear) border = earliestMonth;
      for (; month >= border; --month) {
        String date;
        if (month >= 10) {
          date = "$year-$month";
        } else {
          date = "$year-0$month";
        }
        var list = await _database.rawQuery('''
        select distinct anime.anime_id, anime.anime_name
        from history, anime
        where date like '$date%' and history.anime_id = anime.anime_id
        order by date desc; -- 倒序
        ''');
        List<Anime> animes = [];
        for (var item in list) {
          animes.add(Anime(
              animeId: item['anime_id'] as int,
              animeName: item['anime_name'] as String,
              animeEpisodeCnt: 0));
        }
        if (animes.isEmpty) continue; // 没有观看记录时直接跳过

        List<Record> records = [];
        // 对于每个动漫，找到当月观看的最小值的最大值
        for (var anime in animes) {
          // print(anime);
          list = await _database.rawQuery('''
          select min(episode_number) as start
          from history
          where date like '$date%' and anime_id = ${anime.animeId};
          ''');
          int startEpisodeNumber = list[0]['start'] as int;
          list = await _database.rawQuery('''
          select max(episode_number) as end
          from history
          where date like '$date%' and anime_id = ${anime.animeId};
          ''');
          int endEpisodeNumber = list[0]['end'] as int;
          Record record = Record(anime, startEpisodeNumber, endEpisodeNumber);
          // print(record);
          records.add(record);
        }
        history.add(HistoryPlus(date, records));
      }
    }
    // for (var item in history) {
    //   print(item);
    // }
    return history;
  }
}
