class CircleMessagesState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? error;

  CircleMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  CircleMessagesState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? error,
  }) {
    return CircleMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
