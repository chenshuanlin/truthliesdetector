import 'package:flutter/material.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// 全域懸浮球元件，可在 App 內外使用。
class FloatingActionMenu extends StatefulWidget {
  final ScreenshotController? screenshotController;
  final Function(int)? onTap;
  final VoidCallback? onClose;

  const FloatingActionMenu({
    super.key,
    this.screenshotController,
    this.onTap,
    this.onClose,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;
  Offset _offset = Offset.zero;

  final double _fabSize = 56.0;
  final double _childFabSize = 45.0;
  final double _spacing = 60.0;
  final double _bottomNavBarEstimatedHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // 預設右下角位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offset = Offset(
        MediaQuery.of(context).size.width - _fabSize - 16.0,
        MediaQuery.of(context).size.height -
            _fabSize -
            16.0 -
            _bottomNavBarEstimatedHeight,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // 懸浮球開關控制
  // --------------------------------------------------
  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // --------------------------------------------------
  // 截圖/選圖片 → AIchat
  // --------------------------------------------------
  Future<void> _recognizeImage() async {
    _toggleMenu();
    try {
      Uint8List? imageBytes;
      if (widget.screenshotController != null) {
        imageBytes = await widget.screenshotController!.capture();
      } else {
        final pick = await FilePicker.platform.pickFiles(type: FileType.image);
        if (pick != null && pick.files.isNotEmpty) {
          imageBytes = pick.files.single.bytes;
        }
      }

      if (imageBytes != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIchat(
              initialQuery: '請幫我辨識這張圖片。',
              capturedImageBytes: imageBytes,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未選擇圖片')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('圖片辨識失敗：$e')),
      );
    }
  }

  // --------------------------------------------------
  // 手動輸入網址分析
  // --------------------------------------------------
  void _showUrlInputDialog() {
    _toggleMenu();
    final TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('輸入網址進行查證'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: '請輸入網址（http 或 https 開頭）'),
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('查證'),
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AIchat(
                        initialQuery: '請幫我分析這個網址的內容：$url',
                      ),
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // 開啟主應用頁面
  // --------------------------------------------------
  void _openApp() async {
    _toggleMenu();
    if (widget.onTap != null) {
      widget.onTap!(0);
    } else {
      // 若在懸浮模式中
      if (!await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    }
  }

  // --------------------------------------------------
  // 在 App 外開啟懸浮球
  // --------------------------------------------------
  static Future<void> showGlobalBall() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
    await FlutterOverlayWindow.showOverlay(
      height: 100,
      width: 100,
      alignment: OverlayAlignment.centerRight,
      enableDrag: true,
      overlayTitle: "TruthLiesDetector",
      overlayContent: "AI懸浮球已啟動",
      flag: OverlayFlag.defaultFlag,
    );
  }

  // --------------------------------------------------
  // 建立子按鈕
  // --------------------------------------------------
  Widget _buildSubMenuButton({
    required Widget child,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    String? heroTag,
  }) {
    return ScaleTransition(
      scale: _animation,
      child: SizedBox(
        width: _childFabSize,
        height: _childFabSize,
        child: FloatingActionButton(
          heroTag: heroTag,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(color: foregroundColor, width: 2),
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // 畫面
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double halfFabSize = _fabSize / 2;
    final double halfChildFabSize = _childFabSize / 2;

    return Stack(
      children: [
        // 主懸浮球（可拖曳）
        Positioned(
          left: _offset.dx,
          top: _offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _offset = Offset(
                  (_offset.dx + details.delta.dx).clamp(
                    0.0,
                    MediaQuery.of(context).size.width - _fabSize,
                  ),
                  (_offset.dy + details.delta.dy).clamp(
                    0.0,
                    MediaQuery.of(context).size.height -
                        _fabSize -
                        _bottomNavBarEstimatedHeight,
                  ),
                );
              });
            },
            child: FloatingActionButton(
              heroTag: 'mainFloatingButton',
              onPressed: _toggleMenu,
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
                side: const BorderSide(color: Colors.white, width: 3),
              ),
              child: Image.asset(
                'lib/assets/logo2.png',
                width: 50,
                height: 50,
              ),
            ),
          ),
        ),

        // 展開子選單
        if (_isOpen) ...{
          // 開啟應用程式
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize - (_spacing * 1.5),
            child: _buildSubMenuButton(
              heroTag: 'openAppButton',
              child: const Icon(Icons.home, size: 22),
              onPressed: _openApp,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 網址輸入
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize - (_spacing * 0.5),
            child: _buildSubMenuButton(
              heroTag: 'searchButton',
              child: const Icon(Icons.search, size: 22),
              onPressed: _showUrlInputDialog,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 圖片辨識
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize + (_spacing * 0.5),
            child: _buildSubMenuButton(
              heroTag: 'cameraButton',
              child: const Icon(Icons.camera_alt, size: 22),
              onPressed: _recognizeImage,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 關閉
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize + (_spacing * 1.5),
            child: _buildSubMenuButton(
              heroTag: 'closeButton',
              child: const Icon(Icons.close, size: 22),
              onPressed: () {
                _toggleMenu();
                if (widget.onClose != null) widget.onClose!();
              },
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),
        },
      ],
    );
  }
}
