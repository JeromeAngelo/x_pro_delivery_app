import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/src/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/widgets/sign_in_form.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/widgets/sign_in_logo.dart';

class AuthScreenView extends StatefulWidget {
  const AuthScreenView({super.key});

  static const routeName = '/sign-in';

  @override
  State<AuthScreenView> createState() => _AuthScreenViewState();
}

class _AuthScreenViewState extends State<AuthScreenView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  void _markUserAsNotFirstTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimer', false);
    debugPrint('✅ Marked user as no longer first timer after successful authentication');
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: BlocConsumer<AuthBloc, AuthState>(
      listener: (_, state) {
        if (state is AuthError) {
          CoreUtils.showSnackBar(context, state.message);
          debugPrint("State: $state");
        } else if (state is SignedIn) {
          debugPrint("State: $state");
          debugPrint("State.users: ${state.users}");
          debugPrint("State.users runtimeType: ${state.users.runtimeType}");

          context.read<UserProvider>().initUser(state.users as LocalUsersModel);
          
          // Mark user as no longer first timer after successful authentication
          _markUserAsNotFirstTimer();
          
          context.go('/loading');
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Center(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const SignInLogo(
                          size: 100,
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        SignInForm(
                            emailController: emailController,
                            passwordController: passwordController,
                            formKey: formKey),
                        const SizedBox(height: 30),
                        if (state is AuthLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 70),
                            child: RoundedButton(
                                icon: Icon(
                                  Icons.lock,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                label: 'Login',
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  if (formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                          SignInEvent(
                                              email:
                                                  emailController.text.trim(),
                                              password: passwordController.text
                                                  .trim()),
                                        );
                                  }
                                }),
                          ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text('https://delivery-app.winganmarketing.com',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ));
  }
}
