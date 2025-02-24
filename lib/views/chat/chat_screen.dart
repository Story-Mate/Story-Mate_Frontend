import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/views/chat/quiz_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../view_models/chat/chat_controller.dart';
import 'package:storymate/views/chat/chat_bubble.dart';
import 'package:storymate/models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  WebSocketChannel? channel;
  DateTime lastMessageReceived = DateTime.now(); // 마지막 메시지 수신 시간 추적
  Timer? pingTimer;
  late int roomId;
  late String bookTitle;
  late String charactersName;
  final ChatController controller = Get.put(ChatController());
  List<dynamic> chatMessages = [];
  int answerCount = 0;

  bool isQuizButtonEnabled = false; // 퀴즈 버튼 활성화 여부
  bool hasQuizNotificationShown = false; // 퀴즈 안내 메시지 표시 여부
  bool isSendingMessage = false; // 메시지 전송 로딩 상태 변수 추가

  // Ping 전송 중인지 확인하는 플래그 추가
  bool isWaitingForPingResponse = false;

  @override
  void initState() {
    super.initState();
    roomId = Get.arguments["roomId"] ?? 0;
    bookTitle = Get.arguments["bookTitle"] ?? "";
    charactersName = Get.arguments["charactersName"] ?? "";

    debugPrint("bookTitle: $bookTitle, charactersName: $charactersName");

    if (roomId != 0) {
      // WebSocket 서버 연결
      channel = WebSocketChannel.connect(
        Uri.parse('wss://be.dev.storymate.site/chat/$roomId'),
      );

      startConnectionMonitor();

      // 메시지 수신 처리 로직
      channel!.stream.listen((message) {
        print("수신된 원본 메시지: $message");

        // Ping 응답에 대한 직접적인 수신 없음 -> 모든 수신 시점 갱신
        lastMessageReceived = DateTime.now();

        try {
          // 서버 오류 메시지 처리 및 필터링
          if (message.contains("Invalid message format")) {
            print("서버에서 필터링된 메시지 수신됨 (무시): $message");
            return; // 카운트 제외 및 출력 방지
          }

          // 일반 텍스트 메시지 처리
          var splitMessage = message.split(':');
          if (splitMessage.length < 2) return;

          String sender = splitMessage[0];
          String messageContent = splitMessage.sublist(1).join(':');

          // testUser 메시지는 화면에 출력하지 않음
          if (sender == 'testUser') {
            print("testUser 응답 수신됨, 무시됨: $messageContent");
            return;
          }

          // 일반 메시지 처리
          setState(() {
            chatMessages.add({
              'content': messageContent,
              'sender': sender,
              'isUser': false,
            });
            answerCount++;
            isSendingMessage = false; // 메시지 전송 상태 종료
          });

          // 퀴즈 버튼 활성화 처리
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

      fetchChatMessages(roomId);
    }
  }

  // Ping 메시지 전송 및 연결 유지 로직
  void startConnectionMonitor() {
    pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      Duration timeSinceLastMessage =
          DateTime.now().difference(lastMessageReceived);

      if (timeSinceLastMessage.inSeconds > 90) {
        print("서버 응답 없음 -> 웹소켓 재연결 시도");
        reconnectWebSocket();
      } else {
        sendPingMessage();
      }
    });
  }

  // Ping 메시지 전송 함수 (고유 식별자 추가)
  void sendPingMessage() {
    if (channel != null) {
      channel!.sink.add("ping");
      print("Ping 메시지 전송됨 (간단한 형식)");
    }
  }

// 웹소켓 재연결 함수
  void reconnectWebSocket() {
    // channel?.sink.close();
    channel = WebSocketChannel.connect(
      Uri.parse('wss://be.dev.storymate.site/chat/$roomId'),
    );
    print("웹소켓 재연결 완료");

    // Ping 타이머 다시 시작
    startConnectionMonitor();

    // 수신 처리 로직 다시 시작
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
          isSendingMessage = false;
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

  Future<void> fetchChatMessages(int roomId,
      {int page = 0, int size = 10}) async {
    final token = await getToken();
    if (token == null) {
      print("토큰이 없습니다. 로그인 후 다시 시도해주세요.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://be.dev.storymate.site/api/chat-messages/$roomId?page=$page&size=$size'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          chatMessages = responseData['data']['chatMessages'] ?? [];
        });
      } else {
        print("채팅 메시지 조회 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("채팅 메시지 조회 오류: $e");
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  void sendMessage(String message) {
    if (message.isEmpty) return;

    // 이미 같은 내용의 메시지가 존재하면 전송하지 않음
    if (chatMessages
        .any((msg) => msg['content'] == message && msg['isUser'] == true)) {
      print("중복 메시지 전송 시도 방지");
      return;
    }

    // 메시지 전송 시작 -> 로딩 상태 활성화
    setState(() {
      isSendingMessage = true;
    });

    String sender = "testUser";

    try {
      // WebSocket 메시지 전송
      channel?.sink.add("$sender:$roomId:$bookTitle:$message");

      // 전송 성공 시 채팅창에 메시지 추가
      setState(() {
        chatMessages.add({
          'content': message,
          'sender': 'You',
          'isUser': true,
        });
      });

      // 로그 출력
      print("메시지 전송 완료: $message");
    } catch (e) {
      print("메시지 전송 실패: $e");
    } finally {
      // 입력창 초기화
      controller.textController.clear();
      controller.update();
    }
  }

  void _showQuizLockedDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor, // 다이얼로그 배경색
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 모서리 둥글게
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 타이틀
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

              // 설명 텍스트
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

              // 확인 버튼
              ElevatedButton(
                onPressed: () {
                  Get.back(); // 다이얼로그 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, // 버튼 색상
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
        backgroundColor: AppTheme.backgroundColor, // 다이얼로그 배경색
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 모서리 둥글게
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 타이틀
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

              // 설명 텍스트
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

              // 버튼 그룹
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 나중에 도전하기 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // 다이얼로그 닫기
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400], // 버튼 색상
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
                  SizedBox(width: 16.w), // 버튼 간 간격

                  // 지금 도전하기 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // 다이얼로그 닫기
                        // 퀴즈로 이동 전 웹소켓 종료
                        channel?.sink.close();
                        pingTimer?.cancel();
                        print("퀴즈 시작 -> 웹소켓 연결 종료");

                        Get.to(() => QuizScreen(), arguments: {
                          "characterName": charactersName,
                          "bookTitle": bookTitle,
                        })!
                            .then((_) {
                          // 퀴즈 종료 후 웹소켓 재연결
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Icon(
            Icons.arrow_back_ios_new,
          ),
        ),
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        title: Text(
          "대화하기",
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
                    // 퀴즈로 이동 전 웹소켓 종료
                    channel?.sink.close();
                    pingTimer?.cancel();
                    print("퀴즈 시작 -> 웹소켓 연결 종료");

                    Get.to(() => QuizScreen(), arguments: {
                      "characterName": charactersName,
                      "bookTitle": bookTitle,
                    })!
                        .then((_) {
                      // 퀴즈 종료 후 웹소켓 재연결
                      reconnectWebSocket();
                      print("퀴즈 종료 -> 웹소켓 재연결");
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isQuizButtonEnabled
                      ? Colors.purple[400]
                      : Colors.grey[400], // 비활성화 시 회색 처리
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
              itemCount: chatMessages.length + (isSendingMessage ? 1 : 0),
              itemBuilder: (context, index) {
                if (isSendingMessage && index == chatMessages.length) {
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
          // 채팅 입력창 및 전송 버튼 비활성화 처리
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    decoration: InputDecoration(hintText: "메시지를 입력하세요"),
                    enabled: !isSendingMessage, // 입력은 가능하지만 엔터 키 동작만 비활성화
                    onSubmitted: (value) {
                      if (!isSendingMessage && value.trim().isNotEmpty) {
                        sendMessage(value); // Enter 입력 시 메시지 전송
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: isSendingMessage
                      ? null // 로딩 중일 때 버튼 비활성화
                      : () {
                          String message = controller.textController.text;
                          if (message.isNotEmpty) {
                            sendMessage(message);
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
}
