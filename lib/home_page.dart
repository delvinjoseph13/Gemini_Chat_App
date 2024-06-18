import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "gemini model");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Chat App"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
        currentUser: currentUser, 
        onSend: _sendMessage, 
        messages: messages,
        inputOptions: InputOptions(trailing: [
          IconButton(onPressed: _sendMediaMessage, icon: Icon(Icons.image))
        ]),);
  }

  void _sendMessage(ChatMessage chatmessage) {
    setState(() {
      messages = [chatmessage, ...messages];
    });

    try {
      String question = chatmessage.text;
      List<Uint8List> images = [];
      if (chatmessage.medias?.isNotEmpty ?? false) {
        images=[
          File(chatmessage.medias!.first.url).readAsBytesSync()
        ];
      }
      gemini.streamGenerateContent(question,images: images).listen(
        (event) {
          ChatMessage? lastmessage = messages.firstOrNull;

          if (lastmessage != null && lastmessage.user == geminiUser) {
            lastmessage = messages.removeAt(0);
            String response = event.content?.parts?.fold(
                    "", (previous, current) => "$previous${current.text}") ??
                "";
            lastmessage.text += response;

            setState(() {
              messages = [lastmessage!, ...messages];
            });
          } else {
            String response = event.content?.parts?.fold(
                    "", (previous, current) => "$previous${current.text}") ??
                "";
            ChatMessage message = ChatMessage(
                user: geminiUser, createdAt: DateTime.now(), text: response);

            setState(() {
              messages = [message, ...messages];
            });
          }
        },
      );
    } catch (e) {
      print(e);
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: "Describe the image",
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image)
          ]);

      _sendMessage(chatMessage);
    }
  }
}
