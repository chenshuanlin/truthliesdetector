import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  static const route = '/settings';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 訂閱管理
  bool newsSubscription = false;
  bool expertAnalysisSubscription = false;
  bool reportSubscription = false;

  // 通知設定
  bool forecastNotification = false;
  bool hotTopicNotification = false;
  bool expertReplyNotification = false;

  // 紀錄是否已同意隱私政策
  bool hasAgreedPrivacyPolicy = false;

  bool isLoading = true;
  int? userId;

  // 顯示小視窗方法（新增勾選框功能）
  void _showInfoDialog(BuildContext context, String title, String content,
      {bool requireAgreement = false}) {
    bool agreed = hasAgreedPrivacyPolicy;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(content),
                if (requireAgreement) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: agreed,
                        onChanged: (val) {
                          setState(() {
                            agreed = val ?? false;
                            if (agreed) {
                              hasAgreedPrivacyPolicy = true;
                              // 同步到後端
                              _updateSettings();
                              Navigator.pop(context); // 勾選後自動關閉
                            }
                          });
                        },
                        activeColor: const Color(0xFF8BA88E), // 勾勾顏色
                        checkColor: Colors.white, // 勾號顏色
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Text("我已閱讀並同意")),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              if (!requireAgreement)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("關閉"),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('user_id');
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final api = ApiService.getInstance();
      final data = await api.getUserSettings(userId!);
      if (data != null) {
        setState(() {
          newsSubscription = data['news_category_subscription'] ?? false;
          expertAnalysisSubscription = data['expert_analysis_subscription'] ?? false;
          reportSubscription = data['weekly_report_subscription'] ?? false;
          forecastNotification = data['fake_news_alert'] ?? false;
          hotTopicNotification = data['trending_topic_alert'] ?? false;
          expertReplyNotification = data['expert_response_alert'] ?? false;
          hasAgreedPrivacyPolicy = data['privacy_policy_agreed'] ?? false;
        });
      }
    } catch (e) {
      print('載入使用者設定失敗: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    if (userId == null) return;
    final api = ApiService.getInstance();
    final body = {
      'news_category_subscription': newsSubscription,
      'expert_analysis_subscription': expertAnalysisSubscription,
      'weekly_report_subscription': reportSubscription,
      'fake_news_alert': forecastNotification,
      'trending_topic_alert': hotTopicNotification,
      'expert_response_alert': expertReplyNotification,
      'privacy_policy_agreed': hasAgreedPrivacyPolicy,
    };
    try {
      final ok = await api.updateUserSettings(userId!, body);
      if (!ok) {
        print('更新設定失敗');
      }
    } catch (e) {
      print('更新設定時發生錯誤: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("設定與通知"),
        backgroundColor: const Color(0xFF9EB79E), // 淡綠色
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context); // 返回上一頁
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 訂閱管理
          const Text(
            "訂閱管理",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("新聞類別訂閱"),
                  value: newsSubscription,
                  onChanged: (val) {
                    setState(() => newsSubscription = val);
                    _updateSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text("專家分析訂閱"),
                  value: expertAnalysisSubscription,
                  onChanged: (val) {
                    setState(() => expertAnalysisSubscription = val);
                    _updateSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text("週報訂閱"),
                  value: reportSubscription,
                  onChanged: (val) {
                    setState(() => reportSubscription = val);
                    _updateSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 通知設定
          const Text(
            "通知設定",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("假訊息預警通知"),
                  value: forecastNotification,
                  onChanged: (val) {
                    setState(() => forecastNotification = val);
                    _updateSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text("熱門話題通知"),
                  value: hotTopicNotification,
                  onChanged: (val) {
                    setState(() => hotTopicNotification = val);
                    _updateSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text("專家回應通知"),
                  value: expertReplyNotification,
                  onChanged: (val) {
                    setState(() => expertReplyNotification = val);
                    _updateSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 隱私與安全設定
          const Text(
            "隱私與安全設定",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text("資料分享設定"),
                  subtitle: const Text("控制您的瀏覽資料如何被使用"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showInfoDialog(
                      context,
                      "資料分享設定",
                      "為了提供更準確的新聞分析與個人化服務，本應用程式可能會收集您的使用紀錄、偏好設定及匿名裝置資訊。這些資料僅用於統計與功能優化，不會包含能識別您身份的資訊，也不會未經同意提供給第三方。",
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text("帳號安全"),
                  subtitle: const Text("管理密碼與雙重驗證"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showInfoDialog(
                      context,
                      "帳號安全",
                      "為保障您的帳號安全，我們建議您定期更換密碼並啟用雙重驗證。本應用程式將依照您選擇的安全機制進行保護，但您仍需妥善保管登入資訊，避免外洩或在不安全環境下登入。啟用相關功能，即表示您理解並同意遵循上述安全建議。",
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text("隱私政策"),
                  subtitle: const Text("閱讀我們的隱私政策"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showInfoDialog(
                      context,
                      "隱私政策",
                      "本應用程式重視您的隱私，為提供新聞查核及個人化服務，我們可能會蒐集與使用您的使用紀錄、偏好設定及匿名化資訊，並僅於必要範圍內進行分析與改善服務。我們不會出售、交換或未經授權將您的個人資料提供給第三方，請您在使用前仔細閱讀本隱私政策並確認同意。",
                      requireAgreement: true, // 勾選框
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
