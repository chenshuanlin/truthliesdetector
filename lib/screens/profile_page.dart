import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                        width: 36,
                        height: 36,
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
                    const CircleAvatar(
                        radius: 28, backgroundColor: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('中小原',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('cycuim@gmail.com',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
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
                                label: Text(t),
                                selected: selected.contains(t),
                                selectedColor: _sageDeep,
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

                const _NavTile(title: '收藏文章', subtitle: '管理你收藏的新聞與文章'),
                const _NavTile(title: '瀏覽歷史', subtitle: '查看你的瀏覽記錄'),
                const _NavTile(title: '通知設定', subtitle: '管理訂閱與提醒設定'),

                const SizedBox(height: 8),
                // 登出按鈕（#D85E5E）
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD85E5E), // 新顏色
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {},
                  child: const Text('登出'),
                ),
              ],
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
  const _NavTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
