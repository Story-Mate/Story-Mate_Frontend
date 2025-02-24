import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/services/api_service.dart';
import '../../../components/custom_bottom_bar.dart';
import '../../../routes/app_routes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// RouteObserver를 사용하기 위한 글로벌 선언
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen>
    with RouteAware {
  final TextEditingController searchController = TextEditingController();
  final _apiService = ApiService();
  var messageCount = 0.obs;

  // 기존 하드코딩된 캐릭터 데이터 유지
  final List<Map<String, dynamic>> localCharacters = [
    {
      "id": 1,
      "name": "김첨지",
      "book": "운수좋은날",
      "image": "assets/characters/ch.1-1.png"
    },
    {
      "id": 2,
      "name": "인어공주",
      "book": "인어공주",
      "image": "assets/characters/ch.2-1.png"
    },
    {
      "id": 3,
      "name": "성냥팔이소녀",
      "book": "성냥팔이소녀",
      "image": "assets/characters/ch.3-1.png"
    },
    {
      "id": 4,
      "name": "심청",
      "book": "심봉사",
      "image": "assets/characters/ch.4-1.png"
    },
    {
      "id": 5,
      "name": "심봉사",
      "book": "심봉사",
      "image": "assets/characters/ch.5-1.png"
    },
    {
      "id": 6,
      "name": "엄지공주",
      "book": "엄지공주",
      "image": "assets/characters/ch.6-1.png"
    },
    {
      "id": 7,
      "name": "점순이",
      "book": "동백꽃",
      "image": "assets/characters/ch.7-1.png"
    },
    {
      "id": 8,
      "name": "화자",
      "book": "동백꽃",
      "image": "assets/characters/ch.8-1.png"
    },
    {
      "id": 9,
      "name": "시골쥐",
      "book": "시골쥐서울구경",
      "image": "assets/characters/ch.9-1.png"
    },
    {
      "id": 10,
      "name": "미운아기오리",
      "book": "미운아기오리",
      "image": "assets/characters/ch.10-1.png"
    },
    {
      "id": 11,
      "name": "허생원",
      "book": "메밀꽃필무렵",
      "image": "assets/characters/ch.11-1.png"
    },
    {
      "id": 12,
      "name": "화자",
      "book": "날개",
      "image": "assets/characters/ch.12-1.png"
    },
  ];

  List<Map<String, dynamic>> filteredCharacters = [];

  @override
  void initState() {
    super.initState();
    filteredCharacters = List.from(localCharacters);
    fetchUserInfo();
  }

  // RouteObserver 구독 및 해제
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 화면이 다시 활성화될 때 호출
  @override
  void didPopNext() {
    fetchUserInfo(); // 사용자가 다른 화면에서 돌아왔을 때 메시지 카운트 업데이트
  }

  // 검색 기능 추가
  void filterCharacters(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCharacters = List.from(localCharacters);
      } else {
        filteredCharacters = localCharacters
            .where((character) =>
                (character["name"]?.contains(query) ?? false) ||
                (character["book"]?.contains(query) ?? false))
            .toList();
      }
    });
  }

  //이전 대화 보기
  void ChatHistory() {
    Get.toNamed(AppRoutes.CHAT_HISTORY);
  }

  // 채팅방 생성 (POST /api/chat-rooms)
  Future<void> createChatRoom(
      String title, int characterId, String bookTitle) async {
    print(
        "채팅방 생성 요청: title=$title, characterId=$characterId, bookTitle=$bookTitle");

    // 토큰 가져오기
    final token = await getToken();
    if (token == null) {
      print("토큰이 없습니다. 로그인 후 다시 시도해주세요.");
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

      //  UTF-8 강제 변환
      String decodedResponse = utf8.decode(response.bodyBytes);
      final responseData = json.decode(decodedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(decodedResponse);
        int roomId = responseData['data']['roomId']; // 서버에서 받은 roomId
        String bookTitle =
            responseData['data']['bookTitle']; // 서버에서 받은 bookTitle
        String charactersName =
            responseData['data']['charactersName']; // 서버에서 받은 캐릭터 이름

        //  한글 깨짐 방지: UTF-8 변환
        bookTitle = utf8.decode(utf8.encode(bookTitle));

        print("서버 응답: $responseData");
        print(
            "채팅방 생성 성공, roomId: $roomId, bookTitle: $bookTitle, charactersName: $charactersName");

        //  채팅방 생성 후 화면 이동
        Get.toNamed(AppRoutes.CHAT, arguments: {
          "roomId": roomId,
          "bookTitle": bookTitle,
          "charactersName": charactersName,
        });

        //  WebSocket 연결
        // connectToWebSocket(roomId);
      } else {
        print("채팅방 생성 실패: ${response.statusCode}");
        print("서버 응답: $decodedResponse");
      }
    } catch (e) {
      print("채팅방 생성 중 오류 발생: $e");
    }
  }

  // // WebSocket 연결 함수
  // void connectToWebSocket(int roomId) {
  //   // WebSocket 연결 URL은 roomId를 사용하여 연결
  //   final channel = WebSocketChannel.connect(
  //     Uri.parse('wss://be.dev.storymate.site/chat/$roomId'),
  //   );

  //   // WebSocket 수신 처리
  //   channel.stream.listen((message) {
  //     print('Received message: $message');
  //     // 추가적인 메시지 처리 로직
  //   });
  // }

  // 토큰을 SharedPreferences에서 불러오기
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken'); // accessToken 가져오기
  }

  /// 회원 정보 조회 API 호출
  Future<void> fetchUserInfo() async {
    try {
      final userData = await _apiService.fetchUserInfo();

      if (userData != null) {
        messageCount.value = userData["messageCount"] ?? 0;

        print("회원 정보 조회 성공: 메시지 개수=${messageCount.value}");
      } else {
        print("회원 정보 조회 실패");
      }
    } catch (e) {
      print("회원 정보 조회 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.purple[50],
        elevation: 0,
        title: Text(
          '작품 속 인물과 이야기를 나눠보세요!',
          style: TextStyle(
            fontFamily: 'Jua',
            color: Colors.black,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 20.w,
                  ),
                  SizedBox(
                    width: 5.w,
                  ),
                  Obx(
                    () => Text(
                      '${messageCount.value}',
                      style: TextStyle(
                        fontFamily: 'Jua',
                        fontSize: 15.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: searchController,
              onChanged: (query) => filterCharacters(query),
              decoration: InputDecoration(
                  hintText: "인물/작품으로 검색",
                  hintStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.normal,
                  ),
                  suffixIcon: Icon(Icons.search, color: Color(0xFF9B9FD0)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 15.0,
                  )),
            ),
          ),

          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 0.8,
                crossAxisCount: 3,
                crossAxisSpacing: 9.w,
                mainAxisSpacing: 15.h,
              ),
              itemCount: filteredCharacters.length,
              itemBuilder: (context, index) {
                final character = filteredCharacters[index];

                return GestureDetector(
                  onTap: () {
                    print("캐릭터 선택됨: ${character["id"]},ID: ${character["id"]}");
                    createChatRoom(
                        character["name"], character["id"], character["book"]);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: character["image"] != null
                              ? AssetImage(character["image"]!)
                              : null,
                          child: character["image"] == null
                              ? Text(
                                  character["name"]![0],
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    color: Colors.black,
                                    fontFamily: 'Jua',
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        character["name"]!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontFamily: 'Jua',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        character["book"]!,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontFamily: 'Jua',
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 5.h),
                    ],
                  ),
                );
              },
            ),
          ), //  "이전 대화 보기" 버튼 추가
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.CHAT_ROOM_LIST);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                backgroundColor: Colors.grey[200], // 버튼 색상
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "이전 대화 보기",
                style: TextStyle(
                    fontFamily: 'Jua',
                    color: Colors.black,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(currentIndex: 0),
    );
  }
}
