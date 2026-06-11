import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:manual_entry_ticket/l10n/app_localizations.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../cubits/login/login_cubit.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/gaps.dart';
import '../widgets/logs_bottom_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isDialogShowing = false; // ← add this


  @override
  Widget build(BuildContext context) {
    final loginCubit = context.read<LoginCubit>();
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginLoading) {

          LoadingDialog.show(context, l10n.authenticating);
        } else if (state is LoginSuccess) {
          if (_isDialogShowing) {
            _isDialogShowing = false;
            LoadingDialog.hide(context);
          }

          CustomSnackBar.showSuccess(
            context,
            l10n.welcomeBack(state.userName),
          );
          Navigator.pushReplacementNamed(context, '/entry_ticket_screen');
        } else if (state is LoginError) {
          if (_isDialogShowing) {
            _isDialogShowing = false;
            LoadingDialog.hide(context);
          }

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
                  Center(
                    child: Container(
                      height: 130.h,
                      width: 130.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 3,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: SvgPicture.asset(
                            AppAssets.logo,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Gaps.h24,
                  Text(
                    l10n.signIn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  Text(
                    l10n.accessPortal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.subtitleText,
                    ),
                  ),
                  Gaps.h32,

                  // Email
                  CustomTextField(
                    controller: loginCubit.emailController,
                    labelText: l10n.email,
                    hintText: l10n.emailHint,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.emailRequired;
                      }
                      final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
                      if (!emailRegex.hasMatch(val.trim())) {
                        return l10n.emailInvalid;
                      }
                      return null;
                    },
                  ),
                  Gaps.h16,

                  // Password
                  CustomTextField(
                    controller: loginCubit.passwordController,
                    labelText: l10n.password,
                    hintText: l10n.passwordHint,
                    obscureText: !_isPasswordVisible,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
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
                        return l10n.passwordRequired;
                      }
                      return null;
                    },
                  ),
                  Gaps.h32,

                  // Login Button
                  BlocBuilder<LoginCubit, LoginState>(
                    builder: (context, state) {
                      return CustomButton(
                        label: l10n.loginButton,
                        isDisabled: state is LoginLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            loginCubit.login(l10n);
                          }
                        },
                      );
                    },
                  ),
                  Gaps.h12,
                  CustomButton(
                    label: l10n.shareLogs,
                    icon: Icons.share_outlined,
                    isPrimary: false,
                    onPressed: () => LogsBottomSheet.show(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}