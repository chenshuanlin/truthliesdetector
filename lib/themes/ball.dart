import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/services.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';

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

  // ✔ API BASE 修正為 10.0.2.2（Android 模擬器 → Flask）
  final String apiBase = const String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const MethodChannel _channel = MethodChannel(
    'com.example.truthliesdetector/screenshot',
  );

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
  // 懸浮球開關
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
  // 截圖（原生）
  // --------------------------------------------------
  Future<Uint8List?> _captureSystemScreenshot() async {
    if (_isOpen) _toggleMenu();

    try {
      final String? base64Image = await _channel.invokeMethod('captureScreen');
      if (base64Image != null && base64Image.isNotEmpty) {
        return base64Decode(base64Image);
      }
      return null;
    } catch (e) {
      print("Failed to capture screen: $e");
      return null;
    }
  }

  // --------------------------------------------------
  // ✔ 修正：呼叫 Flask /analyze/summary
  // --------------------------------------------------
  Future<void> _sendToFlask(String query, {Uint8List? imageBytes}) async {
    try {
      final uri = Uri.parse('$apiBase/analyze/summary'); // 已修正路徑

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"text": query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        FlutterOverlayWindow.shareData(
          jsonEncode({
            'type': 'result',
            'credibility': data['credibility'],
            'summary': data['summary'],
          }),
        );
      } else {
        FlutterOverlayWindow.shareData(
          jsonEncode({
            'type': 'error',
            'message': '伺服器錯誤 ${response.statusCode}',
          }),
        );
      }
    } catch (e) {
      FlutterOverlayWindow.shareData(
        jsonEncode({'type': 'error', 'message': '無法連線後端：$e'}),
      );
    }
  }

  // --------------------------------------------------
  // 截圖或選圖片 → 查證
  // --------------------------------------------------
  Future<void> _recognizeImage() async {
    _toggleMenu();
    try {
      Uint8List? imageBytes;

      if (widget.screenshotController != null) {
        imageBytes = await widget.screenshotController!.capture();
      } else {
        imageBytes = await _captureSystemScreenshot();
      }

      if (imageBytes != null) {
        await _sendToFlask("請幫我辨識這張圖片。", imageBytes: imageBytes);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AIchat(
                initialQuery: "請幫我辨識這張圖片。",
                capturedImageBytes: imageBytes,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("圖片辨識錯誤：$e");
    }
  }

  // --------------------------------------------------
  // 手動輸入網址分析（呼叫 /analyze/summary）
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
            decoration: const InputDecoration(
              hintText: '請輸入網址（http 或 https 開頭）',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('查證'),
              onPressed: () async {
                final url = urlController.text.trim();

                if (url.isNotEmpty) {
                  Navigator.of(dialogContext).pop();

                  await _sendToFlask("請幫我分析這個網址：$url");

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AIchat(initialQuery: "請幫我分析這個網址：$url"),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // 回到主 App
  // --------------------------------------------------
  void _openApp() async {
    _toggleMenu();
    if (widget.onTap != null) {
      widget.onTap!(0);
    } else {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    }
  }

  // --------------------------------------------------
  // 在 App 外開啟懸浮球（靜態方法）
  // --------------------------------------------------
  static Future<void> showGlobalBall() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }

    await FlutterOverlayWindow.showOverlay(
      height: 120,
      width: 120,
      alignment: OverlayAlignment.centerRight,
      enableDrag: true,
      overlayTitle: "TruthLiesDetector",
      overlayContent: "AI懸浮球已啟動",
      flag: OverlayFlag.defaultFlag,
    );
  }

  // --------------------------------------------------
  // 子按鈕元件
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
  // UI Build
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double halfFabSize = _fabSize / 2;
    final double halfChildFabSize = _childFabSize / 2;

    return Stack(
      children: [
        // 背景遮罩（菜單打開時）
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(color: Colors.black.withOpacity(0.05)),
            ),
          ),

        // 子選單按鈕們
        if (_isOpen) ...{
          // 關閉按鈕
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize + (_spacing * 1.5),
            child: _buildSubMenuButton(
              heroTag: 'close_btn',
              child: const Icon(Icons.close, size: 22),
              onPressed: () {
                _toggleMenu();
                widget.onClose?.call();
              },
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 圖片辨識
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize + (_spacing * 0.5),
            child: _buildSubMenuButton(
              heroTag: 'camera_btn',
              child: const Icon(Icons.camera_alt, size: 22),
              onPressed: _recognizeImage,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 網址分析
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize - (_spacing * 0.5),
            child: _buildSubMenuButton(
              heroTag: 'url_btn',
              child: const Icon(Icons.search, size: 22),
              onPressed: _showUrlInputDialog,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),

          // 回到 app
          Positioned(
            left: _offset.dx - _spacing,
            top: _offset.dy + halfFabSize - halfChildFabSize - (_spacing * 1.5),
            child: _buildSubMenuButton(
              heroTag: 'home_btn',
              child: const Icon(Icons.home, size: 22),
              onPressed: _openApp,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryGreen,
            ),
          ),
        },

        // 主球本體
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
              heroTag: 'main_btn',
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
      ],
    );
  }
}
