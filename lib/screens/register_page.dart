import 'package:flutter/material.dart';

const _sage = Color(0xFF9EB79E);
const _sageDeep = Color(0xFF8EAA98);

class RegisterPage extends StatefulWidget {
  static const route = '/register';
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _username = TextEditingController();
  final _account = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _agree = false;
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
        child: Column(
          children: [
            const SizedBox(height: 24),
            // 上方 Logo
            Image.asset(
              'lib/assets/logo.png', // 你的 logo 路徑
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 註冊 + 底線
                    Column(
                      children: [
                        Text(
                          '註冊',
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
                        controller: _username,
                        decoration: _input.copyWith(labelText: '用戶名稱')),
                    const SizedBox(height: 12),
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _email,
                        decoration: _input.copyWith(labelText: '電子郵件')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _phone,
                        decoration: _input.copyWith(labelText: '電話號碼')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _agree,
                          onChanged: (v) =>
                              setState(() => _agree = v ?? false),
                          activeColor: _sageDeep,
                        ),
                        const Text('我同意條款'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 註冊按鈕（#748874）
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF748874),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _agree
                          ? () => Navigator.pushReplacementNamed(
                              context, '/home')
                          : null,
                      child: const Text('註冊'),
                    ),
                    const SizedBox(height: 8),
                    // 已有帳號（黑色文字）
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, '/login'),
                      child: const Text('已有帳號？前往登入'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
