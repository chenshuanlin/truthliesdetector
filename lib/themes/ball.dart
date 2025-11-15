import 'package:flutter/material.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';

/// 可拖曳的懸浮球，支援展開子選單
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

  final double _fabSize = 56.0; // 主懸浮球大小
  final double _childFabSize = 45.0; // 子按鈕大小
  final double _spacing = 60.0; // 子按鈕間距
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

    // 初始化位置（右下角）
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

  /// 切換展開/收合
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

  /// 截圖/選擇圖片 → AI 分析
  Future<void> _recognizeImage() async {
    _toggleMenu();
    if (widget.screenshotController != null) {
      final Uint8List? imageBytes = await widget.screenshotController!
          .capture();
      if (imageBytes != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIchat(
              initialQuery: '請幫我辨識這張截圖',
              capturedImageBytes: imageBytes,
            ),
          ),
        );
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        String filePath = result.files.single.name;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIchat(initialQuery: '請幫我辨識這張圖片: $filePath'),
          ),
        );
      }
    }
  }

  /// 輸入網址 → AI 分析
  void _showUrlInputDialog() {
    _toggleMenu();
    TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('輸入網址進行搜尋'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: '請輸入網址'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('搜尋'),
              onPressed: () {
                String url = urlController.text;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AIchat(initialQuery: '請幫我辨識這個網址的內容: $url'),
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 開啟應用程式主頁面
  void _openApp() {
    _toggleMenu();
    // 修正導航邏輯，使用 onTap 回呼函式切換到主頁面
    if (widget.onTap != null) {
      widget.onTap!(0); // 0 是主頁面（HomePage）的索引
    }
  }

  /// 建立子按鈕
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

  @override
  Widget build(BuildContext context) {
    final double halfFabSize = _fabSize / 2;
    final double halfChildFabSize = _childFabSize / 2;
    final double halfSpacing = _spacing / 2;

    return Stack(
      children: [
        // 主懸浮球
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
              child: Image.asset('lib/assets/logo2.png', width: 50, height: 50),
            ),
          ),
        ),

        // 子選單 (垂直排列在左側)
        if (_isOpen) ...{
          // 開啟應用程式 (最上方)
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize - (_spacing * 1.5),
            child: _buildSubMenuButton(
              heroTag: 'openAppFloatingButton',
              child: const Icon(Icons.open_in_new, size: 22),
              onPressed: _openApp,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 輸入網址 (第二個)
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize - (_spacing * 0.5),
            child: _buildSubMenuButton(
              heroTag: 'searchFloatingButton',
              child: const Icon(Icons.search, size: 22),
              onPressed: _showUrlInputDialog,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 截圖 (第三個)
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize + (_spacing * 0.5),
            child: _buildSubMenuButton(
              heroTag: 'cameraFloatingButton',
              child: const Icon(Icons.camera_alt, size: 22),
              onPressed: _recognizeImage,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 關閉 (最下方)
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize + (_spacing * 1.5),
            child: _buildSubMenuButton(
              heroTag: 'closeFloatingButton',
              child: const Icon(Icons.close, size: 22),
              onPressed: () {
                _toggleMenu();
                // 修正：如果父層提供了 onClose 回呼函式，則呼叫它
                if (widget.onClose != null) {
                  widget.onClose!();
                }
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
