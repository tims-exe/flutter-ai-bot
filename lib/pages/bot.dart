import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BotPage extends StatefulWidget {
  const BotPage({super.key});

  @override
  State<BotPage> createState() => _BotPageState();
}

class _BotPageState extends State<BotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Add scroll controller
  List<String> messages = ["C:\\User>"];
  bool isCursorVisible = true;
  final dio = Dio();
  final link = dotenv.env['API_URL'];

  void _handleUserInput(String input) async {
    debugPrint('Msg Sent !!! ');
    if (input == "/clear") {
      _clearResponse();
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

      //_testResponse();

      String botResponse = await _sendMessageToBackend(input);
      //_scrollToBottom();
      setState(() {
        messages.add(botResponse);
        messages.add("C:\\User>");
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      
    }
  }

  /* void _testResponse() async {
    debugPrint('in function');
    try {
      var response = await dio.get($url);
      debugPrint('****************');
      debugPrint(response.statusCode.toString());
      debugPrint(response.data.toString());
    } on DioException catch (e) {
      debugPrint(e.toString());
    }
  } */

  void _clearResponse() async {
    debugPrint('in function');
    try {
      var response = await dio.get("$link/clear");
      debugPrint('****************');
      debugPrint(response.statusCode.toString());
      debugPrint(response.data.toString());
    } on DioException catch (e) {
      debugPrint(e.toString());
    }
  }

  // Scroll to the bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final newOffset =
          _scrollController.offset + 500; // Increase by 500 pixels
      _scrollController.animateTo(
        newOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ), // Ensure it doesn't exceed max scroll extent
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String> _sendMessageToBackend(String userMessage) async {
    final url =
        Uri.parse('$link/chat'); // URL for Flask endpoint
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

    _clearResponse();

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
                      minLines: 1, // Minimum height
                      maxLines: null, // Allow expansion as needed
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
    );}
}