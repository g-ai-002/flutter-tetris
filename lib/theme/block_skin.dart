/// 棋盘皮肤：决定方块配色、棋盘底色与界面强调色。
enum BlockSkin {
  paper('宣纸', '朱砂松烟，原版国风'),
  celadon('青瓷', '雨过天青，温润如玉'),
  dunhuang('敦煌', '石青石绿，壁画余韵'),
  ink('水墨', '淡墨五色，留白见意');

  const BlockSkin(this.label, this.description);

  final String label;
  final String description;

  /// 读取历史偏好，未知或缺失时回到默认的宣纸皮肤。
  static BlockSkin fromName(String? name) => values.firstWhere(
    (skin) => skin.name == name,
    orElse: () => BlockSkin.paper,
  );
}
