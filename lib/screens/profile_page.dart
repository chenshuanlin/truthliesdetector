import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truthliesdetector/providers/user_provider.dart';
import 'package:truthliesdetector/screens/splash_page.dart';
import 'package:truthliesdetector/screens/history_page.dart';
import 'package:truthliesdetector/screens/collect_page.dart';
import 'package:truthliesdetector/screens/settings_page.dart';

const _sage = Color(0xFF9EB79E);
const _sageDeep = Color(0xFF8EAA98);

class ProfilePage extends StatefulWidget {
  static const route = '/profile';
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final tags = [
    '科技', '政治', '健康', '教育', '娛樂', '體育', '設計', '旅遊', '生活', '商業',
    '金融', '環境', '國際', '藝術', '社會', '研究', '美食', '影視'
  ];
  final selected = <String>{'科技', '健康', '社會'};

  // 🔹 編輯用的 controller
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _editProfile() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    if (user == null) return;

    _nameController.text = user.username;
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('編輯資料'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '電子郵件',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '電話號碼 (選填)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 顯示載入指示器
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final success = await userProvider.updateUserProfile(
                    _nameController.text,
                    _emailController.text,
                    _phoneController.text.isEmpty ? null : _phoneController.text,
                  );

                  // 關閉載入指示器
                  if (mounted) Navigator.pop(context);
                  // 關閉編輯對話框
                  if (mounted) Navigator.pop(context);

                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('資料更新成功！'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('更新失敗，請稍後再試'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // 關閉載入指示器
                  if (mounted) Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('更新失敗：$e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _sageDeep,
                foregroundColor: Colors.white,
              ),
              child: const Text('儲存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        
        // 如果沒有登入，顯示登入提示
        if (!userProvider.isLoggedIn || user == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('請先登入', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 頂部曲線背景
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    color: _sage,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Image.asset(
                          'lib/assets/logo.png',
                          width: 45,
                          height: 45,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _sageDeep,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.username,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(user.email,
                                style: const TextStyle(color: Colors.white70)),
                            if (user.phone != null && user.phone!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(user.phone!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _editProfile, // 🔹 打開編輯對話框
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        child: const Text('編輯資料'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 主體內容
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 帳號資訊卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('帳號資訊',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          _InfoRow(label: '帳號', value: user.account),
                          _InfoRow(label: '用戶名稱', value: user.username),
                          _InfoRow(label: '電子郵件', value: user.email),
                          if (user.phone != null && user.phone!.isNotEmpty)
                            _InfoRow(label: '電話', value: user.phone!),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // 興趣標籤
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('興趣標籤',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in tags)
                                ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (selected.contains(t)) ...[
                                        const Icon(
                                          Icons.check,
                                          size: 16, // 細版勾勾
                                          color: Colors.white, // ✅ 改成白色
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(t),
                                    ],
                                  ),
                                  labelStyle: TextStyle(
                                    color: selected.contains(t)
                                        ? Colors.white
                                        : _sage,
                                    height: 1.2,
                                  ),
                                  labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 2),
                                  selected: selected.contains(t),
                                  showCheckmark: false, // ❌ 關掉預設黑勾
                                  selectedColor: _sageDeep,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: _sage),
                                  onSelected: (_) {
                                    setState(() {
                                      if (selected.contains(t)) {
                                        selected.remove(t);
                                      } else {
                                        selected.add(t);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  _NavTile(
                    title: '收藏文章',
                    subtitle: '管理你收藏的新聞與文章',
                    onTap: () => Navigator.pushNamed(context, CollectPage.route),
                  ),
                  _NavTile(
                    title: '瀏覽歷史',
                    subtitle: '查看你的瀏覽記錄',
                    onTap: () => Navigator.pushNamed(context, HistoryPage.route),
                  ),
                  _NavTile(
                    title: '通知設定',
                    subtitle: '管理訂閱與提醒設定',
                    onTap: () => Navigator.pushNamed(context, SettingsPage.route),
                  ),

                  const SizedBox(height: 8),
                  // 登出按鈕（#D85E5E）
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD85E5E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      // 顯示確認對話框
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('確認登出'),
                          content: const Text('您確定要登出嗎？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD85E5E),
                              ),
                              child: const Text('登出'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await userProvider.logout();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, SplashPage.route);
                        }
                      }
                    },
                    child: const Text('登出'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
