import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truthliesdetector/providers/user_provider.dart';
import 'package:truthliesdetector/services/mock_database_service.dart';
import 'package:truthliesdetector/models/user.dart';

class DatabaseTestPage extends StatefulWidget {
  const DatabaseTestPage({super.key});

  @override
  State<DatabaseTestPage> createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends State<DatabaseTestPage> {
  final TextEditingController _accountController = TextEditingController(text: 'test');
  final TextEditingController _passwordController = TextEditingController(text: 'hello');
  String _result = '';

  void _testLogin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.login(_accountController.text, _passwordController.text);
    setState(() {
      _result = success ? '登入成功！' : '登入失敗！';
    });
  }

  void _testRegister() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final result = await userProvider.register(
      User(
        account: 'newuser',
        username: '新用戶',
        password: 'password123',
        email: 'newuser@example.com',
        phone: '0987654321',
      ),
    );
    setState(() {
      _result = result == 'success' ? '註冊成功！' : '註冊失敗：$result';
    });
  }

  void _debugListUsers() {
    MockDatabaseService.instance.debugListUsers();
    setState(() {
      _result = '請查看控制台輸出';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('資料庫測試'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('測試帳號: test, 密碼: hello', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: '帳號',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密碼',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _testLogin,
              child: const Text('測試登入'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testRegister,
              child: const Text('測試註冊新用戶'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _debugListUsers,
              child: const Text('列出所有用戶'),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '結果: $_result',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}