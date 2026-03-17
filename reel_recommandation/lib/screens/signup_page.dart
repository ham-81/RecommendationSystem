import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:reel_recommandation/utils/colors.dart';
import 'package:reel_recommandation/utils/validator_textfield.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                          hint: 'Username',
                          controller: usernameController,
                          type: TextInputType.text,
                          isPass: false,
                          validatorCallback: ValidationBuilder()
                              .required()
                              .build(),
                        ),
                        SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Password',
                          controller: passwordController,
                          type: TextInputType.visiblePassword,
                          isPass: true,
                          validatorCallback: ValidationBuilder()
                              .minLength(5)
                              .maxLength(50)
                              .required()
                              .build(),
                        ),
                        SizedBox(height: 10),
                        CustomTextField(
                          hint: 'Confirm Password',
                          controller: confirmPasswordController,
                          type: TextInputType.visiblePassword,
                          isPass: true,
                          validatorCallback: (value) {
                            if (passwordController.text != value) {
                              return 'Password did not match';
                            } else {
                              return null;
                            }
                          },
                        ),

                        SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: followButton,
                              foregroundColor: followButtonTextLight,
                            ),
                            child: Text('Sign Up'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style: TextStyle(color: darkTextPrimary)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: followButton,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
