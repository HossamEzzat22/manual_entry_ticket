import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_colors.dart';
import '../cubits/login/login_cubit.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/gaps.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final loginCubit = context.read<LoginCubit>();

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginLoading) {
          LoadingDialog.show(context, "Authenticating...");
        } else {
          LoadingDialog.hide(context);
        }

        if (state is LoginSuccess) {
          CustomSnackBar.showSuccess(
            context,
            "Welcome back, ${(state).userName}!",
          );
          Navigator.pushReplacementNamed(context, '/entry_ticket_screen');
        }

        if (state is LoginError) {
          CustomSnackBar.showError(context, state.message);
        }
      },
      child: AppScaffold(
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Image/Logo Section
                  Center(
                    child: Container(
                      height: 100.h,
                      width: 100.h,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        size: 50.sp,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ),
                  Gaps.h24,
                  Text(
                    "Sign In",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  Text(
                    "Access the manual cashier portal",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.subtitleText,
                    ),
                  ),
                  Gaps.h32,

                  // Email Custom Field
                  CustomTextField(
                    controller: loginCubit.emailController,
                    labelText: "Email",
                    hintText: "example@domain.com",
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Email is required";
                      }
                      final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
                      if (!emailRegex.hasMatch(val.trim())) {
                        return "Enter a valid email (e.g. example@domain.com)";
                      }
                      return null;
                    },
                  ),
                  Gaps.h16,

                  // Password Custom Field
                  CustomTextField(
                    controller: loginCubit.passwordController,
                    labelText: "Password",
                    hintText: "Enter password",
                    obscureText: !_isPasswordVisible,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Password is required";
                      }
                      return null;
                    },
                  ),
                  Gaps.h32,

                  // Custom Login Button
                  CustomButton(
                    label: "LOGIN",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        loginCubit.login();
                      }
                    },
                  ),
                  Gaps.h24,

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}