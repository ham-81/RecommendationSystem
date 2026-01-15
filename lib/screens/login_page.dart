import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:reel_recommandation/routes/routes.dart';
import 'package:reel_recommandation/utils/colors.dart';
import 'package:reel_recommandation/utils/validator_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 100),
                        Image.asset('assets/insta_logo.png'),
                        SizedBox(height: 60),
                        CustomTextField(
                          hint: 'Email',
                          controller: emailController,
                          type: TextInputType.emailAddress,
                          isPass: false,
                          validatorCallback: ValidationBuilder()
                              .required()
                              .email()
                              .build(),
                        ),
                        SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Password',
                          controller: passwordController,
                          type: TextInputType.visiblePassword,
                          isPass: true,
                          validatorCallback: ValidationBuilder()
                              .required()
                              .minLength(6)
                              .maxLength(50)
                              .build(),
                        ),
                        SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, AppRoutes.home);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: followButton,
                              foregroundColor: followButtonTextLight,
                            ),
                            child: Text('Log In'),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: darkTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.signup),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: followButton,
                        side: BorderSide(color: followButton),
                      ),
                      child: Text('Create new account'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
