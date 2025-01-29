import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart'; // Add this import
import '../config.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final String roommateId;
  final String roommateName;

  ChatPage({
    required this.userId,
    required this.roommateId,
    required this.roommateName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late IO.Socket socket;
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> filteredMessages = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);
  bool showEmojiPicker = false;
  bool isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Variables to hold the uploaded file data
  String? _uploadedFileUrl;
  String? _uploadedFileType;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    fetchChatHistory();
    connectToWebSocket();

    _controller.addListener(() {
      isButtonEnabled.value = _controller.text.isNotEmpty;
    });

    _searchController.addListener(() {
      filterMessages(_searchController.text);
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 150.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    socket.off('receiveMessage');
    socket.off('messageRead');
    socket.disconnect();
    socket.close();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      // Permissions are granted, proceed with file operations
    } else {
      // Handle the case when permissions are not granted
    }
  }

  Future<File> downloadAndSavePdf(String url, String fileName) async {
    final response = await http.get(Uri.parse(url));
    final documentDirectory = await getApplicationDocumentsDirectory();
    final file = File(join(documentDirectory.path, fileName));
    file.writeAsBytesSync(response.bodyBytes);
    return file;
  }

  String generateRoomId(String id1, String id2) {
    final ids = [id1, id2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> fetchChatHistory() async {
    final baseUrl = getBaseUrl();
    final url = '$baseUrl/api/chats/${widget.userId}/${widget.roommateId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            final fetchedMessages =
                List<Map<String, dynamic>>.from(json.decode(response.body));
            final Set<String> uniqueFileUrls = Set<String>();

            for (var message in fetchedMessages) {
              if (message['fileUrl'] != null) {
                if (uniqueFileUrls.contains(message['fileUrl'])) {
                  continue;
                }
                uniqueFileUrls.add(message['fileUrl']);
              }
              addMessageIfNotDuplicate(message);
            }

            filteredMessages = messages;
          });
          _scrollToBottom();
        }
      } else {
        print('Failed to fetch chat history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat history: $e');
    }
  }

  void addMessageIfNotDuplicate(Map<String, dynamic> newMessage) {
    final existing =
        messages.any((message) => message['_id'] == newMessage['_id']);
    if (!existing) {
      if (mounted) {
        setState(() {
          messages.add(newMessage);
          filteredMessages = messages;
        });
        _scrollToBottom();
      }
    }
  }

  void markMessagesAsRead() {
    final roomId = generateRoomId(widget.userId, widget.roommateId);
    socket.emit('markAsRead', {
      'userId': widget.userId,
      'roommateId': widget.roommateId,
      'roomId': roomId,
    });
  }

  void connectToWebSocket() {
    final baseUrl = getBaseUrl();
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      final roomId = generateRoomId(widget.userId, widget.roommateId);
      socket.emit('joinRoom', {'roomId': roomId});
      markMessagesAsRead();
    });

    socket.on('receiveMessage', (data) {
      if (mounted) {
        addMessageIfNotDuplicate(data);
        markMessagesAsRead();
      }
    });

    socket.on('messageRead', (data) {
      if (mounted) {
        setState(() {
          for (var message in messages) {
            if (message['senderId'] == widget.userId &&
                message['receiverId'] == data['userId']) {
              message['read'] = true;
            }
          }
        });
      }
    });

    socket.onDisconnect((_) {
      print('Disconnected from WebSocket');
    });
  }

  Future<void> _deleteChat() async {
    final baseUrl = getBaseUrl();
    final url = '$baseUrl/api/chats/delete-chat';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.userId,
          'roommateId': widget.roommateId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          messages.clear();
          filteredMessages.clear();
        });

        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Chat deleted successfully.')),
        );
      } else {
        print('Failed to delete chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else if (file.path != null) {
        final fileOnDisk = File(file.path!);
        fileBytes = await fileOnDisk.readAsBytes();
      }

      if (fileBytes == null) {
        print('Failed to read file bytes');
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${getBaseUrl()}/api/chats/upload-file'),
      );

      request.fields['senderId'] = widget.userId;
      request.fields['receiverId'] = widget.roommateId;
      request.fields['roomId'] =
          generateRoomId(widget.userId, widget.roommateId);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.name,
      ));

      try {
        final response = await request.send();

        if (response.statusCode == 201) {
          final responseBody = await response.stream.bytesToString();
          final uploadedFileMessage = jsonDecode(responseBody);

          setState(() {
            _uploadedFileUrl = uploadedFileMessage['fileUrl'];
            _uploadedFileType = uploadedFileMessage['fileType'];
          });

          setState(() {
            if (_uploadedFileType == 'image') {
              _controller.text = '[Image selected: $_uploadedFileUrl]';
            } else if (_uploadedFileType == 'document') {
              _controller.text = '[Document selected: $_uploadedFileUrl]';
            }
            isButtonEnabled.value = true;
          });
        } else {
          print('Failed to upload file: ${response.statusCode}');
        }
      } catch (e) {
        print('Error during file upload: $e');
      }
    }
  }

  void sendMessage(String message) {
    if (message.isNotEmpty) {
      final roomId = generateRoomId(widget.userId, widget.roommateId);

      Map<String, dynamic> messageData;
      if (message.startsWith('[Image selected: ')) {
        final fileUrl =
            message.substring(message.indexOf(': ') + 2, message.length - 1);
        messageData = {
          'roomId': roomId,
          'senderId': widget.userId,
          'receiverId': widget.roommateId,
          'fileUrl': fileUrl,
          'fileType': 'image',
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        };
      } else if (message.startsWith('[Document selected: ')) {
        final fileUrl =
            message.substring(message.indexOf(': ') + 2, message.length - 1);
        messageData = {
          'roomId': roomId,
          'senderId': widget.userId,
          'receiverId': widget.roommateId,
          'fileUrl': fileUrl,
          'fileType': 'document',
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        };
      } else {
        messageData = {
          'roomId': roomId,
          'senderId': widget.userId,
          'receiverId': widget.roommateId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        };
      }

      socket.emit('sendMessage', messageData);

      _controller.clear();
      isButtonEnabled.value = false;
      _scrollToBottom();

      setState(() {
        _uploadedFileUrl = null;
        _uploadedFileType = null;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void filterMessages(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredMessages = messages;
      });
    } else {
      setState(() {
        filteredMessages = messages
            .where((message) => message['message']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFCB603),
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.roommateName[0],
                  style: TextStyle(color: Color(0xFFFCB603)),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Chat with ${widget.roommateName}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Search') {
                setState(() {
                  isSearching = true;
                });
              } else if (value == 'Delete') {
                _deleteChat();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'Search',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFFFCB603)),
                    SizedBox(width: 10),
                    Text('Search', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete Chat', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.white),
            onPressed: _uploadFile,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (kIsWeb)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BubblesPainter(
                        animationValue: _animation.value, isWeb: kIsWeb),
                  );
                },
              ),
            ),
          Center(
            child: kIsWeb
                ? Container(
                    width: 800,
                    height: 600,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: buildChatBody(),
                  )
                : buildChatBody(),
          ),
        ],
      ),
    );
  }

  Widget buildChatBody() {
    return Column(
      children: [
        if (isSearching)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                prefixIcon: Icon(Icons.search, color: Colors.black),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      isSearching = false;
                      _searchController.clear();
                      filteredMessages = messages;
                    });
                  },
                ),
              ),
            ),
          ),
        Expanded(
          child: filteredMessages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = filteredMessages[index];
                    final isMe = message['senderId'] == widget.userId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (message['fileUrl'] != null &&
                              message['fileType'] == 'image')
                            GestureDetector(
                              onTap: () {
                                if (kIsWeb) {
                                  launch(
                                      '${getBaseUrl()}/${message['fileUrl']}');
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        appBar: AppBar(
                                          title: Text('Image Preview'),
                                        ),
                                        body: PhotoView(
                                          imageProvider:
                                              CachedNetworkImageProvider(
                                            '${getBaseUrl()}/${message['fileUrl']}',
                                          ),
                                          minScale:
                                              PhotoViewComputedScale.contained,
                                          maxScale:
                                              PhotoViewComputedScale.covered *
                                                  2,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: CachedNetworkImage(
                                imageUrl:
                                    '${getBaseUrl()}/${message['fileUrl']}',
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            )
                          else if (message['fileUrl'] != null &&
                              message['fileType'] == 'document')
                            GestureDetector(
                              onTap: () async {
                                final pdfUrl =
                                    '${getBaseUrl()}/${message['fileUrl']}';
                                if (await canLaunch(pdfUrl)) {
                                  await launch(pdfUrl);
                                } else {
                                  print('Could not launch $pdfUrl');
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.insert_drive_file,
                                      color: Colors.grey),
                                  SizedBox(width: 5),
                                  Text(
                                    'Open Document',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Color(0xFFFCB603)
                                    : Color(0xFFF7EAD9),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                message['message'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMe)
                                Icon(
                                  Icons.done_all,
                                  color: message['read']
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 16,
                                ),
                              SizedBox(width: 5),
                              Text(
                                message['timestamp'] != null
                                    ? DateTime.parse(message['timestamp'])
                                        .toLocal()
                                        .toString()
                                    : '',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (showEmojiPicker)
          Container(
            color: Colors.white,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _controller.text += emoji.emoji;
                isButtonEnabled.value = _controller.text.isNotEmpty;
              },
            ),
          ),
        Container(
          color: Color(0xFFF7EAD9),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.emoji_emotions,
                    color: Color(0xFFFCB603),
                  ),
                  onPressed: () {
                    setState(() {
                      showEmojiPicker = !showEmojiPicker;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: Color(0xFFFCB603),
                  ),
                  onPressed: _uploadFile,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isButtonEnabled,
                  builder: (context, isEnabled, child) {
                    return IconButton(
                      icon: Icon(
                        Icons.send,
                        color: isEnabled ? Color(0xFFFCB603) : Colors.grey,
                      ),
                      onPressed: isEnabled
                          ? () => sendMessage(_controller.text)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BubblesPainter extends CustomPainter {
  final double animationValue;
  final bool isWeb;

  BubblesPainter({required this.animationValue, required this.isWeb});

  @override
  void paint(Canvas canvas, Size size) {
    if (isWeb) {
      final paint = Paint()
        ..color = Color(0xFFFCB603).withOpacity(0.2)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 10; i++) {
        final offset = Offset(
          size.width * (i / 10) + animationValue,
          size.height * (i / 10) - animationValue,
        );
        canvas.drawCircle(offset, 50, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
