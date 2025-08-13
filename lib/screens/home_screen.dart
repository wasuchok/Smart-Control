import 'dart:convert';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:smart_control/core/network/api_service.dart';
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
  double _micVolume = 0.5;
  String _zoneNumber = "";
  String _zoneType = "";
  bool _is_playing = false;

  bool _micOn = false;
  bool _liveOn = false;

  late WebSocketChannel channel;

  Future<void> getStatusZone() async {
    try {
      final api = ApiService.public();
      final result = await api.post(
        "/mqtt/publishAndWait",
        data: {"zone": "${_displayText}"},
      );

      setState(() {
        _is_playing = result['is_playing'];
        print(result);
        if (_zoneType == "volume") {
          _displayText = "${result["volume"]}";
        }
        if (_zoneType == "power") {
          setStream();
        }
      });
    } catch (error) {
      print(error);
    }
  }

  Future<void> setStream() async {
    try {
      final api = ApiService.public();
      await api.post(
        "/mqtt/publish",
        data: {
          "topic": "mass-radio/zone${_zoneNumber}/command",
          "payload": {"set_stream": !_is_playing},
        },
      );

      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.minimal,
        title: const Text('สำเร็จ'),
        description: Text(
          !_is_playing
              ? 'เปิดการใช้งานโซน $_zoneNumber'
              : 'ปิดการใช้งานโซน $_zoneNumber',
        ),
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.topRight,
        showProgressBar: true,
      );
      setState(() {
        _zoneType = "";
      });
    } catch (error) {
      print(error);
    }
  }

  void setVolume() async {
    try {
      final api = ApiService.public();
      await api.post(
        "/mqtt/publish",
        data: {
          "topic": "mass-radio/zone${_zoneNumber}/command",
          "payload": {"set_volume": _displayText},
        },
      );

      toastification.show(
        context: context,
        type: ToastificationType.success, // success | info | warning | error
        style: ToastificationStyle.minimal,
        title: const Text('สำเร็จ'),
        description: Text('ปรับเสียงสำเร็จ'),
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.topRight,
        showProgressBar: true,
      );
    } catch (error) {
      print(error);
    }
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

  void connectWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080'));

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data["zone"] != null) {
        final idx = zones.indexWhere(
          (z) => z["no"] == data["zone"] || z["no"] == data["zone"],
        );
        if (idx != -1) {
          setState(() {
            zones[idx]["status"]["stream_enabled"] = data["stream_enabled"];
            zones[idx]["status"]["volume"] = data["volume"];
            zones[idx]["status"]["is_playing"] = data["is_playing"];
          });
        }
      }
    });
  }

  void _toggleMic() {
    setState(() {
      _micOn = !_micOn;
    });
    print("ไมโครโฟน: ${_micOn ? 'เปิด' : 'ปิด'}");
  }

  void _toggleLive() {
    setState(() {
      _liveOn = !_liveOn;
    });
    print("ถ่ายทอดสด: ${_liveOn ? 'เริ่ม' : 'หยุด'}");
  }

  Widget _buildCircularToggleButton({
    required bool isActive,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String activeLabel,
    required String inactiveLabel,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isActive ? activeColor : inactiveColor).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? activeColor : inactiveColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isActive ? activeLabel : inactiveLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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
              child: _buildKeypad(cardBg, whiteBg, textColor, shadowColor),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildCircularToggleButton(
                          isActive: _micOn,
                          activeIcon: Icons.mic,
                          inactiveIcon: Icons.mic_off,
                          activeLabel: "ปิดไมค์",
                          inactiveLabel: "เปิดไมค์",
                          activeColor: Colors.green,
                          inactiveColor: Colors.red,
                          onTap: _toggleMic,
                        ),
                        const SizedBox(width: 20),
                        _buildCircularToggleButton(
                          isActive: _liveOn,
                          activeIcon: Icons.live_tv,
                          inactiveIcon: Icons.live_tv_outlined,
                          activeLabel: "หยุดถ่ายทอด",
                          inactiveLabel: "เริ่มถ่ายทอด",
                          activeColor: Colors.red,
                          inactiveColor: Colors.blue,
                          onTap: _toggleLive,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.volume_down),
                              Expanded(
                                child: Slider(
                                  value: _micVolume,
                                  onChanged: (value) {
                                    setState(() => _micVolume = value);
                                    print("ปรับเสียงไมค์: $value");
                                  },
                                ),
                              ),
                              const Icon(Icons.volume_up),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: GridView.builder(
                        itemCount: zones.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemBuilder: (context, index) {
                          final isOn = zones[index];
                          return LampTile(
                            isOn: isOn["status"]["stream_enabled"],
                            lampOnColor: lampOn,
                            lampOffColor: lampOff,
                            zone: "โซน ${index + 1}",
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(
    Color cardBg,
    Color whiteBg,
    Color textColor,
    Color shadowColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 8, spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Future<void> _onKeyPressed(String value) async {
    setState(() {
      if (value == 'clear') {
        _displayText = '0';
        _zoneType = '';
        return;
      }

      if (_zoneType == 'volume') {
        if (int.tryParse(value) != null) {
          final newValue = _displayText == '0' ? value : _displayText + value;

          final numValue = int.parse(newValue);
          if (numValue > 21) {
            print('⚠️ ไม่สามารถตั้งค่าเสียงเกิน 21 ได้');
            return;
          }
        }
      }

      if (_zoneType != "volume" && (value == "add" || value == "remove")) {
        return;
      }

      if (value == 'add') {
        final current = int.parse(_displayText);
        if (_zoneType == 'volume' && current >= 21) {
          print('⚠️ ไม่สามารถตั้งค่าเสียงเกิน 21 ได้');
          return;
        }
        _displayText = (current + 1).toString();
        return;
      }

      if (value == 'remove') {
        final current = int.parse(_displayText);
        if (_zoneType == 'volume' && current <= 1) {
          print('⚠️ ไม่สามารถตั้งค่าเสียงต่ำกว่า 1 ได้');
          return;
        }
        _displayText = (current - 1).toString();
        return;
      }

      if (value == 'volume') {
        final zoneValue = int.tryParse(_displayText);
        if (zoneValue == null || zoneValue <= 0 || zoneValue > zones.length) {
          toastification.show(
            context: context,
            type:
                ToastificationType.warning, // success | info | warning | error
            style: ToastificationStyle.minimal,
            title: const Text('คำเตือน'),
            description: Text('กรุณาเลือกโซนที่ถูกต้อง (1-${zones.length})'),
            autoCloseDuration: const Duration(seconds: 3),
            alignment: Alignment.topRight,
            showProgressBar: true,
          );

          return;
        }
        _zoneNumber = _displayText;
        _zoneType = 'volume';
        getStatusZone();
        return;
      }

      if (value == "power") {
        _zoneType = "power";
        final zoneValue = int.tryParse(_displayText);
        if (zoneValue == null || zoneValue <= 0 || zoneValue > zones.length) {
          toastification.show(
            context: context,
            type: ToastificationType.warning,
            style: ToastificationStyle.minimal,
            title: const Text('คำเตือน'),
            description: Text('กรุณาเลือกโซนที่ถูกต้อง (1-${zones.length})'),
            autoCloseDuration: const Duration(seconds: 3),
            alignment: Alignment.topRight,
            showProgressBar: true,
          );
          return;
        }
        _zoneNumber = _displayText;
        getStatusZone();
        _displayText = "0";
        return;
      }

      if (value == "enter") {
        if (_zoneType == "volume") {
          setState(() {
            setVolume();
            _zoneType = "";
            _displayText = "0";
          });
        }

        return;
      }

      if (_displayText == '0') {
        _displayText = value;
      } else if (value == 'enter') {
        _displayText = '0';
      } else {
        _displayText += value;
      }
    });
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
