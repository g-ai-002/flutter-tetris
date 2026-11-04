/// Web 端没有可写的用户目录，日志只保留在内存。
class FileSystemService {
  FileSystemService._();

  static final FileSystemService instance = FileSystemService._();

  Future<String> getLogRootPath() async => '';

  Future<bool> openDirectory(String path) async => false;
}
