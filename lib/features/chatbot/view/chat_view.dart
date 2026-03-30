import 'package:flutter/material.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/quick_action_chips.dart';
import '../widgets/chat_input_area.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'message':
          "Hello! I'm your Territory AI health assistant. I've synced your latest activity data. How can I help you reach your fitness goals today?",
      'isUser': false,
      'timestamp': '09:41 AM',
    },
    {
      'message': "How many steps have I taken today?",
      'isUser': true,
      'timestamp': '09:42 AM',
    },
    {
      'message':
          "You've taken 6,432 steps so far. You're 64% of the way to your daily goal of 10,000!",
      'isUser': false,
      'timestamp': '09:42 AM',
      'extraContent': true,
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F8),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const ChatHeader(title: 'Territory AI'),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(
                  message: msg['message'],
                  isUser: msg['isUser'],
                  timestamp: msg['timestamp'],
                  extraContent: msg['extraContent'] == true
                      ? _buildProgressExtra()
                      : null,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1 - 10,
            ),
            child: _buildBottomArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressExtra() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.64,
            backgroundColor: const Color(0xFF0D968B).withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D968B)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF0D968B).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickActionChips(
            chips: const [
              'Check my steps',
              'Walk suggestions',
              'Territory tips',
              'Hydration log',
            ],
            onChipTapped: (chip) {
              setState(() {
                _messages.add({
                  'message': chip,
                  'isUser': true,
                  'timestamp': 'Just now',
                });
              });
            },
          ),
          const SizedBox(height: 10),
          ChatInputArea(
            controller: _messageController,
            onAdd: () {},
            onSend: () {
              if (_messageController.text.isNotEmpty) {
                setState(() {
                  _messages.add({
                    'message': _messageController.text,
                    'isUser': true,
                    'timestamp': 'Just now',
                  });
                  _messageController.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
