import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/login_page.dart';

const _sage = Color(0xFF9EB79E);
const _sageDeep = Color(0xFF8EAA98);

class RegisterPage extends StatefulWidget {
  static const route = '/register';
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _account = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _agree = false;
  bool _obscure = true;

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

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (!_agree) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先同意條款')),
        );
        return;
      }

      // ✅ 註冊成功
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('註冊成功！請登入')),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, LoginPage.route);
      });
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
            Image.asset('lib/assets/logo.png', width: 80, height: 80),
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

                        // 用戶名稱
                        TextFormField(
                          controller: _username,
                          decoration: _input('用戶名稱'),
                          validator: (v) =>
                              v == null || v.isEmpty ? '請輸入用戶名稱' : null,
                        ),
                        const SizedBox(height: 12),

                        // 帳號
                        TextFormField(
                          controller: _account,
                          decoration: _input('帳號'),
                          validator: (v) =>
                              v == null || v.isEmpty ? '請輸入帳號' : null,
                        ),
                        const SizedBox(height: 12),

                        // 密碼
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: _input('密碼').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '請輸入密碼';
                            if (v.length < 6) return '密碼至少需要 6 碼';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 電子郵件
                        TextFormField(
                          controller: _email,
                          decoration: _input('電子郵件'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '請輸入電子郵件';
                            if (!v.contains('@')) return '請輸入有效的電子郵件';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // 電話號碼
                        TextFormField(
                          controller: _phone,
                          decoration: _input('電話號碼'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '請輸入電話號碼';
                            if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                              return '電話號碼只能是數字';
                            }
                            if (v.length < 10) return '電話號碼至少需要 10 碼';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // 條款同意
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

                        // 註冊按鈕
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF748874),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _register,
                          child: const Text('註冊'),
                        ),
                        const SizedBox(height: 8),

                        // 已有帳號 → 回登入
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, LoginPage.route);
                          },
                          child: const Text('已有帳號？前往登入'),
                        ),
                      ],
                    ),
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
