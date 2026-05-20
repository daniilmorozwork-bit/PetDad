import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Екран реєстрації.
/// Кнопка реєстрації доступна завжди, але при неправильному вводі
/// форма показує помилки під конкретними полями.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  /// До першої спроби реєстрації помилки не показуємо.
  /// Після першої спроби вмикаємо автоперевірку полів.
  bool _showValidationErrors = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Базова перевірка email.
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    return emailRegex.hasMatch(email.trim());
  }

  /// Запуск реєстрації.
  /// Якщо форма невалідна, поля підсвічуються червоним,
  /// а запит на backend не відправляється.
  Future<void> _register() async {
    setState(() {
      _showValidationErrors = true;
    });

    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Перевірте правильність заповнення полів'),
          ),
        );

      return;
    }

    await context.read<AuthCubit>().register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) {
        return current is AuthAuthenticated || current is AuthFailure;
      },
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        }

        if (state is AuthFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Реєстрація'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,

                /// До першого натискання кнопки помилки не показуються.
                /// Після першого натискання помилки оновлюються автоматично
                /// під час введення.
                autovalidateMode: _showValidationErrors
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Створення акаунта',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Заповніть основні дані для реєстрації в застосунку.',
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Імʼя',
                        hintText: 'Наприклад: Олексій Мороз',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'Імʼя є обовʼязковим';
                        }

                        if (text.length < 2) {
                          return 'Імʼя має містити мінімум 2 символи';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'name@example.com',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Email є обовʼязковим';
                        }

                        if (!_isValidEmail(email)) {
                          return 'Введіть коректний email';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        hintText: '+380501112233',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        hintText: 'Мінімум 8 символів',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final password = value ?? '';

                        if (password.isEmpty) {
                          return 'Пароль є обовʼязковим';
                        }

                        if (password.length < 8) {
                          return 'Пароль має містити мінімум 8 символів';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зареєструватися'),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.go('/login');
                            },
                      child: const Text('У мене вже є акаунт'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}