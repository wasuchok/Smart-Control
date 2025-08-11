import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayText = '0';
  List<bool> _switchStates = List.generate(50, (_) => false);
  final DateTime _currentTime = DateTime.now();
  String _username = "Admin";

  void _onKeyPressed(String value) {
    setState(() {
      if (_displayText == '0') {
        _displayText = value;
      } else {
        _displayText += value;
      }
    });
  }

  void _clearDisplay() {
    setState(() {
      _displayText = '0';
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
                  // Logo and Brand
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
                          _buildStatusItem(
                            Icons.access_time_filled,
                            "${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}",
                            accent,
                          ),
                          const SizedBox(width: 20),
                          _buildStatusItem(
                            Icons.person_outline,
                            _username,
                            accent,
                          ),
                          const SizedBox(width: 20),
                          _buildStatusItem(
                            Icons.wifi_tethering,
                            "Connected",
                            accent,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons
                  Row(
                    children: [
                      _buildActionButton(
                        Icons.notifications_none,
                        "การแจ้งเตือน",
                        () {},
                        textColor,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        Icons.settings_outlined,
                        "ตั้งค่า",
                        () {},
                        textColor,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        Icons.logout_outlined,
                        "ออกจากระบบ",
                        () => _showLogoutDialog(context),
                        Colors.red[500]!,
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
            // LEFT: Keypad + Display
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
                    // Display
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

                    // Keypad
                    Expanded(
                      child: Column(
                        children: [
                          _buildKeypadRow(['1', '2', '3', 'volume']),
                          const SizedBox(height: 8),
                          _buildKeypadRow(['4', '5', '6', 'add']),
                          const SizedBox(height: 8),
                          _buildKeypadRow(['7', '8', '9', 'remove']),
                          const SizedBox(height: 8),
                          _buildKeypadRow(['clear', '0', 'power', 'enter']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // RIGHT: Lamp Zones
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
                  itemCount: 50,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final isOn = _switchStates[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isOn ? lampOn : whiteBg,
                        boxShadow: [
                          BoxShadow(
                            color: isOn
                                ? lampOn.withOpacity(0.4)
                                : Colors.grey[300]!.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _switchStates[index] = !_switchStates[index];
                              _onKeyPressed(
                                'Zone ${index + 1}: ${_switchStates[index] ? "ACTIVE" : "OFF"}',
                              );
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOn
                                        ? Colors.white24
                                        : lampOff.withOpacity(0.08),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb_outlined,
                                    color: isOn ? Colors.white : lampOff,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Zone ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isOn
                                        ? Colors.white
                                        : Colors.grey[700]!,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOn
                                        ? Colors.white24
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isOn ? 'ACTIVE' : 'OFF',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isOn
                                          ? Colors.white
                                          : Colors.grey[600]!,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildStatusItem(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50]!,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    Color color,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100]!,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        // Add logout logic here
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

  Widget _buildKeypadRow(List<String> keys) {
    final Map<String, IconData> iconMap = {
      'volume': Icons.volume_up_outlined,
      'add': Icons.add,
      'remove': Icons.remove,
      'power': Icons.power_settings_new,
      'enter': Icons.keyboard_return,
      'clear': Icons.backspace_outlined,
    };

    Color bgForKey(String key) {
      if (key == 'enter') return Colors.blue[600]!;
      if (key == 'clear') return Colors.red[500]!;
      return Colors.white;
    }

    Color fgForKey(String key) {
      if (key == 'enter' || key == 'clear') return Colors.white;
      return Colors.grey[800]!;
    }

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys.map((key) {
          final isIcon = iconMap.containsKey(key);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _Keycap3D(
                label: isIcon ? null : key,
                icon: isIcon ? iconMap[key] : null,
                bgColor: bgForKey(key),
                fgColor: fgForKey(key),
                onTap: () {
                  if (key == 'clear') {
                    _clearDisplay();
                  } else {
                    _onKeyPressed(key);
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ปุ่มสไตล์ 3D: นูนขึ้น/กดแล้วจม + เงา 2 ทิศ
class _Keycap3D extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _Keycap3D({
    Key? key,
    this.label,
    this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_Keycap3D> createState() => _Keycap3DState();
}

class _Keycap3DState extends State<_Keycap3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDarkKey = widget.bgColor.computeLuminance() < 0.5;

    final topLeft = _pressed ? Colors.black12 : Colors.white.withOpacity(0.9);
    final bottomRight = _pressed
        ? Colors.white.withOpacity(0.9)
        : Colors.black26;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _pressed ? 2.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _pressed
                ? [
                    widget.bgColor.withOpacity(0.95),
                    widget.bgColor.withOpacity(0.85),
                  ]
                : [
                    widget.bgColor.withOpacity(0.98),
                    widget.bgColor.withOpacity(0.92),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: topLeft,
              offset: const Offset(-3, -3),
              blurRadius: 6,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: bottomRight,
              offset: const Offset(3, 3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: isDarkKey ? Colors.black12 : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Center(
          child: widget.icon != null
              ? Icon(widget.icon, size: 24, color: widget.fgColor)
              : Text(
                  widget.label ?? '',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: widget.fgColor,
                  ),
                ),
        ),
      ),
    );
  }
}
