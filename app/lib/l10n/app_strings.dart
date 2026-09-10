import 'package:flutter/widgets.dart';

final class AppStrings {
  const AppStrings._(this.isChinese);

  final bool isChinese;

  static const supportedLocales = <Locale>[
    Locale('en', 'US'),
    Locale('zh', 'CN'),
  ];

  static AppStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return AppStrings._(locale?.languageCode == 'zh');
  }

  String text(String english) {
    if (!isChinese) {
      return english;
    }
    return _zhCn[english] ?? english;
  }

  String dataVersion(int version) =>
      isChinese ? '数据 v$version' : 'Data v$version';

  String errorCode(String code) =>
      isChinese ? '错误代码：$code' : 'Error code: $code';

  String power(Object value) => isChinese ? '威力 $value' : 'Power $value';

  String revision(String source, int revision) =>
      isChinese ? '$source — 版本 $revision' : '$source — revision $revision';

  String updated(String timestamp) =>
      isChinese ? '更新于 $timestamp' : 'Updated $timestamp';

  String handbookEntry(String id) =>
      isChinese ? '图鉴条目 · $id' : 'Handbook entry · $id';

  String catalogInstalled(int version) =>
      isChinese ? '图鉴数据 $version 已安装。' : 'Catalog data $version installed.';

  String catalogRestoreFailed(String code) =>
      isChinese ? '恢复图鉴失败（$code）。' : 'Catalog restore failed ($code).';

  String seasonName(int season) => switch (season) {
    1 => '暗夜拾光',
    2 => '狂欢怪谈',
    3 => '铅字幻梦',
    _ => '月涌狂想',
  };

  String catalogUpdateFailed(String code) => isChinese
      ? '图鉴更新失败（$code），当前图鉴未改变。'
      : 'Catalog update failed ($code). Current Catalog unchanged.';

  String downloadCatalogTitle(int version) =>
      isChinese ? '下载图鉴数据 $version？' : 'Download Catalog data $version?';

  String downloadCatalogBody(String bytes) => isChinese
      ? '将使用当前网络连接下载 $bytes。完整图鉴会在安装前完成校验；收藏、收集标记和笔记都会保留。'
      : 'Download $bytes using the current network connection. The complete Catalog is verified before installation. Favorites, collection marks, and notes are kept.';

  String catalogSummary(int dataVersion, int schemaVersion) => isChinese
      ? '数据 $dataVersion · 结构 $schemaVersion'
      : 'Data $dataVersion · Schema $schemaVersion';

  String downloadingProgress(String received, String total) => isChinese
      ? '正在下载 $received / $total……'
      : 'Downloading $received of $total...';

  String favoriteLabel(String objectLabel, {required bool remove}) {
    if (isChinese) {
      return '${remove ? '取消收藏' : '收藏'} $objectLabel';
    }
    return '${remove ? 'Remove' : 'Add'} $objectLabel favorite';
  }

  static const _zhCn = <String, String>{
    'Roco World Handbook': '洛克王国：世界图鉴',
    'Roco Handbook': '洛克王国：世界图鉴',
    'About this Catalog': '关于图鉴数据',
    'Data version': '数据版本',
    'Catalog schema': '图鉴数据库结构',
    'Snapshot': '数据快照',
    'Built': '构建时间',
    'Source revision range': '数据源版本范围',
    'Coverage': '收录范围',
    'Description Note Definitions': '说明术语释义',
    'Evolutions': '进化关系',
    'Pets': '精灵',
    'Skill Stone Topics': '技能石课题',
    'Topic Rewards': '课题奖励',
    'Included': '已收录',
    'Not included': '未收录',
    'Attribution': '数据来源',
    'Catalog information': '图鉴信息',
    'Creatures': '精灵',
    'Skills': '技能',
    'My Library': '我的收藏',
    'Tools': '工具',
    'Preparing the offline Catalog': '正在准备离线图鉴',
    'Preparing the offline Catalog...': '正在准备离线图鉴……',
    'No download is required.': '无需下载。',
    'Your personal library could not be opened.': '无法打开你的个人收藏。',
    'The offline Catalog could not be opened.': '无法打开离线图鉴。',
    'The existing personal database was preserved. Correct the storage problem, then try again.':
        '现有个人数据已保留。请解决存储问题后重试。',
    'Your personal data was not changed. Try preparing the bundled Catalog again.':
        '个人数据未改变。请重新准备 App 内置图鉴。',
    'Try again': '重试',
    'Search creatures': '搜索精灵',
    'Name, title, alias, or number': '名称、称号、别名或编号',
    'Clear search': '清除搜索',
    'Handbook': '图鉴',
    'All forms': '全部形态',
    'Sort': '排序',
    'Handbook number': '图鉴编号',
    'Name': '名称',
    'Types': '系别',
    'Filters': '筛选',
    'Attack, high to low': '物攻从高到低',
    'Magic attack, high to low': '魔攻从高到低',
    'Speed, high to low': '速度从高到低',
    'Search results show concrete forms so a matching form opens directly.':
        '搜索结果会显示具体形态，点击后可直接打开对应形态。',
    'Physical attack': '物攻',
    'Magic attack': '魔攻',
    'Speed': '速度',
    'Filter by type': '按系别筛选',
    'Creature filters': '精灵筛选',
    'Creature type': '精灵系别',
    'Creature stage': '精灵阶数',
    'Creature form': '精灵形态',
    'Main form': '主形态',
    'Regional form': '地区形态',
    'Owning season': '归属赛季',
    'Has shiny': '有异色',
    'No shiny': '无异色',
    'A creature may match any selected type.': '精灵符合任一已选系别即可显示。',
    'Clear': '清除',
    'Apply': '应用',
    'Creature types could not be loaded.': '无法加载精灵系别。',
    'No creatures match this search.': '没有符合条件的精灵。',
    'Clear search and filters': '清除搜索和筛选',
    'Loading...': '加载中……',
    'Load more': '加载更多',
    'The local Catalog query failed.': '本地图鉴查询失败。',
    'Creature details': '精灵详情',
    'Displayed form': '当前形态',
    'Default form': '默认形态',
    'Form not provided': '未提供形态',
    'Basic information': '基本信息',
    'Base stats': '种族资质',
    'Total base stats': '种族资质总和',
    'Type relationships': '属性克制',
    'Incoming damage increased': '受到伤害增加',
    'Incoming damage reduced': '受到伤害降低',
    'Strong against': '克制',
    'Resisted by': '被抵抗',
    'Normal damage': '无特殊倍率',
    'Feature': '特性',
    'Feature relationship': '特性关系',
    'Pet skills': '精灵技能',
    'Bloodline effects': '血脉影响',
    'Learnable skills': '可学技能',
    'Filter skills': '筛选技能',
    'Skill type': '技能类型',
    'Skill tags': '技能标签',
    'Skill element': '技能属性',
    'Skill filters': '技能筛选',
    'Skill handbook': '技能图鉴',
    'No skills match these filters.': '没有符合筛选条件的技能。',
    'No learning source is provided.': '未提供学习来源。',
    'Evolution': '进化',
    'My library': '我的收藏',
    'Source': '数据源',
    'Not provided': '未提供',
    'Creature favorite': '已收藏此精灵',
    'Add creature favorite': '收藏此精灵',
    'The collection mark applies to this handbook entry, not to every form.':
        '收集标记仅应用于此图鉴条目，不代表已收集全部形态。',
    'No evolution group is provided.': '未提供进化关系。',
    'Related group members; direction is not provided:': '相关进化组成员（未提供进化方向）：',
    'Source reference not provided.': '未提供数据源引用。',
    'Creature details could not be loaded.': '无法加载精灵详情。',
    'Class': '类别',
    'Stage': '阶段',
    'First stage': '一阶段',
    'Second stage': '二阶段',
    'Third stage': '三阶段',
    'Lord form': '首领形态',
    'Stage not provided': '未提供阶段',
    'Height': '身高',
    'Weight': '体重',
    'Starlight': '星光值',
    'Review gold': '回顾洛克贝',
    'Double ride': '双人骑乘',
    'Shiny form': '异色形态',
    'Original form': '原始形态',
    'Lord evolution': '首领进化',
    'Yes': '是',
    'No': '否',
    'Unknown': '未知',
    'HP': '生命',
    'Attack': '物攻',
    'Defense': '物防',
    'Magic defense': '魔防',
    'Search skills': '技能查询',
    'Skill name': '技能名称',
    'All': '全部',
    'Features': '特性',
    'Learnable': '可学习',
    'No skills match this search.': '没有符合条件的技能。',
    'Details not provided': '未提供详情',
    'Skill details': '技能详情',
    'Skill details could not be loaded.': '无法加载技能详情。',
    'Values': '数值',
    'Element': '系别',
    'Category': '分类',
    'Energy': '耗能',
    'Power': '威力',
    'Unlock': '解锁',
    'Target': '目标',
    'Glossary definitions are not included': '暂未收录术语释义',
    'The original description is available, but referenced glossary definitions are not part of this Catalog.':
        '已保留原始说明，但其中引用的术语释义暂未纳入此图鉴。',
    'Creatures with this feature': '拥有此特性的精灵',
    'Creatures that can learn this skill': '可学习此技能的精灵',
    'No creature relationship is provided.': '未提供关联精灵。',
    'Skill favorite': '已收藏此技能',
    'Add skill favorite': '收藏此技能',
    'Skill': '技能',
    'Creature': '精灵',
    'Handbook entry': '图鉴条目',
    'Settings': '设置',
    'Offline tools': '离线工具',
    'Explore the Catalog from new angles.': '从更多角度查阅图鉴。',
    'Season archive': '赛季档案',
    'Browse creatures by their stored season.': '按图鉴中的归属赛季查看精灵。',
    'Feature handbook': '特性图鉴',
    'Browse every source-backed creature feature.': '查看已收录的精灵特性。',
    'Egg groups': '孵蛋组别',
    'Find creatures that share an egg group.': '查看同一孵蛋组别的精灵。',
    'Game descriptions': '游戏描述',
    'Browse source terminology and descriptions.': '查阅游戏术语与描述。',
    'Game description handbook': '游戏描述图鉴',
    'Read statuses, marks, weather, and battle rules.': '查阅状态、印记、天气与战斗规则。',
    'Search game descriptions': '搜索游戏描述',
    'descriptions': '条描述',
    'Status': '状态',
    'Mark': '印记',
    'Weather': '天气',
    'Battle action': '战斗动作',
    'Battle rule': '战斗规则',
    'Other': '其他',
    'Game description data could not be loaded.': '无法加载游戏描述图鉴。',
    'No game descriptions match these filters.': '没有符合筛选条件的游戏描述。',
    'Game description': '游戏内介绍',
    'Related features': '关联特性',
    'Related skills': '关联技能',
    'No related features are included.': '当前图鉴没有关联特性。',
    'No related skills are included.': '当前图鉴没有关联技能。',
    'Event timeline': '活动时间轴',
    'Review activities on a chronological timeline.': '按时间轴查看活动。',
    'Activity timeline could not be loaded.': '无法加载活动时间轴。',
    'Previous month': '上个月',
    'Next month': '下个月',
    'This month': '本月',
    'activities': '项活动',
    'No activities are scheduled for this month.': '这个月没有已收录的活动。',
    'day': '日',
    'Active': '进行中',
    'Upcoming': '即将开始',
    'Ended': '已结束',
    'Undated': '日期待定',
    'Activity time': '活动时间',
    'Activity category': '活动分类',
    'Not announced': '尚未公开',
    'Summary': '简介',
    'Activity details': '活动详情',
    'Date not announced': '日期尚未公开',
    'Until': '截止至',
    'From': '开始于',
    'Outfit inspiration': '穿搭灵感',
    'Browse source-backed outfit ideas.': '浏览图鉴收录的穿搭灵感。',
    'Outfit catalog could not be loaded.': '无法加载时装图鉴。',
    'Search outfits': '搜索时装',
    'Female': '女款',
    'Male': '男款',
    'outfits': '套时装',
    'No outfits match these filters.': '没有符合筛选条件的时装。',
    'Quality': '品质',
    'pieces': '件',
    'Outfit description': '时装描述',
    'How to obtain': '获取方式',
    'Personal library': '个人收藏',
    'Open favorites, collection marks, and notes.': '查看收藏、收集标记和笔记。',
    'Catalog tool': '图鉴工具',
    'Personal tool': '个人工具',
    'Creatures in this season': '本赛季精灵',
    'No creatures are included for this season yet.': '当前图鉴尚未收录本赛季精灵。',
    'Feature handbook could not be loaded.': '无法加载特性图鉴。',
    'Egg groups could not be loaded.': '无法加载孵蛋组别。',
    'No creatures are included in this egg group.': '当前图鉴未收录该孵蛋组别的精灵。',
    'members': '只精灵',
    'Undiscovered': '未发现',
    'Giant Spirit Group': '巨灵组',
    'Amphibious Group': '两栖组',
    'Insect Group': '昆虫组',
    'Sky Group': '天空组',
    'Animal Group': '动物组',
    'Fairy Group': '妖精组',
    'Plant Group': '植物组',
    'Humanoid Group': '拟人组',
    'Soft-bodied Group': '软体组',
    'Earth Group': '大地组',
    'Magic Group': '魔力组',
    'Ocean Group': '海洋组',
    'Flying Dragon Group': '飞龙组',
    'Mechanical Group': '机械组',
    'Theme': '主题',
    'Follow device setting': '跟随设备设置',
    'Personal data': '个人数据',
    'Favorites, collection marks, and notes stay on this device. Uninstalling the App may remove them.':
        '收藏、收集标记和笔记仅保存在此设备上；卸载 App 可能会移除这些数据。',
    'Catalog updates': '图鉴更新',
    'Checks are started only by you. This App does not check, download, or install Catalog data in the background.':
        '仅在你主动操作时检查更新；App 不会在后台检查、下载或安装图鉴数据。',
    'Check for Catalog update': '检查图鉴更新',
    'Cancel': '取消',
    'Catalog recovery': '图鉴恢复',
    'Restore the complete read-only Catalog shipped with this App. Personal data is stored separately and is not removed.':
        '恢复 App 内置的完整只读图鉴；个人数据独立保存，不会被移除。',
    'Restore bundled Catalog': '恢复内置图鉴',
    'About': '关于',
    'App version': 'App 版本',
    'Catalog': '图鉴',
    'Last Catalog action': '最近图鉴操作',
    'Personal database schema': '个人数据库结构',
    'Catalog built': '图鉴构建时间',
    'Open-source licenses': '开源许可',
    'Flutter and packaged dependencies': 'Flutter 与打包依赖',
    'Catalog is up to date.': '图鉴已是最新版本。',
    'Checking for a Catalog update...': '正在检查图鉴更新……',
    'Verifying and installing...': '正在校验并安装……',
    'Catalog update cancelled. Current Catalog unchanged.': '已取消图鉴更新，当前图鉴未改变。',
    'Later': '以后再说',
    'Download': '下载',
    'Restore bundled Catalog?': '恢复内置图鉴？',
    'This replaces only the offline Catalog with the version included in this App. Favorites, collection marks, and notes are kept. The bundled version may be older than the current Catalog.':
        '仅将离线图鉴替换为 App 内置版本；收藏、收集标记和笔记都会保留。内置版本可能早于当前图鉴。',
    'Restore Catalog': '恢复图鉴',
    'Bundled Catalog restored.': '已恢复内置图鉴。',
    'Checking for Catalog updates...': '正在检查图鉴更新……',
    'Downloading Catalog update...': '正在下载图鉴更新……',
    'Verifying and installing Catalog update...': '正在校验并安装图鉴更新……',
    'Saved item': '已保存项目',
    'Currently unavailable in this Catalog.': '当前图鉴中暂不可用。',
    'Personal notes': '个人笔记',
    'Favorites': '收藏',
    'Collected': '已收集',
    'No favorites yet.': '暂无收藏。',
    'Favorites could not be loaded.': '无法加载收藏。',
    'Collection marks could not be loaded.': '无法加载收集标记。',
    'No handbook entries are marked as collected.': '暂无已标记为收集的图鉴条目。',
    'No collected handbook entries yet.': '暂无已收集的图鉴条目。',
    'The saved item could not be opened.': '无法打开已保存项目。',
    'The collected entry could not be opened.': '无法打开已收集条目。',
    'Handbook entry collected': '已收集此图鉴条目',
    'The collection mark could not be saved. Try again.': '无法保存收集标记，请重试。',
    'The favorite could not be saved. Try again.': '无法保存收藏，请重试。',
    'Delete note?': '删除笔记？',
    'This removes the note from this device.': '这会从此设备移除该笔记。',
    'Delete': '删除',
    'The note could not be deleted.': '无法删除笔记。',
    'The note could not be saved. Your draft is still here.':
        '无法保存笔记，草稿仍保留在此处。',
    'Personal note': '个人笔记',
    'Saved only on this device': '仅保存在此设备',
    'Save note': '保存笔记',
    'Save edit': '保存修改',
    'Saved notes could not be loaded.': '无法加载已保存笔记。',
    'Retry': '重试',
    'No notes saved for this item.': '此项目暂无笔记。',
    'Edit note': '编辑笔记',
    'Delete note': '删除笔记',
    'Native': '原生',
    'Bloodline': '血脉',
    'Skill stone': '技能石',
    'Legendary': '传说',
    'Level': '等级',
    'Source stage': '来源阶段',
    'Unknown source': '未知来源',
    'None': '无',
    'Lord branch': '首领分支',
    'Evolution chain': '进化链',
    'Opened the current validated Catalog': '已打开当前通过校验的图鉴',
    'Installed bundled Catalog data': '已安装内置图鉴数据',
    'Installed a verified Catalog package': '已安装通过校验的图鉴包',
    'Recovered the previous validated Catalog': '已恢复上一版通过校验的图鉴',
    'Restored the Catalog bundled with this App': '已恢复 App 内置图鉴',
    'Independent, non-commercial, and unofficial.': '独立、非商业、非官方应用。',
  };
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);

  String tr(String english) => strings.text(english);
}
