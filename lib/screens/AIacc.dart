import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http; // 導入 http 套件
import 'dart:convert'; // 導入 json 轉換
import 'package:truthliesdetector/themes/app_colors.dart'; // 導入自定義顏色
import 'package:truthliesdetector/screens/AIchat.dart'; // 導入 AIchat 介面

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedFileName; // 用於顯示選擇的檔案名稱
  List<Map<String, String>> _historyQueries = []; // 初始化為空列表，等待後端資料載入
  bool _isLoadingHistory = false; // 新增 loading 狀態

  @override
  void initState() {
    super.initState();
    _loadHistoryQueries(); // 模擬從後端載入資料
  }

  Future<void> _loadHistoryQueries() async {
    setState(() {
      _isLoadingHistory = true;
      _historyQueries = [];
    });

    try {
      final response = await http.get(Uri.parse('https://api.example.com/history'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _historyQueries = data.map((item) => Map<String, String>.from(item)).toList();
        });
        print('歷史查詢資料載入成功！');
      } else {
        print('從後端載入歷史查詢資料失敗，狀態碼: ${response.statusCode}');
      }
    } catch (e) {
      print('載入歷史查詢資料時發生錯誤: $e');
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
      if (_historyQueries.isEmpty) {
        // 如果載入失敗，並且沒有資料，使用模擬數據
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _historyQueries = [
            {
              'title': '台積電宣布在日本設立新廠',
              'time': '3小時前',
              'status': '已查證',
              'confidence': '高可信度',
            },
            {
              'title': '新冠疫苗含有微型晶片追蹤人體活動',
              'time': '6小時前',
              'status': '已查證',
              'confidence': '低可信度',
            },
          ];
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
        });
        print('選擇的檔案名稱: $_selectedFileName');
      } else {
        setState(() {
          _selectedFileName = null;
        });
      }
    } catch (e) {
      print('檔案選擇錯誤: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  // 修改此處，將箭頭放置在 AppBar 的 leading 位置
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0, left: 16.0),
                      child: InkWell(
                        onTap: () {
                          // 確保能正確返回上一頁
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            // 如果無法返回，可以導航到主頁面
                            // 例如: Navigator.pushReplacementNamed(context, '/');
                            print("無法返回，可能是根路由");
                          }
                        },
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          '真假小助手',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Image.asset(
                            'lib/assets/logo2.png',
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '請幫您查證資訊真假',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '輸入可疑訊息、網址或上傳圖片/影片',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: 5,
                      decoration: const InputDecoration.collapsed(
                        hintText: '  請輸入您要查證的訊息內容或網址... ',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
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
                      children: [
                        const Text('上傳圖片', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        if (_selectedFileName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              '已選擇檔案: $_selectedFileName',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('選擇文件'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        String queryMessage = _textController.text;
                        if (_selectedFileName != null) {
                          queryMessage = '請查證此訊息："$queryMessage" 和檔案: "$_selectedFileName"';
                        } else if (queryMessage.isEmpty) {
                          queryMessage = '請查證此訊息';
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AIcaht(
                              initialQuery: queryMessage,
                            ),
                          ),
                        );

                        _textController.clear();
                        setState(() {
                          _selectedFileName = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        '立即查證',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_isLoadingHistory)
                    const Center(child: CircularProgressIndicator())
                  else if (_historyQueries.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          '沒有歷史查詢資料',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '歷史查詢',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                print('查看所有歷史查詢');
                              },
                              child: const Text(
                                '查看全部',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _historyQueries.length,
                          itemBuilder: (context, index) {
                            final query = _historyQueries[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      query['title']!,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen,
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                query['status']!,
                                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              query['time']!,
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          query['confidence']!,
                                          style: TextStyle(
                                            color: query['confidence'] == '高可信度' ? Colors.green.shade700 : Colors.red.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}