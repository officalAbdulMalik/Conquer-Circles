import 'package:flutter/material.dart';

import '../widgets/chat_bubble.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/quick_action_chips.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _selectedCoachChip = 0;

  final List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[
    {
      'message':
          'Hey there, FitWarrior! I\'m your personal fitness coach. How can I help you today?',
      'isUser': false,
      'timestamp': 'Now',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _appendMessage({required String message, required bool isUser}) {
    setState(() {
      _messages.add({'message': message, 'isUser': isUser, 'timestamp': 'Now'});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSend() {
    final String message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    _appendMessage(message: message, isUser: true);
    _messageController.clear();

    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) {
        return;
      }
      _appendMessage(
        message:
            'Nice one. I can break that into a simple plan and reminders for today.',
        isUser: false,
      );
    });
  }

  void _handlePromptTap(String prompt) {
    _appendMessage(message: prompt, isUser: true);
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) {
        return;
      }
      _appendMessage(
        message: 'Done. I prepared a quick action based on "$prompt".',
        isUser: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          const ChatHeader(title: 'FitCoach AI'),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: QuickActionChips(
              chips: const ['Daily Goals', 'Workouts', 'Stats', 'Nutrition'],
              chipIcons: const [
                Icons.gps_fixed_rounded,
                Icons.fitness_center_rounded,
                Icons.bar_chart_rounded,
                Icons.restaurant_menu_rounded,
              ],
              useCoachStyle: true,
              selectedIndex: _selectedCoachChip,
              onChipIndexTapped: (int index) {
                setState(() {
                  _selectedCoachChip = index;
                });
              },
              onChipTapped: (String chip) {
                _appendMessage(message: chip, isUser: true);
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EAF0)),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> msg = _messages[index];
                final bool isUser = msg['isUser'] == true;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChatBubble(
                      message: msg['message'] as String,
                      isUser: isUser,
                      timestamp: msg['timestamp'] as String,
                      showTimestamp: false,
                    ),
                    if (index == 0 && !isUser) _buildCoachSuggestions(),
                  ],
                );
              },
            ),
          ),
          _buildBottomComposer(),
        ],
      ),
    );
  }

  Widget _buildCoachSuggestions() {
    const List<String> prompts = <String>[
      'Show my progress',
      'Set a goal',
      'Motivate me!',
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: prompts
            .map(
              (String prompt) => GestureDetector(
                onTap: () => _handlePromptTap(prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0FB),
                    border: Border.all(color: const Color(0xFFE1DDF6)),
                  ),
                  child: Text(
                    prompt,
                    style: const TextStyle(
                      color: Color(0xFF746CC4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBottomComposer() {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatInputArea(
            controller: _messageController,
            onAdd: () {},
            onSend: _handleSend,
            showAddButton: false,
            hintText: 'Ask me anything...',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          const SizedBox(height: 10),
          const _CoachStatsRow(),
        ],
      ),
    );
  }
}

class _CoachStatsRow extends StatelessWidget {
  const _CoachStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _CoachStatItem(
          icon: Icons.bolt_rounded,
          color: Color(0xFF8172D8),
          value: '2.4K',
          label: 'XP',
        ),
        SizedBox(width: 14),
        _CoachStatItem(
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFFF6B6B),
          value: '12',
          label: 'streak',
        ),
        SizedBox(width: 14),
        _CoachStatItem(
          icon: Icons.trending_up_rounded,
          color: Color(0xFF3DA9F5),
          value: '85%',
          label: 'goal',
        ),
      ],
    );
  }
}

class _CoachStatItem extends StatelessWidget {
  const _CoachStatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9A9DA8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
