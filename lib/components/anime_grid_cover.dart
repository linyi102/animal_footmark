import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';

class AnimeGridCover extends StatelessWidget {
  final Anime _anime;
  const AnimeGridCover(this._anime, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 31 / 43, // 固定大小
      // aspectRatio: 41 / 63, // 固定大小
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: _anime.animeCoverUrl.isEmpty
            ? Center(
                child: Text(
                  _anime.animeName.substring(
                      0,
                      _anime.animeName.length >
                              3 // 最低长度为3，此时下标最大为2，才可以设置end为3，[0, 3)
                          ? 3
                          : _anime.animeName.length), // 第二个参数如果只设置为3可能会导致越界
                  style: const TextStyle(fontSize: 20),
                ),
              )
            : CachedNetworkImage(
                imageUrl: _anime.animeCoverUrl,
                fit: BoxFit.fitHeight,
              ),
      ),
    );
  }
}
