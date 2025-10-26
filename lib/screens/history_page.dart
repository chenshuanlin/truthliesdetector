import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import 'chat_detail_page.dart';
import '../route_observer.dart';

class HistoryPage extends StatefulWidget {
  static const String route = '/history';
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with RouteAware {
  bool _loading = false;
  List<Map<String, dynamic>> _records = [];

  String get apiBase => kIsWeb ? 'http://127.0.0.1:5000' : 'http://10.0.2.2:5000';

  @override
  void initState() {
    super.initState();
    debugPrint('HistoryPage.initState: apiBase=$apiBase');
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // subscribe to route observer so we can refresh when returning to this page
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId ?? 0;
      debugPrint('HistoryPage._loadHistory: userId=$userId');
      if (userId == 0) {
        // not logged in, show empty
        setState(() => _records = []);
        return;
      }
      final url = '$apiBase/chat/history?user_id=$userId&limit=50';
      debugPrint('HistoryPage requesting: $url');
      final resp = await http.get(Uri.parse(url));
      debugPrint('HistoryPage response status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final records = List<Map<String, dynamic>>.from(data['records'] ?? []);
        debugPrint('HistoryPage received ${records.length} records');
        setState(() {
          _records = records;
        });
      } else {
        debugPrint('HistoryPage non-200 response: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Load history failed: $e');
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    try {
      routeObserver.unsubscribe(this);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this route (e.g. user pressed back from chat)
    debugPrint('HistoryPage.didPopNext - refreshing history');
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9EB79E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '瀏覽歷史',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('目前沒有瀏覽紀錄'))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _records[index];
                      final query = (item['query'] ?? '').toString();
                      final createdAt = item['created_at'] ?? '';
                      final gemini = item['gemini_result'] ?? {};
                      final short = query.length > 80 ? '${query.substring(0, 80)}...' : query;

                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        title: Text(short, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(createdAt, style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailPage(
                                query: query,
                                geminiResult: Map<String, dynamic>.from(gemini),
                                createdAt: createdAt,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
