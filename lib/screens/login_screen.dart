import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';

import 'package:habitsapp/animations/login_animation.dart';
//import 'package:habitsapp/animations/hiWelcomeAnimation.dart';

class LoginScreen extends StatefulWidget {
  @override
  LoginPage createState() => LoginPage();
}

class LoginPage extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  Future<void> logIn() async {
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful")),
      );
    } on FirebaseAuthException catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failure \n ${err.message}")),
      );
    }

    setState(() => loading = false);
  }

  Future<void> register() async {
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Creation Successful")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account Creation Failure \n  ${e.message}")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(children: [
        Expanded(
          flex: 1,
          child: Center(
            child: HiWelcomeAnimation(),
          ),
        ),
        Container(
            height: double.infinity,
            width: 660,
            padding: const EdgeInsets.all(75),
            decoration: const BoxDecoration(
                gradient: RadialGradient(
              center: Alignment(0.5, 0),
              radius: 0.8,
              colors: [Colors.lime, Colors.lightBlue],
              stops: <double>[0.4, 1.0],
            )),
            child: Container(
                height: 500,
                width: 400,
                margin: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(40.0)),
                  color: Colors.white,
                ),
                child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(children: [
                        const SizedBox(height: 35),
                        const Text("Login",
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 80),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            hoverColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            hoverColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 100),
                        Row(
                          children: [
                            const SizedBox(width: 60),
                            ElevatedButton(
                              onPressed: logIn,
                              child: const Text("Login"),
                            ),
                            const SizedBox(width: 40),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RegisterScreen()),
                                );
                              },
                              child: const Text("Register"),
                            ),
                          ],
                        ),
                      ]),
                    ))))
      ]),
    );
  }
}
