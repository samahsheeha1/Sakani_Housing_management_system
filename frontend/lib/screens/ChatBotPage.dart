import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:string_similarity/string_similarity.dart'; // For fuzzy matching
import '../config.dart';
import '../services/api_service.dart';
import 'Chat.dart'; // Ensure this file contains the `getBaseUrl()` function

class ChatBotPage extends StatefulWidget {
  final String token; // Add token as a parameter
  const ChatBotPage({super.key, required this.token});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> chatMessages = [];
  List<Map<String, String>> faqs = [];
  String? userId; // Store the user's ID

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // Initialize chat by fetching FAQs and user profile
  Future<void> _initializeChat() async {
    // Fetch the user's profile to get the user ID
    await _fetchUserProfile();

    // Fetch FAQs from the backend
    await _fetchFAQs();

    // Add a welcome message
    setState(() {
      chatMessages.add({
        'sender': 'bot',
        'message': 'Hello! How can I help you today?',
        'isDefaultQuestion': false,
      });
    });
  }

  // Fetch the user's profile
  Future<void> _fetchUserProfile() async {
    try {
      final profile = await ApiService.fetchUserProfile(widget.token);
      setState(() {
        userId = profile['_id']; // Store the user's ID
      });
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  // Fetch FAQs from the backend
  Future<void> _fetchFAQs() async {
    try {
      final response = await http.get(Uri.parse('${getBaseUrl()}/api/faqs'));
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('API Response: $responseData'); // Log the API response

        // Handle different response formats
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('faqs')) {
          data = responseData['faqs'];
        } else {
          throw Exception('Invalid API response format');
        }

        // Explicitly cast the values to String
        setState(() {
          faqs = data
              .map<Map<String, String>>((faq) => {
                    'question': faq['question']?.toString() ?? 'No question',
                    'answer': faq['answer']?.toString() ?? 'No answer',
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to load FAQs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching FAQs: $e');
      throw Exception('Failed to load FAQs');
    }
  }

  // Find the best matching FAQ based on similarity
  Map<String, String> _findBestMatchingFAQ(String message) {
    // Convert the message to lowercase for case-insensitive comparison
    final lowerCaseMessage = message.toLowerCase();

    // Check if the user wants to contact the admin
    if (lowerCaseMessage.contains('contact admin') ||
        lowerCaseMessage.contains('talk to admin') ||
        lowerCaseMessage.contains('speak to admin')) {
      return {
        'question': '',
        'answer': 'Redirecting you to the admin...',
        'action': 'contactAdmin', // Add an action to trigger navigation
      };
    }

    // Use string_similarity to find the best match
    final bestMatch = StringSimilarity.findBestMatch(
      lowerCaseMessage,
      faqs.map((faq) => faq['question']!.toLowerCase()).toList(),
    );

    // If the best match has a high enough similarity score, return the corresponding FAQ
    if (bestMatch.bestMatch.rating! > 0.5) {
      return faqs[bestMatch.bestMatchIndex];
    }

    // If no match is found, return a default response
    return {
      'question': '',
      'answer': 'Sorry, I don\'t understand that question.',
    };
  }

  // Fetch admin details from the backend
  Future<Map<String, String>> fetchAdminDetails() async {
    final response =
        await http.get(Uri.parse('${getBaseUrl()}/api/users/details'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'id': data['id'],
        'name': data['name'],
      };
    } else {
      throw Exception('Failed to fetch admin details');
    }
  }

  // Send a message and get the bot's response
  Future<void> _sendMessage(String message) async {
    // Add the user's message to the chat
    setState(() {
      chatMessages.add({
        'sender': 'user',
        'message': message,
        'isDefaultQuestion': false,
      });
    });

    // Find the best matching FAQ
    final faq = _findBestMatchingFAQ(message);

    // Add the bot's response to the chat
    setState(() {
      chatMessages.add({
        'sender': 'bot',
        'message': faq['answer']!,
        'isDefaultQuestion': false,
      });
    });

    // If the action is to contact the admin, navigate to the ChatPage
    if (faq['action'] == 'contactAdmin') {
      // Fetch admin details
      final adminDetails = await fetchAdminDetails();

      // Navigate to the ChatPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userId: userId!, // Pass the current user's ID
            roommateId: adminDetails['id']!, // Pass the admin's ID
            roommateName: adminDetails['name']!, // Pass the admin's name
          ),
        ),
      );
    }

    // Clear the input field
    _controller.clear();
  }

  // Send a default question
  void _sendDefaultQuestion(String question) {
    _sendMessage(question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Bot'),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                final isUser = message['sender'] == 'user';

                // Display default questions as buttons after the welcome message
                if (index == 0 && chatMessages.length == 1) {
                  return Column(
                    children: [
                      // Welcome message
                      _buildChatBubble(
                        message: message['message'],
                        isUser: false,
                      ),
                      const SizedBox(height: 16),
                      // Default questions
                      ...faqs.take(3).map((faq) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ElevatedButton(
                            onPressed: () =>
                                _sendDefaultQuestion(faq['question']!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade100,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: Text(faq['question']!),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }

                // Regular chat messages
                return _buildChatBubble(
                  message: message['message'],
                  isUser: isUser,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build a chat bubble
  Widget _buildChatBubble({required String message, required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? Colors.orange.shade200 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              Icon(
                Icons.android,
                color: Colors.orange.shade700,
              ),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.black : Colors.black87,
              ),
            ),
            if (isUser) const SizedBox(width: 8),
            if (isUser)
              Icon(
                Icons.person,
                color: Colors.orange.shade700,
              ),
          ],
        ),
      ),
    );
  }
}
