import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/home_page.dart';
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
  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;

  InputDecoration get _input => InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF7F8F7),
        labelStyle: const TextStyle(color: Colors.black54),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DDD8))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DDD8))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _sageDeep, width: 1.2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sage,
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 24),
          // 顯示 Logo
          Image.asset(
            'lib/assets/logo.png', // 請改成你的 logo 路徑
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 登入 + 底線
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
                    TextField(
                        controller: _account,
                        decoration: _input.copyWith(labelText: '帳號')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: _input.copyWith(
                            labelText: '密碼',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ))),
                    const SizedBox(height: 8),
                    Row(children: [
                      Checkbox(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                          activeColor: _sageDeep),
                      const Text('記住我'),
                    ]),
                    const SizedBox(height: 6),
                    // 登入按鈕（#748874）
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF748874),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        // 按登入 → 跳轉 HomePage
                        Navigator.pushReplacementNamed(
                            context, HomePage.route);
                      },
                      child: const Text('登入'),
                    ),
                    const SizedBox(height: 8),
                    // 我要註冊按鈕（黑色文字）
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        // 按「我要註冊」 → 跳轉 RegisterPage
                        Navigator.pushReplacementNamed(
                            context, RegisterPage.route);
                      },
                      child: const Text('我要註冊'),
                    ),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}
