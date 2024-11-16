import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImgPage extends StatefulWidget {
  const ImgPage({super.key});

  @override
  State<ImgPage> createState() => _ImgPageState();
}

class _ImgPageState extends State<ImgPage> {
  List<String> messages = ["C:\\User>"];
  bool isCursorVisible = true;
  final TextEditingController _controller = TextEditingController();
  final dio = Dio();
  final link = dotenv.env['API_URL'];
  Uint8List? imageBytes;
  bool isLoading = false;

  void _clearResponse() async {
    debugPrint('in function');
    try {
      var response = await dio.get("$link/img/clear");
      debugPrint('****************');
      debugPrint(response.statusCode.toString());
      debugPrint(response.data.toString());
    } on DioException catch (e) {
      debugPrint(e.toString());
    }
  }

  void _handleUserInput(String input) async {
    debugPrint('Msg Sent !!! ');
    if (input == "/clear") {
      _clearResponse();
      setState(() {
        messages.clear();
        _controller.clear();
        messages.add("C:\\User>");
        imageBytes = null;
      });
    } else {
      _controller.clear();
      setState(() {
        messages.removeLast();
        messages.add("C:\\User> $input");
        isLoading = true;
      });
      try {
        // Send POST request to Flask app
        var response = await dio.post(
          "$link/img/generate-image",
          data: {"message": input},
          options:
              Options(responseType: ResponseType.bytes), // Expect image bytes
        );

        if (response.statusCode == 200) {
          setState(() {
            imageBytes = response.data; // Store the received image bytes
          });
        } else {
          debugPrint("Error: ${response.statusCode}");
        }
      } on DioException catch (e) {
        debugPrint(e.toString());
      } finally {
        setState(() {
          isLoading = false;
        });
      }
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
          '.img',
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
                child: Stack(
                  children: [
                    ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
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

                    // Show the progress indicator if loading
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Colors.amber,
                          ),
                        ),
                      ),

                    // Show the image if available
                    if (imageBytes != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Image.memory(imageBytes!),
                        ),
                      ),
                  ],
                ),
              ),

              // Text input field
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
                          hintText: 'Generate an Image...',
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
          )),
    );
  }
}
