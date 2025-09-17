import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 我們需要引用 main.dart 來取得 MainLayout 的路由
import 'package:truthliesdetector/main.dart';
import 'package:truthliesdetector/screens/register_page.dart';

const _sage = Color(0xFF9EB79E);
const _sageDeep = Color(0xFF8EAA98);

class LoginPage extends StatefulWidget {
  static const route = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;
  bool _loading = false;

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF7F8F7),
    labelStyle: const TextStyle(color: Colors.black54),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD5DDD8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD5DDD8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _sageDeep, width: 1.2),
    ),
  );

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/login"), // ✅ 呼叫後端登入 API
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "account": _account.text.trim(),
          "password": _password.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // ✅ 登入成功 → 進入 MainLayout
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("登入成功，歡迎 ${data['username']}")),
        );

        Navigator.pushReplacementNamed(context, MainLayout.route);
      } else {
        // ❌ 登入失敗 → 提示錯誤
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("帳號或密碼錯誤，請先註冊")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("登入失敗: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sage,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo
            Image.asset(
              'lib/assets/logo.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 登入標題 + 底線
                      Column(
                        children: [
                          Text(
                            '登入',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 2,
                            color: _sageDeep,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 帳號輸入
                      TextFormField(
                        controller: _account,
                        decoration: _input('帳號'),
                        validator: (v) =>
                        v == null || v.isEmpty ? '請輸入帳號' : null,
                      ),
                      const SizedBox(height: 12),

                      // 密碼輸入
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: _input('密碼').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? '請輸入密碼' : null,
                      ),
                      const SizedBox(height: 8),

                      // 記住我
                      Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            onChanged: (v) =>
                                setState(() => _remember = v ?? false),
                            activeColor: _sageDeep,
                          ),
                          const Text('記住我'),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 登入按鈕
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF748874),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text('登入'),
                      ),
                      const SizedBox(height: 8),

                      // 我要註冊按鈕
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, RegisterPage.route);
                        },
                        child: const Text('我要註冊'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
