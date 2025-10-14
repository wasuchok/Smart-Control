import 'dart:convert';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

class StreamStatusService {
  void connect() {
    SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url:
          'http://110.171.195.179:8080/playlist/stream/status-sse', //110.171.195.179 public IP, 192.168.1.83 local IP
      header: {
        "Accept": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    ).listen((event) {
      print(event);
      if (event.event == 'status' && event.data != null) {
        final data = jsonDecode(event.data!);
        print("SSE status: $data");
      }
    });
  }
}
