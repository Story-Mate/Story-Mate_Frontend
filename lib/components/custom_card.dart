// 작품 카드 위젯

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final String tags;

  const CustomCard({
    super.key,
    required this.title,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 129,
      decoration: BoxDecoration(
        color: Color(0xffd9d9d9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.6),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Jua',
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: -0.23,
              ),
            ),
            Text(
              tags,
              style: TextStyle(
                color: Color(0xFF7C7C7C),
                fontSize: 10,
                fontFamily: 'Jua',
                fontWeight: FontWeight.w400,
                height: 2,
                letterSpacing: -0.23,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
