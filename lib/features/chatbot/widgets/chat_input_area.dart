import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAdd;
  final bool showAddButton;
  final String hintText;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAdd,
    this.showAddButton = false,
    this.hintText = 'Ask me anything...',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E4EC)),
            ),
            child: Row(
              children: [
                if (showAddButton)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: onAdd,
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: Color(0xFF7D7E85),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(
                      color: Color(0xFF30323A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSend,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7E8EE)),
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Color(0xFFC5C6CF),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
