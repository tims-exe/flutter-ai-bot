import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bot',
      debugShowCheckedModeBanner: false,
      home: RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Add scroll controller
  List<String> messages = ["C:\\User>"];
  bool isCursorVisible = true;

  void _handleUserInput(String input) async {
    debugPrint('Msg Sent !!! ');
    if (input == "/clear") {
      setState(() {
        messages.clear();
        _controller.clear();
        messages.add("C:\\User>");
      });
    } else {
      _controller.clear();
      setState(() {
        messages.removeLast();
        messages.add("C:\\User> $input");
      });
      String botResponse = await _sendMessageToBackend(input);
      _scrollToBottom();
      setState(() {
        messages.add(botResponse);
        messages.add("C:\\User>");
      });
    }

    // Scroll to the bottom when a new message is added
    _scrollToBottom();
  }

  // Scroll to the bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String> _sendMessageToBackend(String userMessage) async {
    final url = Uri.parse('http://127.0.0.1:5000/chat');  // URL for Flask endpoint
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({"message": userMessage});

    try {
      final response = await http.post(url, headers: headers, body: body);
      debugPrint('got response');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? "Error: No response from bot";
      } else {
        return "Error: Failed to get response";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  @override
  void initState() {
    super.initState();

    // Make the cursor blink
    Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          isCursorVisible = !isCursorVisible;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '.bot',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding:
            const EdgeInsets.only(bottom: 50, left: 30, right: 30, top: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController, // Attach the scroll controller
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  // Check if it's the last message (C:\User>) and if it's the one where the cursor should be
                  if (messages[index] == "C:\\User>" &&
                      index == messages.length - 1) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            height: 30,
                            child: Text(
                              messages[index],
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isCursorVisible
                                ? const Text(
                                    ' |',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 20,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      messages[index],
                      style: TextStyle(
                        color: index.isEven ? Colors.amber : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white70, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask...',
                        hintStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        FocusScope.of(context).unfocus();
                        _handleUserInput(_controller.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
