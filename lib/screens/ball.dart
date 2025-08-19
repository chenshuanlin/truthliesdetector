import 'package:flutter/material.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:screenshot/screenshot.dart';

// FloatingActionMenu 是一個可拖曳的懸浮動作菜單，帶有展開和折疊功能
class FloatingActionMenu extends StatefulWidget {
  final ScreenshotController? screenshotController;
  final Function(int)? onTap;
  final VoidCallback? onClose; // 關閉懸浮球的回呼函數

  const FloatingActionMenu({super.key, this.screenshotController, this.onTap, this.onClose});

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;
  Offset _offset = Offset(0, 0);
  final double _fabSize = 56.0; // 主懸浮動作按鈕的標準大小
  final double _childFabSize = 45.0; // 子按鈕尺寸變小，使其更緊湊
  final double _spacing = 50.0; // 子按鈕與主按鈕中心之間的距離縮小
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

    _animationController.addListener(() {
      if (_animationController.status == AnimationStatus.completed && _isOpen) {
        print('動畫已完成，菜單已完全展開。');
      } else if (_animationController.status == AnimationStatus.dismissed && !_isOpen) {
        print('動畫已重置，菜單已完全折疊。');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offset = Offset(
        MediaQuery.of(context).size.width - _fabSize - 16.0,
        MediaQuery.of(context).size.height - _fabSize - 16.0 - _bottomNavBarEstimatedHeight,
      );
      print('懸浮球初始位置: $_offset');
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    print('懸浮球被點擊！當前 _isOpen 狀態 (點擊前): $_isOpen');
    setState(() {
      _isOpen = !_isOpen;
      print('setState 後 _isOpen 狀態 (點擊後): $_isOpen');
      if (_isOpen) {
        _animationController.forward();
        print('調用 _animationController.forward()。');
      } else {
        _animationController.reverse();
        print('調用 _animationController.reverse()。');
      }
    });
  }

  Future<void> _recognizeImage() async {
    _toggleMenu();
    if (widget.screenshotController != null) {
      final imageBytes = await widget.screenshotController!.capture();
      if (imageBytes != null) {
        print('已截圖，準備傳輸數據...');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIcaht(
                initialQuery: '請幫我辨識這張截圖',
                capturedImageBytes: imageBytes),
          ),
        );
      } else {
        print('截圖失敗或為空');
        _showInfoDialog(context, '截圖失敗', '未能擷取到畫面，請重試。');
      }
    } else {
      print('未提供 ScreenshotController，無法進行截圖。將使用文件選擇模擬。');
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null) {
          String? filePath = result.files.single.name;
          print('選擇圖片進行辨識 (文件選擇): $filePath');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIcaht(initialQuery: '請幫我辨識這張圖片: $filePath'),
            ),
          );
        } else {
          print('使用者取消圖片選擇');
        }
      } catch (e) {
        print('圖片選擇錯誤: $e');
        _showInfoDialog(context, '文件選擇錯誤', '選擇圖片時發生錯誤：$e');
      }
    }
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('確定'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('搜尋'),
              onPressed: () {
                String url = urlController.text;
                print('開始搜尋網址: $url');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIcaht(initialQuery: '請幫我辨識這個網址的內容: $url'),
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

  void _startSearch() {
    _showUrlInputDialog();
  }

  void _startAIBotChat() {
    _toggleMenu();
    print('進入 AI 對話');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIcaht(initialQuery: '您好，有什麼可以為您服務的？'),
      ),
    );
  }

  Widget _buildChildButton(IconData icon, VoidCallback onPressed) {
    return ScaleTransition(
      scale: _animation,
      child: SizedBox(
        width: _childFabSize,
        height: _childFabSize,
        child: FloatingActionButton(
          heroTag: icon.codePoint.toString(),
          mini: false,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          onPressed: onPressed,
          child: Icon(icon, size: 28),
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return ScaleTransition(
      scale: _animation,
      child: SizedBox(
        width: _childFabSize,
        height: _childFabSize,
        child: FloatingActionButton(
          heroTag: 'chatFloatingButtonInMenu',
          mini: false,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          onPressed: _startAIBotChat,
          child: const Text('真假\n聊聊', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('build方法被調用，當前 _isOpen 狀態: $_isOpen');

    final double halfFabSize = _fabSize / 2;
    final double halfChildFabSize = _childFabSize / 2;
    final double halfSpacing = _spacing;

    return Stack(
      children: [
        // 主懸浮球和拖曳手勢
        Positioned(
          left: _offset.dx,
          top: _offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _offset = Offset(
                  (_offset.dx + details.delta.dx).clamp(
                      0.0, MediaQuery.of(context).size.width - _fabSize),
                  (_offset.dy + details.delta.dy).clamp(
                      0.0, MediaQuery.of(context).size.height - _fabSize - _bottomNavBarEstimatedHeight),
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
              child: Container(
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  'lib/assets/logo2.png',
                  width: 60,
                  height: 60,
                ),
              ),
            ),
          ),
        ),

        // 子按鈕佈局 - 僅當菜單展開時顯示
        if (_isOpen) ...{
          // 相機按鈕 (上方)
          Positioned(
            left: _offset.dx + halfFabSize - halfChildFabSize,
            top: _offset.dy - halfSpacing,
            child: _buildChildButton(Icons.camera_alt, _recognizeImage),
          ),

          // 搜尋按鈕 (左方)
          Positioned(
            left: _offset.dx - halfSpacing,
            top: _offset.dy + halfFabSize - halfChildFabSize,
            child: _buildChildButton(Icons.search, _startSearch),
          ),

          // 聊天按鈕 (右方)
          Positioned(
            left: _offset.dx + _fabSize + halfSpacing - halfChildFabSize,
            top: _offset.dy + halfFabSize - halfChildFabSize,
            child: _buildChatButton(),
          ),

          // 關閉按鈕 (下方)
          Positioned(
            left: _offset.dx + halfFabSize - halfChildFabSize,
            top: _offset.dy + _fabSize + halfSpacing - halfChildFabSize,
            child: _buildChildButton(Icons.close, () {
              if (widget.onClose != null) {
                widget.onClose!(); // 直接呼叫關閉功能
              }
            }),
          ),
        },
      ],
    );
  }
}