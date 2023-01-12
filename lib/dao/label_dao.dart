import 'package:flutter_test_future/dao/anime_label_dao.dart';
import 'package:flutter_test_future/models/label.dart';

import '../utils/log.dart';
import '../utils/sqlite_util.dart';

class LabelDao {
  static final db = SqliteUtil.database;
  static const table = "label";
  static const columnId = "id";
  static const columnName = "name";

  // 建表
  static createTable() async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $table (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      name      TEXT NOT NULL
    );
    ''');
  }

  // 新建标签，并返回新插入记录的id，返回0表示插入失败
  static Future<int> insert(Label label) async {
    Log.info("sql:insert($label)");
    // 插入除id以外的信息(因为id自增)
    return await db.insert(table, {columnName: label.name});
  }

  static Future<int> delete(int id) async {
    Log.info("sql:delete($id)");
    // 先删除动漫标签表中有该标签的记录
    await AnimeLabelDao.deleteByLabelId(id);
    // 再删除该标签
    return await db.delete(table, where: "$columnId = ?", whereArgs: [id]);
  }

  static Future<int> update(int id, String newName) async {
    Log.info("sql:update(id=$id, newName=$newName)");
    return await db.rawUpdate('''
    update $table set $columnName = '$newName' where $columnId = $id;
    ''');
  }

  // 获取所有标签列表
  static Future<List<Label>> getAllLabels() async {
    Log.info("sql:getAllLabels");
    List<Map<String, Object?>> maps = await db.query(table);
    return maps.map((e) => Label.fromMap(e)).toList();
  }

  // 根据id获取标签
  static Future<Label> getLabelById(int id) async {
    Log.info("sql:getAllLabels");
    List<Map<String, Object?>> maps =
        await db.query(table, where: "$columnId = ?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Label.fromMap(maps[0]);
    } else {
      return Label.noneLabel();
    }
  }

  // 搜索标签
  static Future<List<Label>> searchLabel(String kw) async {
    Log.info("sql:searchLabel(kw=$kw)");
    List<Map<String, Object?>> maps = await db.rawQuery('''
    select * from $table where $columnName like '%$kw%';            
    ''');
    return maps.map((e) => Label.fromMap(e)).toList();
  }

  // 查询是否存在标签名
  static Future<bool> existLabelName(String name) async {
    Log.info("sql:existLabelName(name=$name)");
    return (await db.query(table, where: "$columnName = ?", whereArgs: [name]))
        .isNotEmpty;
  }
}
