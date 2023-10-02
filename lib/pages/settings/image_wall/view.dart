import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/modules/note_img_viewer.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/values/values.dart';

class ImageWallPage extends StatefulWidget {
  const ImageWallPage({super.key, required this.imageUrls});
  final List<String> imageUrls;

  @override
  State<ImageWallPage> createState() => _ImageWallPageState();
}

class _ImageWallPageState extends State<ImageWallPage> {
  int get groupCnt => 3;
  List<List<String>> groups = [];
  List<ScrollController> scrollControllers = [];
  List<Timer> timers = [];

  bool playing = false;
  int speed = 1; // 当前速度

  int get maxSpeed => 3; // 最大速度
  int get standardSpaceMs => 3000; // 标准间隔为3s
  int get spaceMs => standardSpaceMs ~/ speed; // 当前间隔
  Duration get interval => Duration(milliseconds: spaceMs);

  double get groupSpacing => 5;
  double get imageSpacing => 4;
  double get imageWidth => 180;
  double get imageHeight => 100;
  double get imageExtent => imageWidth + imageSpacing;

  bool get enableBlur => false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < groupCnt; ++i) {
      groups.add([]);
      scrollControllers.add(ScrollController());
    }
    for (var i = 0; i < widget.imageUrls.length; ++i) {
      groups[i % groupCnt].add(widget.imageUrls[i]);
    }
    _play();
  }

  @override
  void dispose() {
    for (var i = 0; i < groupCnt; ++i) {
      scrollControllers[i].dispose();
    }
    super.dispose();
  }

  _play() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      timers.clear();

      for (var i = 0; i < groupCnt; ++i) {
        var scrollController = scrollControllers[i];

        // 立即执行
        _scrollOnceImage(scrollController);
        // 再定时
        var timer = Timer.periodic(interval, (timer) {
          _scrollOnceImage(scrollController);
        });
        timers.add(timer);
      }
      if (mounted) {
        setState(() {
          playing = true;
        });
      }
    });
  }

  void _scrollOnceImage(ScrollController scrollController) {
    if (!scrollController.hasClients) return;

    scrollController.animateTo(
      scrollController.offset + imageExtent,
      duration: interval,
      curve: Curves.linear,
    );
  }

  _pause() {
    for (var i = 0; i < groupCnt; ++i) {
      var scrollController = scrollControllers[i];
      // 立即暂停
      scrollController.animateTo(scrollController.offset,
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
      // 取消定时器
      timers[i].cancel();
    }
    if (mounted) {
      setState(() {
        playing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true)
          .copyWith(scaffoldBackgroundColor: Colors.black),
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            Expanded(child: _buildGallary()),
          ],
        ),
      ),
    );
  }

  Column _buildGallary() {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [for (var i = 0; i < groups.length; ++i) _buildGroup(i)],
    );
  }

  _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          ),
          const Spacer(),
          _buildSpeedControlButton(),
          _buildPlayControlButton(),
          _buildShuffleButton(),
        ],
      ),
    );
  }

  IconButton _buildShuffleButton() {
    return IconButton(
      onPressed: () {
        for (var i = 0; i < groups.length; ++i) {
          groups[i].shuffle();
        }
        setState(() {});
      },
      icon: const Icon(Icons.shuffle_rounded, size: 20),
    );
  }

  IconButton _buildPlayControlButton() {
    return IconButton(
      onPressed: () => playing ? _pause() : _play(),
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }

  IconButton _buildSpeedControlButton() {
    return IconButton(
        onPressed: () {
          _pause();
          speed = speed % maxSpeed + 1;
          // 需要重新创建定时器
          _play();
        },
        icon: Text(
          '${speed}x',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
  }

  _buildGroup(int groupIndex) {
    var group = groups[groupIndex];
    if (group.isEmpty) return const SizedBox();

    bool showDropShadow = groupIndex == groups.length - 1;

    return Container(
      height: showDropShadow ? imageHeight * 2 + 20 : imageHeight,
      margin: EdgeInsets.symmetric(vertical: groupSpacing),
      child: ListView.builder(
        controller: scrollControllers[groupIndex],
        reverse: groupIndex % 2 == 1,
        scrollDirection: Axis.horizontal,
        itemExtent: imageExtent,
        itemBuilder: (context, index) {
          var imageUrl = group[index % group.length];

          var image = Container(
            height: imageHeight,
            width: imageWidth,
            margin: EdgeInsets.symmetric(horizontal: imageSpacing),
            // color: Colors.red,
            // child: Text(imageUrl),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
                child: CommonImage(imageUrl)),
          );

          return Scrollbar(
            thumbVisibility: false,
            trackVisibility: false,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _toImageViewerPage(imageUrl),
                    child: image,
                  ),
                  if (showDropShadow) _buildDropShadowImage(image),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _buildDropShadowImage(Container image) {
    return Container(
      padding: EdgeInsets.only(top: groupSpacing * 2),
      // 翻转
      child: Transform.flip(
        flipY: true,
        // 渐变
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black26, Colors.transparent])
              .createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
          blendMode: BlendMode.dstIn,
          child: Stack(
            children: [
              image,
              // 模糊
              if (enableBlur)
                ClipRect(
                  child: BackdropFilter(
                    blendMode: BlendMode.srcIn,
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: SizedBox(height: imageHeight, width: imageWidth),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toImageViewerPage(String imageUrl) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerPage(relativeLocalImages: [
            RelativeLocalImage(0, ImageUtil.getRelativeNoteImagePath(imageUrl))
          ]),
        ));
  }
}
