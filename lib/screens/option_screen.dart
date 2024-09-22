import 'package:blog_app/components/round_button.dart';
import 'package:blog_app/screens/log_in_screen.dart';
import 'package:blog_app/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
class option_screen extends StatefulWidget {
  const option_screen({super.key});

  @override
  State<option_screen> createState() => _option_screenState();
}

class _option_screenState extends State<option_screen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(image: AssetImage("assets/images/firebase_image.webp"),),
              SizedBox(height: 30,),
            RoundButton(title: "LogIn",
                onPress: (){
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LogInScreen(),));
                }),
            SizedBox(height: 30,),
            RoundButton(title: "Register",
                onPress: (){
              Navigator.push(context,
              MaterialPageRoute(builder: (context) => SignInScreen(),));
                }),
          ],),
        ),
      ),
    ));
  }
}
