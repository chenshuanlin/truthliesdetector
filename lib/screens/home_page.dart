import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/profile_page.dart';

const _sage = Color(0xFF9EB79E); // 綠底色
const _sageDeep = Color(0xFF8EAA98);

class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final filters = [
    '科技', '政治', '健康', '教育', '娛樂', '體育', '設計', '旅遊', '生活', '商業',
    '金融', '環境', '國際', '藝術', '社會', '研究', '美食', '影視'
  ];
  final selected = <String>{'政治'};

  bool showMoreTrends = false; // 🔹 控制「熱門趨勢」展開
  bool showMoreAnalytics = false; // 🔹 控制「大數據分析」展開

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _sage,
        foregroundColor: Colors.white,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'lib/assets/logo.png',
              width: 45,
              height: 45,
            ),
          ),
        ],
      ),

      // 🔹 側邊欄 Drawer
      drawer: Drawer(
        child: Container(
          color: _sage,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 24, bottom: 16),
                  child: Image.asset(
                    'lib/assets/logo.png',
                    width: 120,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 50),
                  title: const Text('首頁', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 50),
                  title: const Text('最新消息', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 50),
                  title: const Text('新聞搜尋', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 50),
                  title: const Text('AI助手', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 50),
                  title: const Text('用戶資訊', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, ProfilePage.route);
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      // 🔹 主體內容
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('興趣標籤', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((f) {
              final isSel = selected.contains(f);
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSel) ...[
                      const Icon(
                        Icons.check,
                        size: 16, // ✅ 細版打勾
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(f),
                  ],
                ),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : _sage,
                  height: 1.2,
                ),
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                selected: isSel,
                showCheckmark: false, // ❌ 關閉預設粗勾
                selectedColor: _sage,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _sage),
                onSelected: (_) {
                  setState(() {
                    isSel ? selected.remove(f) : selected.add(f);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 🔹 熱門趨勢
          _SectionHeader(
            title: '熱門趨勢',
            onMore: () {
              setState(() {
                showMoreTrends = !showMoreTrends;
              });
            },
          ),
          Card(
            child: ListTile(
              title: const Text('健康資訊瀏覽量上升'),
              subtitle: const Text('近 24 小時內關於「保健食品」的搜尋與分享次數上升 300%。'),
              trailing: const Chip(label: Text('高風險')),
            ),
          ),
          if (showMoreTrends) ...[
            Card(
              child: ListTile(
                title: const Text('政治議題討論度飆升'),
                subtitle: const Text('選舉相關假新聞在社群平台廣傳。'),
                trailing: const Chip(label: Text('中風險')),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('環境議題快速擴散'),
                subtitle: const Text('近期「減碳政策」相關假訊息數量增加。'),
                trailing: const Chip(label: Text('高風險')),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // 🔹 大數據分析
          _SectionHeader(
            title: '大數據分析',
            onMore: () {
              setState(() {
                showMoreAnalytics = !showMoreAnalytics;
              });
            },
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _MiniCard(title: '輿情來源分析', subtitle: '各平台文章比例'),
              _MiniCard(title: '退稿率走勢', subtitle: '本週被澄清趨勢'),
            ],
          ),
          if (showMoreAnalytics) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _MiniCard(title: '輿情議題分析', subtitle: '主題分佈'),
                _MiniCard(title: '假訊息來源分析', subtitle: '來源型態'),
              ],
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onMore;
  const _SectionHeader({required this.title, required this.onMore});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(onPressed: onMore, child: const Text('更多')),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _MiniCard({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final w =
        (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2; // 兩欄
    return SizedBox(
      width: w,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
