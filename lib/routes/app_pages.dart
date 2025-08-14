import 'package:get/get.dart';
import 'package:smart_control/screens/home_screen.dart';
import 'package:smart_control/screens/song_upload/song_upload_screen.dart';

import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
    GetPage(name: AppRoutes.song_upload, page: () => const SongUploadScreen()),
  ];
}
