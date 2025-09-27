import 'package:flutter/material.dart';
// 假設您的 AppColors 定義在這個路徑下，以解決重複定義問題。
import 'package:truthliesdetector/themes/app_colors.dart';
import 'dart:math';

// 顏色擴展方法 (用於計算顏色的深淺)
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

// MARK: - 數據模型

/// 通用圖表數據模型
class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}

/// 柱狀圖數據模型
class BarData {
  final double value;
  final bool isHighRisk; // 是否為高風險 (紅色)
  final String label; // 星期幾或月份標籤

  BarData(this.value, this.isHighRisk, this.label);
}

// MARK: - 主頁面

class AiReportPage extends StatefulWidget {
  static const route = '/ai_report';

  const AiReportPage({super.key});

  @override
  State<AiReportPage> createState() => _AiReportPageState();
}

class _AiReportPageState extends State<AiReportPage> {
  int _selectedTabIndex = 0;

  // 報告內容數據
  final Map<int, Map<String, dynamic>> _reportData = {
    0: {
      'title': '假訊息監測完整報告 (週報)',
      'content': '本週共偵測到 **157** 條疑似假訊息，其中 **32 條**經 AI 交叉比對後確認為假消息，相較上週增長 **18%**。主要增長點集中在政治和健康類別。\n\n**熱門趨勢分析:**\n* 健康與疫苗 (38%): 主要散佈在私人訊息群組，內容涉及未經證實的療法。\n* 選舉與政治 (29%): 多數源於社群媒體，與特定候選人或政策相關。\n* 經濟相關 (18%): 主要為投資誘餌和市場謠言。\n\n**建議:** 立即對高傳播風險的「健康類假訊息」進行人工複核和澄清。',
      'chart_data': [
        BarData(50, false, '一'), BarData(75, true, '二'), BarData(60, false, '三'),
        BarData(85, true, '四'), BarData(70, true, '五'), BarData(55, false, '六'),
        BarData(45, true, '日'),
      ],
      'chart_type': 'bar',
    },
    1: {
      'title': '新聞趨勢與熱度完整分析',
      'content': '本週新聞總量相較上週增長 **15%**。熱度最高的關鍵詞是「能源政策」，熱度增長達 **45%**。\n\n**情感分佈:**\n* 中性: 65%\n* 負面: 25% (集中在國際貿易協定)\n* 正面: 10%\n\n**預測:** 預計下週「能源政策」將持續主導輿論，建議準備相關事實查核素材，以防衍生假消息。',
      'chart_data': [10.0, 15.0, 12.0, 20.0, 25.0, 22.0, 28.0],
      'chart_type': 'line',
    },
    2: {
      'title': '假訊息傳播網路完整報告',
      'content': '傳播速度比上週加快 **25%**。健康類假訊息 (來自 LINE 群組) 在 48 小時內達到峰值。\n\n**主要傳播途徑分佈:**\n* 社群媒體 (Facebook, X): 45%\n* 私人訊息群組 (LINE, Telegram): 30%\n* 傳統媒體/網站: 25%\n\n**高風險節點:** 「KOL\_金融達人」和「匿名論壇」被識別為本週最主要的假訊息擴散源頭。',
      'chart_data': [
        ChartData('社群媒體', 45, AppColors.primaryGreen),
        ChartData('私人訊息群組', 30, AppColors.primaryGreen2),
        ChartData('傳統媒體', 25, AppColors.userGray),
      ],
      'chart_type': 'pie',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'AI報告與趨勢分析',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSegmentedControl(),
            const SizedBox(height: 20),
            _buildCurrentContent(),
          ],
        ),
      ),
    );
  }

  // MARK: - Widget Builders

  // 頂部分段控制（Tab Bar）
  Widget _buildSegmentedControl() {
    final List<String> titles = ['假訊息偵測', '新聞趨勢', '傳播模式'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: titles.asMap().entries.map((entry) {
        int index = entry.key;
        String title = entry.value;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _buildTabItem(
            title,
            isSelected: _selectedTabIndex == index,
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  // 單個 Tab 項目
  Widget _buildTabItem(String title, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.userGray.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // 根據選中的 Tab 返回對應的內容
  Widget _buildCurrentContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDetectionReportContent();
      case 1:
        return _buildTrendAnalysisContent();
      case 2:
        return _buildPropagationModelContent();
      default:
        return const Center(child: Text('報告加載中...'));
    }
  }

  // MARK: Tab 0: 假訊息偵測 (包含 Bar Chart & Topics List)
  Widget _buildDetectionReportContent() {
    // 模擬週報數據: Bar Chart
    final List<BarData> weeklyData = _reportData[0]?['chart_data'];

    // 模擬熱門主題數據: Topics List
    final List<ChartData> topicData = [
      ChartData('健康與疫苗相關假訊息', 38, AppColors.dangerRed),
      ChartData('選舉與政治相關假訊息', 29, AppColors.dangerRed.darken(0.1)),
      ChartData('經濟相關假訊息', 18, AppColors.primaryGreen),
      ChartData('國際關係', 10, AppColors.primaryGreen2),
      ChartData('社會事件', 5, AppColors.userGray),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 本週假訊息監測報告 (Bar Chart)
        _buildVisualCard(
          title: '本週假訊息監測報告',
          onViewAll: () => _showFullReportModal(),
          child: AiBarChart(data: weeklyData), // 使用可互動的 BarChart
        ),
        const SizedBox(height: 15),

        // 2. 關鍵指標卡片
        _buildMetricsCards(),
        const SizedBox(height: 15),

        // 3. 熱門假訊息主題 (List with vertical bars)
        _buildVisualCard(
          title: '熱門假訊息主題',
          child: Column(
            children: topicData.sublist(0, 3).map((d) => _TopicListItem(data: d)).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // MARK: Tab 1: 新聞趨勢分析
  Widget _buildTrendAnalysisContent() {
    final List<double> lineData = _reportData[1]?['chart_data'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 趨勢圖卡片
        _buildVisualCard(
          title: '新聞熱度趨勢圖 (日)',
          onViewAll: () => _showFullReportModal(),
          child: AiLineChart(data: lineData, color: AppColors.primaryGreen2),
        ),
        const SizedBox(height: 20),

        // 關鍵詞藥丸
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            '本週熱度最高關鍵詞：',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkText),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildPill('能源政策 (\u{1F525}+45%)', AppColors.dangerRed),
            _buildPill('晶片供應', AppColors.primaryGreen),
            _buildPill('國際貿易協定', AppColors.userGray),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // MARK: Tab 2: 傳播模式分析
  Widget _buildPropagationModelContent() {
    final List<ChartData> pieData = _reportData[2]?['chart_data'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 圓餅圖卡片
        _buildVisualCard(
          title: '傳播途徑分佈',
          onViewAll: () => _showFullReportModal(),
          child: AiPieChart(data: pieData),
        ),
        const SizedBox(height: 20),

        // 關鍵傳播節點
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            '關鍵傳播節點：',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkText),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildPill('KOL_金融達人 (高風險)', AppColors.dangerRed),
            _buildPill('匿名論壇 (高擴散)', AppColors.dangerRed.darken(0.1)),
            _buildPill('地方社群_A (中度)', AppColors.primaryGreen),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 報告區塊標題與「查看完整報告」按鈕
  Widget _buildReportSectionHeader({required String title, required VoidCallback onViewAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: const Row(
              children: [
                Text(
                  '查看完整報告',
                  style: TextStyle(
                    color: AppColors.userGray,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.userGray,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 關鍵指標卡片
  Widget _buildMetricsCards() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 已確認假訊息 (DangerRed)
        _MetricCard(
          value: '32',
          label: '已確認假訊息',
          trend: '+18% \u25B2',
          color: AppColors.dangerRed,
        ),
        SizedBox(width: 10),
        // 待查證訊息 (UserGray - 偏中性)
        _MetricCard(
          value: '125',
          label: '待查證訊息',
          trend: '+5% \u25B2',
          color: AppColors.userGray,
        ),
        SizedBox(width: 10),
        // AI 辨識率 (PrimaryGreen2)
        _MetricCard(
          value: '86%',
          label: 'AI 辨識率',
          trend: '+12% \u25B2',
          color: AppColors.primaryGreen2,
        ),
      ],
    );
  }

  // 輔助 Widget: 關鍵詞藥丸
  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.darken(0.3),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 視覺化卡片，包含標題、摘要和圖表/內容
  Widget _buildVisualCard({
    required String title,
    Widget? child,
    VoidCallback? onViewAll,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportSectionHeader(title: title, onViewAll: onViewAll ?? () {}),
          if (child != null) child,
        ],
      ),
    );
  }

  /// 顯示完整的模擬報告內容（全螢幕 Modal）
  void _showFullReportModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullReportModal(
          initialTabIndex: _selectedTabIndex,
          reportData: _reportData,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

// MARK: - 輔助元件 (Sub-Widgets)

// 提取為獨立的 Widget，用於關鍵指標卡片
class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final String trend;
  final Color color;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 0.5,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trend,
              style: TextStyle(
                fontSize: 12,
                color: color.darken(0.1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 熱門主題項目 (帶有彩色垂直線)
class _TopicListItem extends StatelessWidget {
  final ChartData data;

  const _TopicListItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 左側彩色垂直線
          Container(
            width: 4,
            height: 30, // 固定高度
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // 主題名稱
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(fontSize: 16, color: AppColors.darkText),
            ),
          ),
          // 百分比
          Text(
            '${data.value.round()}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: data.color.darken(0.1),
            ),
          ),
        ],
      ),
    );
  }
}


// MARK: - 圖表繪製器 (Custom Charts)

/// 柱狀圖 Widget (用於 Tab 0: 假訊息偵測週報)
class AiBarChart extends StatefulWidget {
  final List<BarData> data;

  const AiBarChart({required this.data, super.key});

  @override
  State<AiBarChart> createState() => _AiBarChartState();
}

class _AiBarChartState extends State<AiBarChart> {
  // 追蹤哪個柱體被點擊 (索引)
  int _tappedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: GestureDetector(
        onTapUp: (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);

          final double barWidth = 15.0;
          final double spacing = (renderBox.size.width - (widget.data.length * barWidth)) / (widget.data.length + 1);

          // 判斷點擊了哪個柱體
          int hitIndex = -1;
          for (int i = 0; i < widget.data.length; i++) {
            final double xStart = spacing + i * (barWidth + spacing);
            final double xEnd = xStart + barWidth;

            if (localPosition.dx >= xStart && localPosition.dx <= xEnd) {
              hitIndex = i;
              break;
            }
          }

          setState(() {
            // 如果點擊了相同的柱體，則隱藏數值
            _tappedIndex = (_tappedIndex == hitIndex) ? -1 : hitIndex;
          });
        },
        child: CustomPaint(
          painter: _BarChartPainter(widget.data, _tappedIndex),
        ),
      ),
    );
  }
}

/// 柱狀圖繪製器
class _BarChartPainter extends CustomPainter {
  final List<BarData> data;
  final int tappedIndex;

  _BarChartPainter(this.data, this.tappedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double barWidth = 15.0;
    const double barRadius = 4.0;
    const double padding = 10.0;
    final double maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final double spacing = (size.width - (data.length * barWidth)) / (data.length + 1);

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double barHeight = (item.value / maxValue) * (size.height - padding * 2);
      final Color barColor = item.isHighRisk ? AppColors.dangerRed : AppColors.primaryGreen;

      // X 軸位置
      final double xCenter = spacing + i * (barWidth + spacing) + barWidth / 2;
      final double yTop = size.height - padding - barHeight;

      // 繪製圓角矩形柱狀圖
      final rect = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(xCenter, size.height - padding - barHeight / 2),
          width: barWidth,
          height: barHeight,
        ),
        topLeft: const Radius.circular(barRadius),
        topRight: const Radius.circular(barRadius),
      );

      final paint = Paint()..color = barColor;
      canvas.drawRRect(rect, paint);

      // 繪製底部標籤
      final textPainterLabel = TextPainter(
        text: TextSpan(
          text: item.label,
          style: const TextStyle(color: AppColors.userGray, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainterLabel.layout();
      textPainterLabel.paint(canvas, Offset(xCenter - textPainterLabel.width / 2, size.height - padding + 5));

      // **舊的圖標繪製邏輯已移除**

      // 點擊後顯示數值
      if (i == tappedIndex) {
        final textPainterValue = TextPainter(
          text: TextSpan(
            text: item.value.round().toString(),
            style: TextStyle(
              color: barColor.darken(0.3),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainterValue.layout();
        // 數值顯示在柱體頂部上方
        textPainterValue.paint(
          canvas,
          Offset(xCenter - textPainterValue.width / 2, yTop - textPainterValue.height - 5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => oldDelegate.tappedIndex != tappedIndex;
}


// 圓餅圖/環狀圖 數據繪製器 (簡化版)
class _PieChartPainter extends CustomPainter {
  final List<ChartData> data;

  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.map((d) => d.value).reduce((a, b) => a + b);
    double startAngle = -pi / 2; // 從頂部開始
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var d in data) {
      final sweepAngle = (d.value / total) * 2 * pi;
      final paint = Paint()
        ..color = d.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true, // 使用 true 讓它成為圓餅圖
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// 圓餅圖 Widget (用於 Tab 2: 傳播模式)
class AiPieChart extends StatelessWidget {
  final List<ChartData> data;

  const AiPieChart({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _PieChartPainter(data),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((d) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: d.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${d.label}: ${d.value.round()}%',
                      style: const TextStyle(fontSize: 14, color: AppColors.darkText),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// 線圖 Widget (用於 Tab 1: 新聞趨勢)
class AiLineChart extends StatelessWidget {
  final List<double> data;
  final Color color;

  const AiLineChart({required this.data, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(data, color),
      ),
    );
  }
}

// 線圖繪製器
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (data.length - 1);
    final double maxValue = data.reduce((a, b) => a > b ? a : b);
    const double padding = 10.0;

    // 繪製背景網格線 (簡化)
    final gridPaint = Paint()
      ..color = AppColors.userGray.withOpacity(0.3)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, size.height - padding), Offset(size.width, size.height - padding), gridPaint);
    canvas.drawLine(Offset(0, padding), Offset(size.width, padding), gridPaint);

    // 繪製數據線
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      // 將 Y 軸縮放並反轉 (越高值越靠近頂部)
      final double y = size.height - padding - ((data[i] / maxValue) * (size.height - 2 * padding));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // 繪製數據點
      canvas.drawCircle(Offset(x, y), 3.0, Paint()..color = color..style = PaintingStyle.fill);
    }
    canvas.drawPath(path, paint);

    // 繪製 X 軸標籤 (模擬星期)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const List<String> labels = ['一', '二', '三', '四', '五', '六', '日'];
    for (int i = 0; i < data.length; i++) {
        textPainter.text = TextSpan(
          text: labels[i],
          style: const TextStyle(color: AppColors.userGray, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(i * stepX - textPainter.width / 2, size.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


/// 模擬完整報告 Modal (包含 3 個 Tab)
class FullReportModal extends StatefulWidget {
  final int initialTabIndex;
  final Map<int, Map<String, dynamic>> reportData;

  const FullReportModal({
    super.key,
    required this.initialTabIndex,
    required this.reportData,
  });

  @override
  State<FullReportModal> createState() => _FullReportModalState();
}

class _FullReportModalState extends State<FullReportModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tabTitles = ['假訊息偵測', '新聞趨勢', '傳播模式'];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('完整報告', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.userGray,
          indicatorColor: AppColors.primaryGreen,
          tabs: tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.reportData.entries.map((entry) {
          final data = entry.value;
          return _buildReportTabView(
            title: data['title'],
            content: data['content'],
            chartData: data['chart_data'],
            chartType: data['chart_type'],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportTabView({
    required String title,
    required String content,
    required dynamic chartData,
    required String chartType,
  }) {
    // 根據 chartType 選擇對應的圖表 Widget
    Widget chartWidget;
    switch (chartType) {
      case 'bar':
        chartWidget = AiBarChart(data: chartData as List<BarData>);
        break;
      case 'line':
        chartWidget = AiLineChart(data: chartData as List<double>, color: AppColors.primaryGreen2);
        break;
      case 'pie':
        chartWidget = AiPieChart(data: chartData as List<ChartData>);
        break;
      default:
        chartWidget = const SizedBox(height: 150, child: Center(child: Text('圖表類型錯誤')));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '--- 報告生成於 2025/09/27 (AI模擬數據) ---',
            style: TextStyle(color: AppColors.userGray, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 20),

          // 1. 圖表區域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
            ),
            child: chartWidget,
          ),
          const SizedBox(height: 20),

          // 2. 統整與文字敘述
          _buildReportContentText(content),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildReportContentText(String content) {
    // 解析 Markdown 樣式的報告內容
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content.split('\n').map((line) {
        if (line.startsWith('**')) {
          // 次級標題或重點
          return Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
            child: Text(
              line.replaceAll('**', ''), // 移除 **
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
          );
        } else if (line.startsWith('*')) {
          // 列表項目
          String text = line.substring(1).trim();
          // 將內容中的 **粗體** 轉換為 TextSpan
          final parts = text.split('**');
          List<TextSpan> spans = [];
          for (int i = 0; i < parts.length; i++) {
            spans.add(
              TextSpan(
                text: parts[i],
                style: TextStyle(
                  fontWeight: i % 2 != 0 ? FontWeight.bold : FontWeight.normal, // 奇數索引為粗體
                  color: AppColors.textColor,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(left: 10.0, top: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('\u2022 ', style: TextStyle(fontSize: 18, color: AppColors.primaryGreen)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: spans,
                      style: const TextStyle(fontSize: 16, height: 1.8, color: AppColors.textColor),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // 一般段落 (包含摘要)
          // 同樣處理粗體
          final parts = line.split('**');
          List<TextSpan> spans = [];
          for (int i = 0; i < parts.length; i++) {
            spans.add(
              TextSpan(
                text: parts[i],
                style: TextStyle(
                  fontWeight: i % 2 != 0 ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textColor,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: RichText(
              text: TextSpan(
                children: spans,
                style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textColor),
              ),
            ),
          );
        }
      }).toList(),
    );
  }
}
