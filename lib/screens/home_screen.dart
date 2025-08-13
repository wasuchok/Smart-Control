import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_control/core/network/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../widgets/status_item.dart';
import '../widgets/action_icon_button.dart';
import '../widgets/keypad_row.dart';
import '../widgets/lamp_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayText = '0';
  final DateTime _currentTime = DateTime.now();
  String _username = "Admin";
  List<dynamic> zones = [];
  WebSocketChannel? _channel;

  void connectWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080'), // เปลี่ยนเป็นของจริง
    );

    _channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);

          // ตรวจว่ามี field zone, stream_enabled, volume, is_playing
          if (data is Map && data.containsKey("zone")) {
            print("test test 123");

            setState(() {
              final idx = zones.indexWhere(
                (z) => z["no"] == data["zone"] || z["no"] == data["zone"],
              );

              if (idx != -1) {
                setState(() {
                  zones[idx]["status"]["stream_enabled"] =
                      data["stream_enabled"] ??
                      zones[idx]["status"]["stream_enabled"];
                  zones[idx]["status"]["volume"] =
                      data["volume"] ?? zones[idx]["status"]["volume"];
                  zones[idx]["status"]["is_playing"] =
                      data["is_playing"] ?? zones[idx]["status"]["is_playing"];
                });
              }
            });
          }
        } catch (e) {
          print("WebSocket parse error: $e");
        }
      },
      onError: (err) {
        print("WebSocket error: $err");
      },
      onDone: () {
        print("WebSocket closed, reconnecting...");
        Future.delayed(const Duration(seconds: 3), connectWebSocket);
      },
    );
  }

  void getAllZones() async {
    try {
      final api = ApiService.public();

      final result = await api.get('/device');

      setState(() {
        zones = result;
      });
    } catch (error) {
      print(error);
    }
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (value == 'clear') {
        _displayText = '0';
        return;
      }
      if (_displayText == '0') {
        _displayText = value;
      } else {
        _displayText += value;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    getAllZones();
    connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final whiteBg = Colors.white;
    final cardBg = Colors.grey[50]!;
    final accent = Colors.blue[600]!;
    final lampOn = Colors.red[600]!;
    final lampOff = Colors.grey[400]!;
    final textColor = Colors.grey[900]!;
    final shadowColor = Colors.grey.withOpacity(0.1);

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lightbulb, color: accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Smart Control',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusItem(
                            icon: Icons.access_time_filled,
                            text:
                                "${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}",
                            color: accent,
                          ),
                          const SizedBox(width: 20),
                          StatusItem(
                            icon: Icons.person_outline,
                            text: _username,
                            color: accent,
                          ),
                          const SizedBox(width: 20),
                          StatusItem(
                            icon: Icons.wifi_tethering,
                            text: "Connected",
                            color: accent,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      ActionIconButton(
                        icon: Icons.notifications_none,
                        tooltip: "การแจ้งเตือน",
                        color: textColor,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      ActionIconButton(
                        icon: Icons.settings_outlined,
                        tooltip: "ตั้งค่า",
                        color: textColor,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      ActionIconButton(
                        icon: Icons.logout_outlined,
                        tooltip: "ออกจากระบบ",
                        color: Colors.red[500]!,
                        onPressed: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: whiteBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      width: double.infinity,
                      child: Text(
                        _displayText,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    Expanded(
                      child: Column(
                        children: [
                          KeypadRow(
                            keys: const ['1', '2', '3', 'volume'],
                            onKey: _onKeyPressed,
                          ),
                          const SizedBox(height: 8),
                          KeypadRow(
                            keys: const ['4', '5', '6', 'add'],
                            onKey: _onKeyPressed,
                          ),
                          const SizedBox(height: 8),
                          KeypadRow(
                            keys: const ['7', '8', '9', 'remove'],
                            onKey: _onKeyPressed,
                          ),
                          const SizedBox(height: 8),
                          KeypadRow(
                            keys: const ['clear', '0', 'power', 'enter'],
                            onKey: _onKeyPressed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: zones.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final isOn = zones[index];
                    print(zones[index]["status"]);
                    return LampTile(
                      isOn: isOn["status"]["stream_enabled"],
                      lampOnColor: lampOn,
                      lampOffColor: lampOff,
                      zone: "โซน ${index + 1}",
                      onTap: () {
                        // setState(() {
                        //   zones[index] = !zones[index];
                        //   _onKeyPressed(
                        //     'Zone ${index + 1}: ${zones[index] ? "ACTIVE" : "OFF"}',
                        //   );
                        // });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, color: Colors.red[500]!, size: 48),
              const SizedBox(height: 16),
              Text(
                'ยืนยันการออกจากระบบ',
                style: TextStyle(
                  color: Colors.grey[900]!,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'คุณต้องการออกจากระบบใช่หรือไม่?',
                style: TextStyle(color: Colors.grey[600]!, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'ยกเลิก',
                        style: TextStyle(
                          color: Colors.grey[800]!,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[500]!,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: logout logic
                      },
                      child: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
}
