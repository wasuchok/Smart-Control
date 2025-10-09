import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

class MicPage extends StatefulWidget {
  const MicPage({super.key});

  @override
  State<MicPage> createState() => _MicPageState();
}

class _MicPageState extends State<MicPage> {
  final _recorder = AudioRecorder();

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _micSub;
  StreamSubscription? _wsSub;
  Completer<void>? _wsDone;
  bool _isRecording = false;
  bool _isStopping = false;
  String _statusLog = "รอเริ่มต้น...";
  int _dataCount = 0;

  double tailSeconds = 0.6;
  static const int sampleRate = 44100;
  static const int channels = 2;
  static const int bitsPerSample = 16;

  @override
  void initState() {
    super.initState();
    _log('📱 MicPage โหลดแล้ว - พร้อมใช้งาน');
    print('==================================================');
    print('🎤 MIC PAGE LOADED - DEBUG MODE');
    print('==================================================');
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] 🎤 $message';
    print(logMessage);
    debugPrint(logMessage); // เพิ่ม debugPrint ด้วย
    if (mounted) {
      setState(() => _statusLog = message);
    }
  }

  Future<void> _startRecording() async {
    _log('🔵 กดปุ่ม Start - เริ่มฟังก์ชัน _startRecording');

    if (_isRecording || _isStopping) {
      _log(
        '⚠️ กำลังทำงานอยู่แล้ว (recording:$_isRecording, stopping:$_isStopping)',
      );
      return;
    }

    try {
      // ตรวจสอบ permission
      _log('🔐 กำลังขอสิทธิ์ไมโครโฟน...');
      final hasPermission = await _recorder.hasPermission();
      _log('🔐 ผลการขอสิทธิ์: ${hasPermission ? "✅ อนุญาต" : "❌ ไม่อนุญาต"}');

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ไม่มีสิทธิ์เข้าถึงไมโครโฟน')),
          );
        }
        return;
      }

      // ปิดการเชื่อมต่อเก่าก่อน (ถ้ามี)
      _log('🧹 ทำความสะอาดการเชื่อมต่อเก่า...');
      await _cleanupConnections();

      // สร้าง WebSocket ใหม่
      _log('🌐 กำลังเชื่อมต่อ WebSocket: ws://192.168.1.83:8080/ws/mic');
      _channel = IOWebSocketChannel.connect("ws://192.168.1.83:8080/ws/mic");
      _log('🌐 สร้าง WebSocket channel แล้ว');

      _wsDone = Completer<void>();
      _wsSub = _channel!.stream.listen(
        (msg) {
          _log('📥 รับข้อความจาก Server: $msg');
        },
        onError: (error) {
          _log('❌ WebSocket Error: $error');
          if (!(_wsDone?.isCompleted ?? true)) _wsDone?.complete();
        },
        onDone: () {
          _log('🔴 WebSocket ปิดการเชื่อมต่อ');
          if (!(_wsDone?.isCompleted ?? true)) _wsDone?.complete();
        },
        cancelOnError: true,
      );
      _log('✅ WebSocket Listener เริ่มทำงาน');

      // เริ่ม stream ไมค์
      _log('🎤 กำลังเริ่ม Audio Stream (${sampleRate}Hz, ${channels}ch)...');
      _dataCount = 0;

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: channels,
        ),
      );
      _log('🎤 ได้ Audio Stream แล้ว');

      _micSub = stream.listen(
        (data) {
          _dataCount++;
          final ch = _channel;
          if (ch == null) {
            _log('⚠️ Channel เป็น null ไม่สามารถส่งข้อมูลได้');
            return;
          }

          // ส่งข้อมูลเสียงไปยัง WebSocket
          try {
            ch.sink.add(data);

            // แสดง log ทุก 50 packets
            if (_dataCount % 50 == 0) {
              _log(
                '📤 ส่งข้อมูล: $_dataCount packets (${data.length} bytes/packet)',
              );
            }
          } catch (e) {
            _log('❌ ส่งข้อมูลไม่สำเร็จ: $e');
          }
        },
        onError: (error) {
          _log('❌ Mic Stream Error: $error');
        },
        onDone: () {
          _log('🔴 Mic Stream จบแล้ว');
        },
      );
      _log('✅ Mic Stream Listener เริ่มทำงาน');

      setState(() => _isRecording = true);
      _log('✅✅✅ เริ่มบันทึกเสียงสำเร็จ! กำลังส่งข้อมูล...');
    } catch (e, stackTrace) {
      _log('❌❌❌ เกิดข้อผิดพลาด: $e');
      print('Stack trace: $stackTrace');
      await _cleanupConnections();
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เริ่มบันทึกไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _cleanupConnections() async {
    _log('🧹 เริ่มทำความสะอาด...');

    if (_micSub != null) {
      try {
        await _micSub?.cancel();
        _log('✅ ยกเลิก mic subscription');
      } catch (e) {
        _log('⚠️ ยกเลิก micSub error: $e');
      }
      _micSub = null;
    }

    if (_wsSub != null) {
      try {
        await _wsSub?.cancel();
        _log('✅ ยกเลิก ws subscription');
      } catch (e) {
        _log('⚠️ ยกเลิก wsSub error: $e');
      }
      _wsSub = null;
    }

    if (_channel != null) {
      try {
        await _channel?.sink.close(1001, 'cleanup');
        _log('✅ ปิด WebSocket channel');
      } catch (e) {
        _log('⚠️ ปิด channel error: $e');
      }
      _channel = null;
    }

    _wsDone = null;
    _log('✅ ทำความสะอาดเสร็จสิ้น');
  }

  Future<void> _flushSilenceTail(double seconds) async {
    final ch = _channel;
    if (ch == null || seconds <= 0) return;

    final int bytesPerSecond = sampleRate * channels * (bitsPerSample ~/ 8);
    const int chunkMs = 40;
    final int chunkBytes = ((bytesPerSecond * chunkMs) / 1000).round();
    final Uint8List silenceChunk = Uint8List(chunkBytes);
    final int totalChunks = ((seconds * 1000) / chunkMs).ceil();

    for (int i = 0; i < totalChunks; i++) {
      ch.sink.add(silenceChunk);
      await Future.delayed(const Duration(milliseconds: chunkMs));
    }

    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isStopping) return;
    _isStopping = true;

    try {
      _log('🛑 กำลังหยุดบันทึก... (ส่งไปแล้ว $_dataCount packets)');

      await _micSub?.cancel();
      _micSub = null;
      _log('✅ หยุด mic stream');

      await _recorder.stop();
      _log('✅ หยุด recorder');

      await _flushSilenceTail(tailSeconds);
      _log('✅ ส่ง silence tail');

      final closeFuture = _channel?.sink.close(1000, 'normal');
      if (closeFuture is Future) {
        await closeFuture.catchError((_) {});
      }
      _log('✅ ปิด WebSocket');

      if (_wsDone != null && !(_wsDone!.isCompleted)) {
        await Future.any([
          _wsDone!.future,
          Future.delayed(const Duration(seconds: 1)),
        ]);
      }

      await _wsSub?.cancel();
      _wsSub = null;
      _wsDone = null;
      _channel = null;

      _log('✅✅✅ หยุดบันทึกสำเร็จ');
    } catch (e) {
      _log('❌ หยุดบันทึกเกิดข้อผิดพลาด: $e');
    } finally {
      setState(() {
        _isRecording = false;
        _isStopping = false;
      });
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    _micSub?.cancel();
    _wsSub?.cancel();
    _recorder.dispose();
    _channel?.sink.close(1001, 'disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 MicPage build - isRecording: $_isRecording');
    final btnText = _isRecording
        ? (_isStopping ? "Stopping..." : "Stop")
        : "Start Mic";
    return Scaffold(
      appBar: AppBar(title: const Text("Mic Stream")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text("หน่วงก่อนปิด (วินาที): "),
                Expanded(
                  child: Slider(
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    value: tailSeconds,
                    label: tailSeconds.toStringAsFixed(2),
                    onChanged: _isRecording || _isStopping
                        ? null
                        : (v) => setState(() => tailSeconds = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isStopping
                  ? null
                  : (_isRecording
                        ? _stopRecording
                        : () {
                            print('👆 ปุ่ม Start Mic ถูกกด!');
                            _startRecording();
                          }),
              child: Text(btnText),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.green[50] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isRecording ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isRecording ? Icons.mic : Icons.mic_off,
                        color: _isRecording ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'สถานะ:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_statusLog, style: const TextStyle(fontSize: 12)),
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '📤 ส่งแล้ว: $_dataCount packets',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "ดู Debug Console (VS Code) เพื่อดู log ทั้งหมด",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            const Text(
              "ถ้าสตรีม mono ให้เปลี่ยน numChannels=1 ทั้งฝั่งนี้และฝั่งรับ เพื่อกันบัฟเฟอร์เพี้ยน",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
