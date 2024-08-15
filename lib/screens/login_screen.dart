import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/screens/auth_screen.dart';
import '/components/my_button.dart';
import '/components/my_textfield.dart';
import '/components/square_tile.dart';
import '/services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Function()? onTap;
  LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() {
    return LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleSignIn() async {
    // show loading circle
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xffE01C2F)),
          );
        });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      print('Usuário ${userCredential.user!.email} logado!');

      // go to home screen
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => AuthScreen()));
    } on FirebaseAuthException catch (e) {
      // pop the loading circle
      Navigator.pop(context);

      // show errors messsages
      if (e.code == 'invalid-credential') {
        genericErrorMessage('Credenciais inválidas, tente novamente!');
      } else if (e.code == 'invalid-email') {
        genericErrorMessage('Informe um email válido!');
      } else if (e.code == 'user-not-found') {
        genericErrorMessage('Email não encontrado, efetue o registro!');
      } else if (e.code == 'wrong-password') {
        genericErrorMessage('Senha incorreta, tente novamente!');
      } else {
        // another error
        genericErrorMessage(e.code);
      }
    }
  }

  void genericErrorMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 243, 243, 243),
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                SizedBox(
                  height: 200,
                  child: Image.asset('lib/logos/remax.png'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Olá, efetue o login para continuar. ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),

                MyTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icon(Icons.email_outlined),
                  obscureText: false,
                  capitalization: false,
                ),
                const SizedBox(height: 15),

                MyTextField(
                  controller: _passwordController,
                  hintText: 'Senha',
                  icon: Icon(Icons.lock_outline),
                  obscureText: true,
                  capitalization: false,
                ),
                const SizedBox(height: 15),

                MyButton(
                  onPressed: _handleSignIn,
                  formKey: _formKey,
                  text: 'Logar-se',
                ),
                const SizedBox(height: 20),

                // continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Text(
                          'OU',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                //google button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //google buttom
                    SquareTile(
                      onTap: () => GoogleAuthService().signInWithGoogle(),
                      imagePath: 'lib/icons/google.svg',
                      height: 70,
                    )
                  ],
                ),
                const SizedBox(height: 30),

                // not a memeber ? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Novo por aqui? ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Registre-se',
                        style: TextStyle(
                            color: Color(0xffE01C2F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
