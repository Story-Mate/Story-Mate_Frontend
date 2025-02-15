import 'package:flutter/material.dart';
import '../../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFF9B9FD0) : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Text(
            message.content,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            softWrap: true, // 텍스트가 길어지면 자동 줄바꿈
          ),
        ),
      ),
    );
  }
}
