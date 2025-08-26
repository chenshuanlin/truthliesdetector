import 'package:flutter/material.dart';

const _sage = Color(0xFF9EB79E);
const _sageDeep = Color(0xFF8EAA98);

class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final filters = ['新聞', '社群', '影片', '關鍵名'];
  final selected = <String>{'新聞'};

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
              'lib/assets/logo.png', // 請改成你的 logo 路徑
              width: 45,
              height: 45,
            ),
          ),
        ],
      ),
      drawer: const Drawer(
        child: SafeArea(
          child: ListTile(
            leading: Icon(Icons.home_outlined),
            title: Text('首頁'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('探索', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: '搜尋假新聞議題、關鍵字…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF7F8F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onSubmitted: (_) {},
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = filters[i];
                final isSel = selected.contains(f);
                return ChoiceChip(
                  label: Text(f),
                  selected: isSel,
                  onSelected: (_) {
                    setState(() {
                      isSel ? selected.remove(f) : selected.add(f);
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: '熱門趨勢', onMore: () {}),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _sageDeep,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '健康資訊瀏覽量上升',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '近 24 小時內關於「保健食品」的搜尋與分享次數上升 300%。可能存在行銷話術集中傳播。',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Chip(label: Text('高風險')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: '大數據分析', onMore: () {}),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _MiniCard(title: '輿情來源分析', subtitle: '各平台文章比例'),
              _MiniCard(title: '退稿率走勢', subtitle: '本週被澄清趨勢'),
              _MiniCard(title: '輿情議題分析', subtitle: '主題分佈'),
              _MiniCard(title: '假訊息來源分析', subtitle: '來源型態'),
            ],
          ),
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
