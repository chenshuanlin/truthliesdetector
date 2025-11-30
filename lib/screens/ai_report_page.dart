import 'package:flutter/material.dart';
// 假設您的 AppColors 定義在這個路徑下，以解決重複定義問題。
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/services/api_service.dart';
import 'dart:math';

// 將後端 UTC ISO 時間字串 (e.g. 2025-10-13T11:02:04Z) 轉為本地時間並格式化顯示
String formatUtcIsoToLocal(String iso) {
  if (iso.isEmpty) return '';
  DateTime? dt;
  try {
    dt = DateTime.parse(iso);
  } catch (_) {
    // 如果 parse 失敗，直接回傳原字串
    return iso;
  }
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

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

/// 柱狀圖數據模型（堆疊式：已查證 + 待查證）
class BarData {
  final double verified; // 已查證數量（綠色）
  final double suspicious; // 待查證數量（紅色）
  final String label; // 星期幾或月份標籤

  BarData(this.verified, this.suspicious, this.label);

  // 總數
  double get total => verified + suspicious;
}

// MARK: - 主頁面

class AiReportPage extends StatefulWidget {
  static const route = '/ai_report';

  const AiReportPage({super.key});

  @override
  State<AiReportPage> createState() => _AiReportPageState();
}

class _AiReportPageState extends State<AiReportPage> {
  final ApiService _apiService = ApiService.getInstance();
  Map<String, dynamic>? _statsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _apiService.getFakeNewsStats();
      setState(() {
        // API 回傳格式是 {"ok": true, "stats": {...}}，只取 stats 部分
        _statsData = response?['stats'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 從 API 數據生成報告內容
  Map<int, Map<String, dynamic>> get _reportData {
    if (_statsData == null) {
      return _getDefaultReportData();
    }

    final stats = _statsData!;
    final weeklyReports = stats['weeklyReports'] as List<dynamic>? ?? [];
    final totalVerified = stats['totalVerified'] as int? ?? 32;
    final totalSuspicious = stats['totalSuspicious'] as int? ?? 125;
    // 直接從 totalVerified 和 totalSuspicious 計算 AI 辨識率
    final total = totalVerified + totalSuspicious;
    final aiAccuracy = total > 0 ? ((totalVerified / total * 100).round()) : 0;
    final topCategories = stats['topCategories'] as List<dynamic>? ?? [];
    final propagationChannels =
        stats['propagationChannels'] as List<dynamic>? ?? [];

    // 動態產生折線圖資料（以 verified+suspicious 為熱度）
    final List<double> lineChartData = weeklyReports.isNotEmpty
        ? weeklyReports
              .map(
                (r) =>
                    ((r['verified'] ?? 0) + (r['suspicious'] ?? 0)).toDouble(),
              )
              .toList(growable: false)
              .cast<double>()
        : [10.0, 15.0, 12.0, 20.0, 25.0, 22.0, 28.0];

    // 動態產生圓餅圖資料（以 topCategories）
    final List<ChartData> pieChartData = propagationChannels.isNotEmpty
        ? propagationChannels.map<ChartData>((c) {
            final name = c['channel']?.toString() ?? '';
            final percent = (c['percentage'] is num)
                ? (c['percentage'] as num).toDouble()
                : 0.0;
            final color = name.contains('社群')
                ? AppColors.dangerRed
                : (name.contains('私人')
                      ? AppColors.primaryGreen
                      : AppColors.userGray);
            return ChartData(name, percent, color);
          }).toList()
        : [
            ChartData('社群媒體', 45, AppColors.primaryGreen),
            ChartData('私人訊息群組', 30, AppColors.primaryGreen2),
            ChartData('傳統媒體', 25, AppColors.userGray),
          ];

    // 動態產生週報標題（自動帶入今天日期）
    final now = DateTime.now();
    final weekTitle =
        '假訊息監測完整報告 (週報) - ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    // 動態產生熱門趨勢分析
    String buildCategoryDesc(List<dynamic> cats) {
      if (cats.isEmpty) return '（本週無顯著主題）';
      return cats
          .map((cat) {
            final name = cat['name'] ?? '';
            final percent = cat['percentage'] ?? 0;
            return '・$name（$percent%）';
          })
          .join('\n');
    }

    // 動態產生情感分佈（如有）
    String buildSentimentDesc() {
      // 這裡可根據 stats['sentiment'] 等欄位自動組裝，暫時寫死
      return '* 中性: 65%\n* 負面: 25%\n* 正面: 10%';
    }

    return {
      0: {
        'title': weekTitle,
        'content':
            '本週共偵測到 **${totalVerified + totalSuspicious}** 條疑似假訊息，其中 **$totalVerified 條**經 AI 交叉比對後確認為假消息，AI 準確率達 **$aiAccuracy%**。\n\n**熱門趨勢分析:**\n${buildCategoryDesc(topCategories)}\n\n**建議:** 立即對高傳播風險的假訊息進行人工複核和澄清。',
        'chart_data': _buildWeeklyChartData(weeklyReports),
        'chart_type': 'bar',
      },
      1: {
        'title': '新聞趨勢與熱度完整分析',
        'content':
            '本週新聞總量相較上週增長 **15%**。熱度最高的關鍵詞如下：\n${buildCategoryDesc(topCategories)}\n\n**情感分佈:**\n${buildSentimentDesc()}\n\n**預測:** 預計下週主題將持續主導輿論，建議準備相關事實查核素材，以防衍生假消息。',
        'chart_data': lineChartData,
        'chart_type': 'line',
      },
      2: {
        'title': '假訊息傳播網路完整報告',
        'content':
            '傳播速度比上週加快 **25%**。\n\n**主要傳播途徑分佈:**\n${(propagationChannels.isNotEmpty ? propagationChannels : [
                    {'channel': '社群媒體', 'percentage': 45},
                    {'channel': '私人訊息群組', 'percentage': 30},
                    {'channel': '傳統媒體/網站', 'percentage': 25},
                  ]).map((c) => '* ${c['channel']} (${c['percentage']}%)').join('\n')}\n\n**高風險節點:** 「KOL_金融達人」和「匿名論壇」被識別為本週最主要的假訊息擴散源頭。',
        'chart_data': pieChartData,
        'chart_type': 'pie',
      },
    };
  }

  List<BarData> _buildWeeklyChartData(List<dynamic> weeklyReports) {
    if (weeklyReports.isEmpty) {
      return [
        BarData(0, 0, '一'),
        BarData(0, 0, '二'),
        BarData(0, 0, '三'),
        BarData(0, 0, '四'),
        BarData(0, 0, '五'),
        BarData(0, 0, '六'),
        BarData(0, 0, '日'),
      ];
    }

    return weeklyReports.map((report) {
      final verified = (report['verified'] is num)
          ? (report['verified'] as num).toDouble()
          : 0.0;

      final suspicious = (report['suspicious'] is num)
          ? (report['suspicious'] as num).toDouble()
          : 0.0;

      final day = report['day']?.toString() ?? '';

      return BarData(verified, suspicious, day);
    }).toList();
  }

  String _buildCategoriesText(List<dynamic> categories) {
    if (categories.isEmpty) {
      return '* 健康與疫苗 (38%): 主要散佈在私人訊息群組，內容涉及未經證實的療法。\n* 選舉與政治 (29%): 多數源於社群媒體，與特定候選人或政策相關。';
    }

    return categories
        .map((cat) {
          final name = cat['name'] as String? ?? '';
          final percentage = cat['percentage'] as int? ?? 0;
          return '* $name ($percentage%)';
        })
        .join('\n');
  }

  Map<int, Map<String, dynamic>> _getDefaultReportData() {
    return {
      0: {
        'title': '假訊息監測完整報告 (週報)',
        'content':
            '本週共偵測到 **157** 條疑似假訊息，其中 **32 條**經 AI 交叉比對後確認為假消息，相較上週增長 **18%**。主要增長點集中在政治和健康類別。\n\n**熱門趨勢分析:**\n* 健康與疫苗 (38%): 主要散佈在私人訊息群組，內容涉及未經證實的療法。\n* 選舉與政治 (29%): 多數源於社群媒體，與特定候選人或政策相關。\n* 經濟相關 (18%): 主要為投資誘餌和市場謠言。\n\n**建議:** 立即對高傳播風險的「健康類假訊息」進行人工複核和澄清。',
        'chart_data': [
          BarData(2, 3, '一'),
          BarData(3, 4, '二'),
          BarData(2, 2, '三'),
          BarData(3, 5, '四'),
          BarData(2, 3, '五'),
          BarData(2, 2, '六'),
          BarData(1, 2, '日'),
        ],
        'chart_type': 'bar',
      },
      1: {
        'title': '新聞趨勢與熱度完整分析',
        'content':
            '本週新聞總量相較上週增長 **15%**。熱度最高的關鍵詞是「能源政策」，熱度增長達 **45%**。\n\n**情感分佈:**\n* 中性: 65%\n* 負面: 25% (集中在國際貿易協定)\n* 正面: 10%\n\n**預測:** 預計下週「能源政策」將持續主導輿論，建議準備相關事實查核素材，以防衍生假消息。',
        'chart_data': [10.0, 15.0, 12.0, 20.0, 25.0, 22.0, 28.0],
        'chart_type': 'line',
      },
      2: {
        'title': '假訊息傳播網路完整報告',
        'content':
            '傳播速度比上週加快 **25%**。健康類假訊息 (來自 LINE 群組) 在 48 小時內達到峰值。\n\n**主要傳播途徑分佈:**\n* 社群媒體 (Facebook, X): 45%\n* 私人訊息群組 (LINE, Telegram): 30%\n* 傳統媒體/網站: 25%\n\n**高風險節點:** 「KOL_金融達人」和「匿名論壇」被識別為本週最主要的假訊息擴散源頭。',
        'chart_data': [
          ChartData('社群媒體', 45, AppColors.primaryGreen),
          ChartData('私人訊息群組', 30, AppColors.primaryGreen2),
          ChartData('傳統媒體', 25, AppColors.userGray),
        ],
        'chart_type': 'pie',
      },
    };
  }

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
        // ←←← 原本的 leading 被移除
        automaticallyImplyLeading: false, // 🔥 確保左上角不會自動出現返回鍵
      ),

      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    '正在載入最新數據...',
                    style: TextStyle(color: AppColors.darkText),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 新增：每日自動更新說明
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '資料每日自動更新，無需手動刷新',
                      style: TextStyle(color: Colors.brown, fontSize: 14),
                    ),
                  ),
                  _buildSegmentedControl(),
                  const SizedBox(height: 8),
                  if (_statsData != null) _buildMetaLine(),
                  const SizedBox(height: 12),
                  _buildCurrentContent(),
                ],
              ),
            ),
    );
  }

  // MARK: - Widget Builders

  // 頂部分段控制（Tab Bar） - 只保留假訊息偵測
  Widget _buildSegmentedControl() {
    // 移除新聞趨勢和傳播模式分頁，只保留假訊息偵測
    return const SizedBox.shrink(); // 只有一個分頁時不需要顯示切換按鈕
  }

  // 單個 Tab 項目
  Widget _buildTabItem(
    String title, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : AppColors.userGray.withOpacity(0.5),
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

  // 根據選中的 Tab 返回對應的內容 - 只保留假訊息偵測
  Widget _buildCurrentContent() {
    return _buildDetectionReportContent();
  }

  // 一行小型動態來源標籤，證明資料為即時抓取
  Widget _buildMetaLine() {
    final meta =
        _statsData?['meta'] ??
        _statsData?['Meta'] ??
        _statsData?['metadata'] ??
        (_statsData?['stats']?['meta']);
    String fetchedAt = '';
    if (meta is Map) {
      final fetched = meta['fetchedAt']?.toString() ?? '';
      fetchedAt = formatUtcIsoToLocal(fetched);
    }
    return Row(
      children: [
        Icon(Icons.public, size: 16, color: AppColors.userGray),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            fetchedAt.isNotEmpty ? '最新抓取時間 $fetchedAt' : '正在載入最新資料來源…',
            style: const TextStyle(fontSize: 12, color: AppColors.userGray),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // MARK: Tab 0: 假訊息偵測 (包含 Bar Chart & Topics List)
  Widget _buildDetectionReportContent() {
    final weeklyData = _reportData[0]?['chart_data'] ?? <BarData>[];
    final List<dynamic> topCategories =
        (_statsData?['topCategories'] as List<dynamic>? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 1. 柱狀圖
        _buildVisualCard(
          title: '本週假訊息監測報告',
          onViewAll: () => _showFullReportModal(),
          child: AiBarChart(data: weeklyData),
        ),
        const SizedBox(height: 15),

        /// 2. 三個統計卡片
        _buildMetricsCards(),
        const SizedBox(height: 15),

        /// 3. 熱門假訊息主題
        _buildVisualCard(
          title: '熱門假訊息主題',
          child: Column(
            children: topCategories.isNotEmpty
                ? topCategories.map<Widget>((cat) {
                    final name = cat['name']?.toString() ?? '';
                    final percent = cat['percentage']?.toString() ?? '';

                    final numVal = (cat['percentage'] is num)
                        ? (cat['percentage'] as num)
                        : 0;

                    final color = numVal >= 30
                        ? AppColors.dangerRed
                        : AppColors.primaryGreen;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                : const [
                    Text(
                      '（本週無顯著主題）',
                      style: TextStyle(color: AppColors.userGray),
                    ),
                  ],
          ),
        ),
      ],
    );
  }

  // 報告區塊標題
  Widget _buildReportSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
      ),
    );
  }

  // 關鍵指標卡片
  Widget _buildMetricsCards() {
    final stats = _statsData ?? {};
    final weekly = (stats['weeklyReports'] as List<dynamic>? ?? []);

    int sumVerified = 0;
    int sumSuspicious = 0;

    for (final r in weekly) {
      sumVerified += (r['verified'] as int? ?? 0);
      sumSuspicious += (r['suspicious'] as int? ?? 0);
    }

    // 近兩天資料（避免 weekly 空的崩潰）
    int lastV = 0, prevV = 0, lastS = 0, prevS = 0;
    if (weekly.isNotEmpty) {
      lastV = (weekly.last['verified'] as int? ?? 0);
      lastS = (weekly.last['suspicious'] as int? ?? 0);
    }
    if (weekly.length >= 2) {
      prevV = (weekly[weekly.length - 2]['verified'] as int? ?? 0);
      prevS = (weekly[weekly.length - 2]['suspicious'] as int? ?? 0);
    }

    int calcDelta(int now, int prev) {
      if (prev == 0) return 0;
      return (((now - prev) / prev) * 100).round();
    }

    final verifiedDelta = calcDelta(lastV, prevV);
    final suspiciousDelta = calcDelta(lastS, prevS);

    // AI 辨識率
    int aiAcc = 0;
    if (stats['aiAccuracy'] is num) {
      aiAcc = (stats['aiAccuracy'] as num).round();
    } else {
      final total = lastV + lastS;
      aiAcc = total > 0 ? ((lastV / total) * 100).round() : 0;
    }

    // AI trend
    final prevAcc = (prevV + prevS) > 0
        ? ((prevV * 100) / (prevV + prevS))
        : aiAcc.toDouble();

    final aiDelta = (aiAcc - prevAcc).round();

    String fmt(int d) => (d >= 0 ? '+$d% ▲' : '$d% ▼');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricCard(
          value: sumVerified.toString(),
          label: '已確認假訊息',
          trend: fmt(verifiedDelta),
          color: AppColors.dangerRed,
        ),
        const SizedBox(width: 10),
        _MetricCard(
          value: sumSuspicious.toString(),
          label: '待查證訊息',
          trend: fmt(suspiciousDelta),
          color: AppColors.userGray,
        ),
        const SizedBox(width: 10),
        _MetricCard(
          value: '$aiAcc%',
          label: 'AI 辨識率',
          trend: fmt(aiDelta),
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
          _buildReportSectionHeader(
            title: title,
            onViewAll: onViewAll ?? () {},
          ),
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
          initialTabIndex: 0, // 只保留假訊息偵測分頁
          reportData: null, // 改為由後端動態取得完整報告
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
              style: const TextStyle(fontSize: 12, color: AppColors.darkText),
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
          final double spacing =
              (renderBox.size.width - (widget.data.length * barWidth)) /
              (widget.data.length + 1);

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
    final double maxValue = data
        .map((d) => d.total)
        .reduce((a, b) => a > b ? a : b);
    final double spacing =
        (size.width - (data.length * barWidth)) / (data.length + 1);

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double verifiedHeight =
          (item.verified / maxValue) * (size.height - padding * 2);
      final double suspiciousHeight =
          (item.suspicious / maxValue) * (size.height - padding * 2);
      final double totalHeight = verifiedHeight + suspiciousHeight;

      // X 軸位置
      final double xCenter = spacing + i * (barWidth + spacing) + barWidth / 2;

      // 繪製待查證部分（紅色，在上方）
      if (suspiciousHeight > 0) {
        final suspiciousRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            xCenter - barWidth / 2,
            size.height - padding - totalHeight,
            barWidth,
            suspiciousHeight,
          ),
          topLeft: const Radius.circular(barRadius),
          topRight: const Radius.circular(barRadius),
        );
        final suspiciousPaint = Paint()..color = AppColors.dangerRed;
        canvas.drawRRect(suspiciousRect, suspiciousPaint);
      }

      // 繪製已查證部分（綠色，在下方）
      if (verifiedHeight > 0) {
        final verifiedRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            xCenter - barWidth / 2,
            size.height - padding - verifiedHeight,
            barWidth,
            verifiedHeight,
          ),
          bottomLeft: const Radius.circular(barRadius),
          bottomRight: const Radius.circular(barRadius),
        );
        final verifiedPaint = Paint()..color = AppColors.primaryGreen;
        canvas.drawRRect(verifiedRect, verifiedPaint);
      }

      // 繪製底部標籤
      final textPainterLabel = TextPainter(
        text: TextSpan(
          text: item.label,
          style: const TextStyle(color: AppColors.userGray, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainterLabel.layout();
      textPainterLabel.paint(
        canvas,
        Offset(xCenter - textPainterLabel.width / 2, size.height - padding + 5),
      );

      // 點擊後顯示數值
      if (i == tappedIndex) {
        final textPainterValue = TextPainter(
          text: TextSpan(
            text: '${item.total.round()}',
            style: const TextStyle(
              color: AppColors.darkText,
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
          Offset(
            xCenter - textPainterValue.width / 2,
            size.height - padding - totalHeight - textPainterValue.height - 5,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.tappedIndex != tappedIndex;
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
            child: CustomPaint(painter: _PieChartPainter(data)),
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkText,
                      ),
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
      child: CustomPaint(painter: _LineChartPainter(data, color)),
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
    canvas.drawLine(
      Offset(0, size.height - padding),
      Offset(size.width, size.height - padding),
      gridPaint,
    );
    canvas.drawLine(Offset(0, padding), Offset(size.width, padding), gridPaint);

    // 繪製數據線
    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      // 將 Y 軸縮放並反轉 (越高值越靠近頂部)
      final double y =
          size.height -
          padding -
          ((data[i] / maxValue) * (size.height - 2 * padding));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // 繪製數據點
      canvas.drawCircle(
        Offset(x, y),
        3.0,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
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
      textPainter.paint(
        canvas,
        Offset(i * stepX - textPainter.width / 2, size.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// 模擬完整報告 Modal (只保留假訊息偵測分頁)
class FullReportModal extends StatefulWidget {
  final int initialTabIndex;
  final Map<int, Map<String, dynamic>>? reportData; // 可為 null，為 null 則改為呼叫後端取得

  const FullReportModal({
    super.key,
    required this.initialTabIndex,
    this.reportData,
  });

  @override
  State<FullReportModal> createState() => _FullReportModalState();
}

class _FullReportModalState extends State<FullReportModal> {
  Map<int, Map<String, dynamic>>? _report; // 動態/本地都映射到相同結構
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initReport();
  }

  Future<void> _initReport() async {
    if (widget.reportData != null) {
      setState(() {
        _report = widget.reportData;
        _loading = false;
      });
      return;
    }

    // 從後端取得完整報告
    final api = ApiService.getInstance();
    final report = await api.getFullReport();
    if (report == null) {
      setState(() {
        _loading = false; // 顯示空白/錯誤狀態
      });
      return;
    }

    // 只取第一個分頁（假訊息偵測）
    List<dynamic> tabs = report['tabs'] as List<dynamic>? ?? [];
    Map<int, Map<String, dynamic>> mapped = {};

    if (tabs.isNotEmpty) {
      final t = tabs[0] as Map<String, dynamic>;
      final chartType = (t['chartType'] ?? '').toString();
      final meta = (t['meta'] as Map<String, dynamic>?) ?? const {};

      dynamic chartData;
      if (chartType == 'bar') {
        final weekly = (t['weeklyReports'] as List<dynamic>? ?? []);
        chartData = weekly.map((r) {
          final day = r['day']?.toString() ?? '';
          final verified = (r['verified'] is num)
              ? (r['verified'] as num).toDouble()
              : 0.0;
          final suspicious = (r['suspicious'] is num)
              ? (r['suspicious'] as num).toDouble()
              : 0.0;
          return BarData(verified, suspicious, day);
        }).toList();
      } else if (chartType == 'line') {
        final line = (t['line'] as List<dynamic>? ?? []);
        chartData = line.map((e) => (e is num) ? e.toDouble() : 0.0).toList();
      } else if (chartType == 'pie') {
        final channels = (t['channels'] as List<dynamic>? ?? []);
        chartData = channels.map<ChartData>((c) {
          final label = c['channel']?.toString() ?? '';
          final percent = (c['percentage'] is num)
              ? (c['percentage'] as num).toDouble()
              : 0.0;
          Color color;
          if (label.contains('社群')) {
            color = AppColors.dangerRed;
          } else if (label.contains('私人')) {
            color = AppColors.primaryGreen;
          } else {
            color = AppColors.userGray;
          }
          return ChartData(label, percent, color);
        }).toList();
      } else {
        chartData = const [];
      }

      mapped[0] = {
        'title': t['title']?.toString() ?? '',
        'content': t['content']?.toString() ?? '',
        'chart_type': chartType,
        'chart_data': chartData,
        'meta': meta,
      };
    }

    setState(() {
      _report = mapped;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          '完整報告',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _report != null && _report!.containsKey(0)
          ? _buildReportTabView(
              title: _report![0]!['title'],
              content: _report![0]!['content'],
              chartData: _report![0]!['chart_data'],
              chartType: _report![0]!['chart_type'],
              meta: (_report![0]!['meta'] as Map<String, dynamic>?),
            )
          : const Center(child: Text('無法載入報告')),
    );
  }

  Widget _buildReportTabView({
    required String title,
    required String content,
    required dynamic chartData,
    required String chartType,
    Map<String, dynamic>? meta,
  }) {
    // 根據 chartType 選擇對應的圖表 Widget
    Widget chartWidget;
    switch (chartType) {
      case 'bar':
        chartWidget = AiBarChart(data: chartData as List<BarData>);
        break;
      case 'line':
        chartWidget = AiLineChart(
          data: chartData as List<double>,
          color: AppColors.primaryGreen2,
        );
        break;
      case 'pie':
        chartWidget = AiPieChart(data: chartData as List<ChartData>);
        break;
      default:
        chartWidget = const SizedBox(
          height: 150,
          child: Center(child: Text('圖表類型錯誤')),
        );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (_) {
              String ts = '';
              if (meta != null && meta.isNotEmpty) {
                final fetched = meta['fetchedAt']?.toString() ?? '';
                ts = formatUtcIsoToLocal(fetched);
              }
              final label = ts.isNotEmpty ? ts : '載入中…';
              return Text(
                '--- 報告生成於 $label (API 數據) ---',
                style: const TextStyle(color: AppColors.userGray, fontSize: 12),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 20),

          // 1. 圖表區域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
              ],
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
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
                  fontWeight: i % 2 != 0
                      ? FontWeight.bold
                      : FontWeight.normal, // 奇數索引為粗體
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
                const Text(
                  '\u2022 ',
                  style: TextStyle(fontSize: 18, color: AppColors.primaryGreen),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: spans,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: AppColors.textColor,
                      ),
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
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.textColor,
                ),
              ),
            ),
          );
        }
      }).toList(),
    );
  }
}
