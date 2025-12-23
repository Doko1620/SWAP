import 'package:flutter/material.dart';

class MyButton extends StatelessWidget{

  final String text;
  const MyButton({super.key,
  required this.text});

  @override
  Widget build(BuildContext context){
    return Container(
      decoration: BoxDecoration(color: Color.fromARGB(255, 77, 44, 111)),
      child: Text(text),
    );
  }
}