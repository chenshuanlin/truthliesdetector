import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/services.dart'; // 导入 Platform Services
// 假设这些文件路径是正确的
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

  // 定义 MethodChannel 用于和 Android Native 代码通信
  // NOTE: 已根據編譯錯誤日誌將通道名稱修正為 com.example.truthliesdetector
  static const MethodChannel _channel =
      MethodChannel('com.example.truthliesdetector/screenshot');

  final double _fabSize = 56.0;
  final double _childFabSize = 45.0;
  final double _spacing = 60.0;
  final double _bottomNavBarEstimatedHeight = 80.0;

  // Flask API base
  final String apiBase =
      const String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:5000');

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
      // 初始化悬浮球位置 (右下角)
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
  // 新增：透過 MethodChannel 呼叫 Android 原生截圖功能
  // --------------------------------------------------
  Future<Uint8List?> _captureSystemScreenshot() async {
    // 关闭菜单，避免遮挡
    if (_isOpen) _toggleMenu(); 

    // 显示等待提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ 正在請求系統截圖權限...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      // 呼叫原生端的 'captureScreen' 方法
      final String? base64Image = await _channel.invokeMethod('captureScreen');
      if (base64Image != null && base64Image.isNotEmpty) {
        // 将 Base64 字符串解码为 Uint8List
        return base64Decode(base64Image);
      }
      return null;
    } on PlatformException catch (e) {
      // 處理原生方法呼叫失敗 (例如：用戶拒絕 MediaProjection 权限)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ 截圖失敗：請確認已授權屏幕錄製。${e.message}'),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      print("Failed to capture screen: ${e.message}");
      return null;
    }
  }


  // --------------------------------------------------
  // 呼叫 Flask /analyze
  // --------------------------------------------------
  Future<void> _sendToFlask(String query, {Uint8List? imageBytes}) async {
    try {
      final uri = Uri.parse('$apiBase/analyze');
      final request = http.MultipartRequest('POST', uri);
      request.fields['text'] = query;

      if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'upload.jpg',
        ));
      }

      // 顯示分析中提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧠 正在進行分析中...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = jsonDecode(resBody);
        final credibility = result['credibility'] ?? '未知';
        final summary = result['summary'] ?? '無摘要';

        // 傳回給 AIchat
        FlutterOverlayWindow.shareData(jsonEncode({
          'type': 'result',
          'credibility': credibility,
          'summary': summary,
        }));

        // 顯示提示
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 分析完成：可信度 $credibility'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        FlutterOverlayWindow.shareData(jsonEncode({
          'type': 'error',
          'message': '伺服器回應錯誤 (${response.statusCode})'
        }));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 分析失敗：伺服器錯誤 (${response.statusCode})'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      FlutterOverlayWindow.shareData(jsonEncode({
        'type': 'error',
        'message': '分析失敗：$e',
      }));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ 無法連線到後端：$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --------------------------------------------------
  // 截圖或選圖片 → 分析 or 開啟 AIchat
  // --------------------------------------------------
  Future<void> _recognizeImage() async {
    _toggleMenu();
    try {
      Uint8List? imageBytes;

      // 1. 如果有 screenshotController，优先截取 App 界面 (用于 App 内使用)
      if (widget.screenshotController != null) {
        imageBytes = await widget.screenshotController!.capture();
      } else {
        // 2. 如果是 Overlay 状态，尝试调用 Native 截取整个屏幕
        imageBytes = await _captureSystemScreenshot(); 
        
        // 3. 如果原生截圖失败或返回 null，则退回到文件选择
        if (imageBytes == null) {
          final pick = await FilePicker.platform.pickFiles(type: FileType.image);
          if (pick != null && pick.files.isNotEmpty) {
            imageBytes = pick.files.single.bytes;
          }
        }
      }

      if (imageBytes != null) {
        // 先发送给 Flask 进行分析
        await _sendToFlask('請幫我辨識這張圖片。', imageBytes: imageBytes);

        // 然后导航到 AIchat 页面，将图片带过去
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AIchat(
                initialQuery: '請幫我辨識這張圖片。',
                capturedImageBytes: imageBytes,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未選擇圖片或未授權截圖')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('圖片辨識失敗：$e')),
        );
      }
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
                  // 关闭对话框
                  Navigator.of(dialogContext).pop(); 
                  
                  // 发送请求给 Flask
                  await _sendToFlask('請幫我分析這個網址的內容：$url');

                  // 导航到 AIchat 页面
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AIchat(
                          initialQuery: '請幫我分析這個網址的內容：$url',
                        ),
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
  // 開啟主應用頁面
  // --------------------------------------------------
  void _openApp() async {
    _toggleMenu();
    if (widget.onTap != null) {
      widget.onTap!(0);
    } else {
      // 如果没有 onTap 属性 (在 Overlay 模式下)，则关闭悬浮窗并返回 App
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    }
  }

  // --------------------------------------------------
  // 在 App 外開啟懸浮球 (静态方法)
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
  // 畫面 (Build)
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double halfFabSize = _fabSize / 2;
    final double halfChildFabSize = _childFabSize / 2;

    return Stack(
      children: [
        // 展开子菜单时的背景遮罩（可选，用于防止误触）
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu, // 点击空白处关闭菜单
              child: Container(
                color: Colors.black.withOpacity(0.05), // 轻微半透明
              ),
            ),
          ),
          
        // 展開子選單按鈕
        if (_isOpen) ...{
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
        },

        // 主懸浮球（可拖曳，在所有子元素之上）
        Positioned(
          left: _offset.dx,
          top: _offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                // 限制拖曳范围，确保不超出屏幕边界
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
      ],
    );
  }
}