/// 历史记录服务：按平台选择实现——IO 落盘 JSON 文件，Web 存入浏览器本地存储。
library;

export '../models/game_record.dart';
export 'history_service_io.dart'
    if (dart.library.js_interop) 'history_service_web.dart';
