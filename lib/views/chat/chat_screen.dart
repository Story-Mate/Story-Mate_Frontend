import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/models/message.dart';
import 'package:storymate/services/api_service.dart';
import 'package:storymate/view_models/chat/chat_controller.dart';
import 'package:storymate/views/chat/character_selection_screen.dart';
import 'package:storymate/views/chat/chat_bubble.dart';
import 'package:storymate/views/chat/quiz_screen.dart';
import 'package:storymate/views/mypage/my_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  final String charactersName;
  final String bookTitle;
  final int roomId;

  const ChatScreen({
    required this.charactersName,
    required this.bookTitle,
    required this.roomId,
    super.key,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService apiService = ApiService();
  var messageCount = 0.obs;

  WebSocketChannel? channel;
  DateTime lastMessageReceived = DateTime.now();
  final ChatController controller = Get.put(ChatController());
  Timer? pingTimer;
  late int roomId;
  late String bookTitle;
  late String charactersName;
  List<dynamic> chatMessages = [];
  int answerCount = 0;
  bool isQuizButtonEnabled = false;
  bool hasQuizNotificationShown = false;
  var isSendingMessage = false.obs;

  @override
  void initState() {
    super.initState();
    roomId = widget.roomId;
    bookTitle = widget.bookTitle;
    charactersName = widget.charactersName;

    debugPrint(
        "초기 데이터: bookTitle: $bookTitle, charactersName: $charactersName, roomId: $roomId");

    if (roomId == 0) {
      debugPrint("기존 채팅방 확인 중...");

      // ✅ 비동기 함수 내부에서 실행
      _initializeChatRoom();
    } else {
      debugPrint("✅ 기존 roomId 사용: $roomId");
      connectWebSocket();
      fetchChatMessages();
    }

    fetchUserInfo();
  }

  /// 회원 정보 조회 API 호출 (잔여 메시지 동기화)
  Future<void> fetchUserInfo() async {
    try {
      final userData = await apiService.fetchUserInfo();
      if (userData != null) {
        setState(() {
          messageCount.value = userData["messageCount"] ?? 0;
        });
        print("회원 정보 조회 성공: 메시지 개수 = ${messageCount.value}");
      } else {
        print("회원 정보 조회 실패");
      }
    } catch (e) {
      print("회원 정보 조회 중 오류 발생: $e");
    }
  }

  /// 메시지가 부족할 경우 안내창 표시
  Future<void> _showNoMessageAlert() async {
    await Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "메시지 부족",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                "잔여 메시지가 부족하여 채팅을 보낼 수 없습니다.\n충전 후 이용해주세요.",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.off(MyPage()); // 마이페이지로 이동
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text(
                  "충전하러 가기",
                  style: TextStyle(
                    fontFamily: 'Jua',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeChatRoom() async {
    String? token = await getToken(); // ✅ 먼저 토큰 가져오기
    if (token == null) {
      debugPrint("⚠️ 로그인 필요 - 채팅방 확인 불가");
      return;
    }

    await getUserChatRooms(token); // ✅ 가져온 토큰을 넘겨주기
  }

  void handleReceivedMessage(String message) {
    lastMessageReceived = DateTime.now();
    if (message.contains("Invalid message format")) {
      debugPrint("⚠️ 서버 필터 메시지 감지 (무시): $message");
      return;
    }
    var splitMessage = message.split(':');
    if (splitMessage.length < 2) return;
    String sender = splitMessage[0];
    String messageContent = splitMessage.sublist(1).join(':');
    if (sender == 'testUser') {
      debugPrint("⚠️ testUser 메시지 감지 (무시)");
      return;
    }
    setState(() {
      chatMessages.add({
        'content': messageContent,
        'sender': sender,
        'isUser': false,
      });
      answerCount++;
      isSendingMessage.value = false;
    });
    if (answerCount >= 3 && !isQuizButtonEnabled) {
      setState(() {
        isQuizButtonEnabled = true;
      });
      if (!hasQuizNotificationShown) {
        _showQuizAvailableNotification();
        hasQuizNotificationShown = true;
      }
    }
  }

  void startConnectionMonitor() {
    pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      // Duration timeSinceLastMessage =
      //     DateTime.now().difference(lastMessageReceived);

      // if (timeSinceLastMessage.inSeconds > 90) {
      //   print("서버 응답 없음 -> 웹소켓 재연결 시도");
      //   reconnectWebSocket();
      // } else {
      //   sendPingMessage();
      // }
      sendPingMessage();
    });
  }

  void sendPingMessage() {
    if (channel != null) {
      channel!.sink.add("ping");
      print("Ping 메시지 전송됨 (간단한 형식)");
    }
  }

  Future<void> initializeChat() async {
    String? token = await getToken();
    if (token == null) {
      debugPrint("❌ 로그인 정보 없음 → 로그인 필요");
      return;
    }

    int? lastRoomId = await getUserChatRooms(token);
    if (lastRoomId != null) {
      roomId = lastRoomId;
      debugPrint("✅ 가장 최근 대화한 채팅방으로 입장: roomId = $roomId");
      connectWebSocket();
      fetchChatMessages();
    } else {
      debugPrint("⚠️ 기존 채팅방 없음 → 대기");
    }
  }

  Future<int?> getUserChatRooms(String token) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://be.dev.storymate.site/api/chat-rooms?page=0&size=10'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> chatRooms = responseData["chatRoomResDtos"] ?? [];

        if (chatRooms.isNotEmpty) {
          // 가장 최근 채팅방 찾기 (채팅방 ID 기준 정렬)
          chatRooms.sort((a, b) => b["roomId"].compareTo(a["roomId"]));
          int recentRoomId = chatRooms.first["roomId"];

          // 캐릭터 정보 가져오기
          charactersName = chatRooms.first["charactersName"] ?? "알 수 없음";
          bookTitle = chatRooms.first["bookTitle"] ?? "미정";

          return recentRoomId;
        }
      } else {
        debugPrint("⚠️ 채팅방 조회 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ 채팅방 조회 오류: $e");
    }
    return null;
  }

  void reconnectWebSocket() {
    channel?.sink.close();
    channel = null;
    channel = WebSocketChannel.connect(
      Uri.parse('wss://be.dev.storymate.site/chat/$roomId'),
    );
    print("웹소켓 재연결 완료");
    startConnectionMonitor();
    channel!.stream.listen((message) {
      print("수신된 원본 메시지: $message");
      lastMessageReceived = DateTime.now();
      try {
        if (message.contains("Invalid message format")) {
          print("서버에서 필터링된 메시지 수신됨 (무시): $message");
          return;
        }
        var splitMessage = message.split(':');
        if (splitMessage.length < 2) return;
        String sender = splitMessage[0];
        String messageContent = splitMessage.sublist(1).join(':');
        if (sender == 'testUser') {
          print("testUser 응답 수신됨, 무시됨: $messageContent");
          return;
        }
        setState(() {
          chatMessages.add({
            'content': messageContent,
            'sender': sender,
            'isUser': false,
          });
          answerCount++;
          isSendingMessage.value = false;
        });
        if (answerCount >= 3 && !isQuizButtonEnabled) {
          setState(() {
            isQuizButtonEnabled = true;
          });
          if (!hasQuizNotificationShown) {
            _showQuizAvailableNotification();
            hasQuizNotificationShown = true;
          }
        }
      } catch (e) {
        print("메시지 처리 오류: $e");
      }
    });
  }

  Future<int?> getExistingChatRoom(int characterId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = await getToken();
    if (token == null) {
      print(" 토큰 없음 - 로그인 필요");
      return null;
    }
    try {
      final response = await http.get(
        Uri.parse(
            'https://be.dev.storymate.site/api/chat-rooms?page=0&size=10'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> chatRooms = responseData["chatRoomResDtos"] ?? [];
        for (var room in chatRooms) {
          if (room["charactersId"] == characterId) {
            print(" 기존 채팅방 발견: roomId = ${room["roomId"]}");
            await prefs.setInt('lastRoomId_$characterId', room["roomId"]);
            return room["roomId"];
          }
        }
      } else {
        print(" 채팅방 조회 실패: ${response.statusCode}");
      }
    } catch (e) {
      print(" 기존 채팅방 조회 중 오류 발생: $e");
    }
    return null;
  }

  Future<void> enterChatRoom(int characterId, String title, String bookTitle,
      String charactersName) async {
    int? existingRoomId = await getExistingChatRoom(characterId);
    if (existingRoomId != null) {
      print(" 기존 채팅방으로 입장: roomId = $existingRoomId");
      Get.to(() => ChatScreen(
            roomId: roomId,
            bookTitle: bookTitle,
            charactersName: charactersName,
          ));
    } else {
      print(" 기존 채팅방 없음 → 새 채팅방 생성 요청");
      await createChatRoom(title, characterId, bookTitle, charactersName);
    }
  }

  Future<void> createChatRoom(String title, int characterId, String bookTitle,
      String charactersName) async {
    final token = await getToken();
    if (token == null) {
      print(" 토큰 없음 - 로그인 필요");
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('https://be.dev.storymate.site/api/chat-rooms'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'charactersId': characterId,
          'bookTitle': bookTitle,
        }),
      );
      if (response.statusCode == 201) {
        var data = json.decode(response.body);
        int newRoomId = data['data']['roomId'];
        print(" 새 채팅방 생성됨: roomId = $newRoomId");
        await saveRoomId(characterId, newRoomId);
        Get.to(() => ChatScreen(
              roomId: newRoomId,
              bookTitle: bookTitle,
              charactersName: charactersName,
            ));
      } else {
        print(" 채팅방 생성 실패: ${response.statusCode}");
      }
    } catch (e) {
      print(" 채팅방 생성 중 오류 발생: $e");
    }
  }

  Future<void> fetchChatMessages() async {
    final token = await getToken();
    if (token == null) {
      debugPrint("⚠️ 토큰 없음");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://be.dev.storymate.site/api/chat-messages/$roomId?page=0&size=10'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          chatMessages = responseData['data']['chatMessages'] ?? [];
        });
      } else {
        debugPrint("❌ 채팅 메시지 조회 실패: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ 채팅 메시지 조회 오류: $e");
    }
  }

  Future<void> loadChatRoom() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    charactersName = Get.arguments["charactersName"] ?? "";
    bookTitle = Get.arguments["bookTitle"] ?? "";
    int characterId = Get.arguments["characterId"] ?? 0;
    print(" [DEBUG] 캐릭터 선택됨: $charactersName (ID: $characterId)");
    int? existingRoomId = await getExistingChatRoom(characterId);
    int argumentRoomId = Get.arguments["roomId"] ?? 0;
    print(" [DEBUG] 저장된 roomId: $existingRoomId, 전달된 roomId: $argumentRoomId");
    if (existingRoomId != null && existingRoomId != 0) {
      roomId = existingRoomId;
      print(" 기존 채팅방 유지: roomId = $roomId");
    } else if (argumentRoomId != 0) {
      roomId = argumentRoomId;
      print(" 새로운 roomId 저장: $roomId");
    } else {
      print(" 기존 roomId 없음 → 새로운 채팅방 생성 방지 필요");
      return;
    }
    print(" 현재 사용되는 roomId: $roomId");
    if (roomId != 0 && channel == null) {
      connectWebSocket();
      fetchChatMessages();
    } else {
      print(" WebSocket이 이미 연결되어 있음.");
    }
  }

  Future<void> saveRoomId(int characterId, int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastRoomId_$characterId', roomId);
    print(" roomId 저장 완료: $roomId");
  }

  Future<int?> getSavedRoomId(int characterId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastRoomId_$characterId');
  }

  void connectWebSocket() {
    if (channel != null) {
      debugPrint(" 이미 연결된 웹소켓 존재");
      return;
    }
    channel = WebSocketChannel.connect(
      Uri.parse('wss://be.dev.storymate.site/chat/$roomId'),
    );
    pingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      sendPingMessage();
    });
    channel!.stream.listen(
      (message) {
        handleReceivedMessage(message);
      },
      onDone: () => reconnectWebSocket(),
      onError: (_) => reconnectWebSocket(),
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  void selectCharacter(int characterId, String title, String bookTitle) async {
    await enterChatRoom(characterId, title, bookTitle, title);
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    // 메시지 부족 시 차단
    if (messageCount.value == 0) {
      _showNoMessageAlert();
      return;
    }

    setState(() => isSendingMessage.value = true);
    if (chatMessages
        .any((msg) => msg['content'] == message && msg['isUser'] == true)) {
      print("중복 메시지 전송 시도 방지");
      return;
    }
    setState(() {
      isSendingMessage.value = true;
    });
    String sender = "testUser";
    try {
      channel?.sink.add("$sender:$roomId:$bookTitle:$message");
      setState(() {
        chatMessages.add({
          'content': message,
          'sender': 'You',
          'isUser': true,
        });
      });

      await fetchUserInfo();
      print("메시지 전송 완료: $message");
    } catch (e) {
      print("메시지 전송 실패: $e");
    } finally {
      controller.textController.clear();
      controller.update();
    }
  }

  void _showQuizLockedDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "퀴즈 도전 불가",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Text(
                "퀴즈를 도전하기 위해서는 $charactersName과 대화를 더 진행해 주세요!",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "확인",
                  style: TextStyle(
                    fontFamily: 'Jua',
                    fontSize: 18.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuizAvailableNotification() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "퀴즈가 열렸습니다!",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Text(
                "퀴즈를 통해 추가 메세지 개수를 얻으실 수 있어요!",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "나중에 도전하기",
                        style: TextStyle(
                          fontFamily: 'Jua',
                          fontSize: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        channel?.sink.close();
                        pingTimer?.cancel();
                        print("퀴즈 시작 -> 웹소켓 연결 종료");
                        Get.to(() => QuizScreen(), arguments: {
                          "characterName": charactersName,
                          "bookTitle": bookTitle,
                        })?.then((_) {
                          // ?. 연산자를 사용해 null safety를 확보합니다.
                          reconnectWebSocket();
                          print("퀴즈 종료 -> 웹소켓 재연결");
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "지금 도전하기",
                        style: TextStyle(
                          fontFamily: 'Jua',
                          fontSize: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    pingTimer?.cancel();
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 뒤로 가기 방지
      onPopInvoked: (didPop) {
        if (didPop) return; // 뒤로 가기 요청 무시
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              channel?.sink.close();
              pingTimer?.cancel();
              print("웹소켓 연결 종료");
              Get.off(CharacterSelectionScreen());
            },
            child: Icon(
              Icons.arrow_back_ios_new,
            ),
          ),
          title: Text(
            "${widget.charactersName} 대화하기 ", // 캐릭터 이름 표시
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.black,
              fontFamily: 'Jua',
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    if (!isQuizButtonEnabled) {
                      _showQuizLockedDialog();
                    } else {
                      channel?.sink.close();
                      pingTimer?.cancel();
                      print("퀴즈 시작 -> 웹소켓 연결 종료");
                      Get.to(() => QuizScreen(), arguments: {
                        "characterName": charactersName,
                        "bookTitle": bookTitle,
                      })!
                          .then((_) {
                        reconnectWebSocket();
                        print("퀴즈 종료 -> 웹소켓 재연결");
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isQuizButtonEnabled
                        ? Colors.purple[400]
                        : Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    minimumSize: Size(100, 36),
                  ),
                  child: Text(
                    "퀴즈 도전하기",
                    style: TextStyle(
                      fontFamily: 'Jua',
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount:
                    chatMessages.length + (isSendingMessage.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isSendingMessage.value && index == chatMessages.length) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  var message = chatMessages[index];
                  return ChatBubble(
                    message: Message(
                      content: message['content'],
                      isUser: message['isUser'],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: 30.h, left: 10.w, right: 10.w, top: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() => TextField(
                          controller: controller.textController,
                          decoration: InputDecoration(
                            hintText: messageCount.value > 0
                                ? "메시지를 입력하세요"
                                : "메시지를 보낼 수 없습니다",
                          ),
                          enabled: messageCount.value > 0,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(fontSize: 16.sp, fontFamily: 'Jua'),
                          onSubmitted: (value) {
                            if (!isSendingMessage.value &&
                                value.trim().isNotEmpty &&
                                messageCount.value > 0) {
                              sendMessage(value);
                            }
                          },
                        )),
                  ),
                  Obx(() => IconButton(
                        icon: Icon(Icons.send),
                        color: messageCount.value > 0
                            ? AppTheme.primaryColor
                            : Colors.grey,
                        onPressed: messageCount.value > 0 &&
                                !isSendingMessage.value
                            ? () {
                                String message = controller.textController.text;
                                if (message.isNotEmpty) {
                                  sendMessage(message);
                                }
                              }
                            : null,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
