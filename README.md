# 洛克手册

[![离线验证](https://github.com/godwhere/roco-handbook/actions/workflows/offline-validation.yml/badge.svg)](https://github.com/godwhere/roco-handbook/actions/workflows/offline-validation.yml)

一款仅面向 iOS 的独立、非商业、离线优先游戏资料 App。客户端使用 Swift 与 SwiftUI，支持 iOS 15 及以上版本；Python 数据工具将经过校验的 BWIKI 固定版本数据转换为结构化 SQLite 图鉴，提供精灵、技能、特性、进化、属性克制、活动和个性化收藏等查询能力。

App 首次启动不需要下载数据，也不会在浏览过程中访问 Wiki。完整图鉴、图片和字体随安装包提供；后续数据更新必须由用户在设置页主动触发，并经过签名、哈希、压缩包、数据库和版本兼容性校验后才能启用。

> 当前原生开发版本为 `1.2.0`，构建号 `3`。项目尚未发布到应用商店，真机、正式签名、商店上传和审核仍属于独立的发布验收环节。

## 项目概览

| 项目 | 当前实现 |
| --- | --- |
| 客户端 | Swift / SwiftUI 原生 iOS App，支持 iOS 15 及以上 |
| 数据规模 | 621 个具体精灵形态、466 个图鉴条目、824 个技能、311 份技能学习表、273 组进化关系 |
| 数据存储 | 只读 `catalog.db` 与独立可迁移 `user.db` |
| 离线资源 | 精灵立绘、异色立绘、技能与特性图标、属性与分类图标、活动图标、时装预览和 Wiki 风格字体 |
| 本地化 | `zh-CN` 与 `en-US`，其他语言回退到英文；游戏术语以冻结的 Wiki 词汇为准 |
| 平台视觉 | 原生 SwiftUI 导航与系统材质、品牌化图鉴标题、系别主题卡片、动态字号 |
| 数据更新 | 设置页主动检查，使用 GitHub Releases 分发由 Ed25519 签名清单认证的完整图鉴包 |
| 自动化验证 | Python 数据契约测试、Swift XCTest、iOS UI 测试与 GitHub Actions 离线持续集成 |

## 核心功能

### 精灵图鉴

- 按名称、称号、别名或图鉴编号搜索具体精灵形态。
- 支持图鉴编号、名称、物攻、魔攻和速度排序。
- 支持系别、阶数、主形态／地区形态／首领形态、归属赛季和有无异色的组合筛选。
- 首页头图延伸至状态栏背景，排序、筛选与搜索位于同一行。
- 默认每行三只精灵，也可在设置中选择双列卡片或紧凑横向列表；已有布局选择继续保留。三种布局共享系别主题背景，并保留完整立绘、形态副标题、`NO.<编号>`、系别图标和详情跳转。
- 有异色资源的精灵可在详情页切换原始立绘与异色立绘。

### 精灵详情

- 暖色立绘头图下提供“资料、技能、属性克制、蛋组”四个页签；资料页以彩色条展示六项种族资质，并提供特性、已有蛋重资料与基本信息。
- 展示六项种族资质、完整数据下的总和、身高、体重、回顾洛克贝、星光值和首领进化状态。
- 区分精灵技能、血脉影响和可学技能，支持名称、系别或描述搜索，以及技能类型与属性筛选，保留各项学习条件。
- 进化分支可直接跳转到对应精灵详情，不根据名称或编号后缀推断关系。
- 属性克制页可切换进攻方与防守方；根据冻结的属性关系表计算单系和双系受到的伤害倍率。
- 蛋组页展示已收录的组别，可跳转浏览同组精灵；未收录的资料明确提示缺失。
- 右上角更多菜单保留进化、个人收藏／笔记和来源资料入口，收藏按钮与异色切换继续可用。

### 技能图鉴

- 独立展示可学习技能，特性通过精灵关系和特性图鉴访问。
- 支持正常文字输入查询，以及技能类型、技能标签和技能属性组合筛选。
- 技能卡展示图标、名称、属性、分类、耗能、威力和效果说明。
- 技能详情保留来源修订、关联精灵和收藏入口。

### 图鉴工具

工具页使用紧凑的纵向卡片提供七个离线入口：

| 工具 | 功能 |
| --- | --- |
| 赛季档案 | 按图鉴中保存的归属赛季查看精灵 |
| 特性图鉴 | 浏览已收录特性及其关联精灵 |
| 孵蛋组别 | 使用正常文字搜索精灵，并按一个或多个孵蛋组别筛选 |
| 游戏描述 | 查询 54 条状态、印记、天气、战斗动作和规则说明 |
| 活动时间轴 | 按月份、分类和状态浏览 547 条活动记录 |
| 穿搭灵感 | 搜索与筛选 110 套时装，并切换 220 个男女款预览 |
| 个人收藏 | 管理精灵与技能收藏、图鉴收集标记和本地笔记 |

### 个人数据

- 收藏、收集状态和笔记保存在设备私有目录中的 `user.db`。
- `user.db` 与可替换的图鉴数据库完全分离，图鉴更新、恢复或回滚不会覆盖个人数据。
- 图鉴对象在新版本中缺失时，个人收藏仍保留保存时的名称快照和笔记。
- 当前版本不提供账号、云同步或跨设备个人数据迁移。

### 原生 iOS 界面

- 使用 SwiftUI 的系统标签栏、导航、菜单、表单和筛选页；iOS 16 及以上使用 `NavigationStack`，iOS 15 使用 `NavigationView`。
- 系统组件随 iOS 版本呈现对应导航材质；密集图鉴、说明和资料面板保持清晰的实体背景。
- 精灵、技能、工具和设置四个主入口保留，列表末尾可滚动到导航栏之外；动态字号增大时精灵网格可切换为单列。
- 图鉴支持中英文界面，游戏条目的名称和说明保留上游原文。Android 不再属于开发和发布目标。

## 技术架构

项目将开发期数据生产与运行期离线查询分开，App 不直接消费 Wiki 原始字段，也不在运行时解析 Lua。

```text
开发期数据链路

BWIKI 固定修订响应
        ↓
来源身份、修订号与内容哈希校验
        ↓
只解析 data-only Lua 的安全解析器
        ↓
字段适配、引用闭包检查与稳定 ID 注册表
        ↓
规范化 JSON
        ↓
Catalog Builder
        ↓
版本化 catalog.db + manifest + attribution

运行期数据链路

SwiftUI 页面
    ↓
Controller / Domain DTO
    ↓
Repository
    ├── 只读 catalog.db：精灵、技能、进化和图鉴工具
    └── 独立 user.db：收藏、收集状态、笔记和设置
```

SwiftUI 页面只通过 Repository 和领域 DTO 读取数据。SQLite 连接、文件复制、哈希计算和完整性检查不会进入视图构建过程；所有搜索输入使用参数绑定，排序字段由受控枚举选择。

## 关键工程设计

### 1. 可追溯的数据生产管线

- 固定上游模块修订、响应哈希和来源身份，避免数据在构建过程中静默变化。
- 自定义解析器只接受受支持的 data-only Lua 语法，不执行下载的 Lua，也不调用 `require`。
- 对空响应、解析失败、未知字段、引用缺失和身份冲突采取失败关闭策略，不会把失败误写成空版本。
- 原始修订、上游数字 ID、空值、未知字段和需要人工复核的冲突会被保留，方便回溯。

### 2. 稳定身份与关系完整性

- 使用独立的 `handbook_id`、`pet_id` 和上游数字 ID，避免把图鉴条目、具体形态和源数据编号混为一体。
- 当前 NRC 注册表锁定 1,911 个精灵、图鉴和技能身份，并检查缺失、复用和未审核变更。
- 新版来源直接提供图鉴编号、默认展示顺序和归属赛季，不再通过名称、后缀或列表顺序推断。
- 原生技能、血脉技能、技能石技能和传奇技能关系分别保留，避免在规范化时相互覆盖。

### 3. 图鉴与个人数据双数据库

- `catalog.db` 是不可变、版本化、只读的内容数据库，可以整体替换和回滚。
- `user.db` 使用独立结构和迁移流程，只保存个人数据，图鉴安装器无权重建或删除它。
- Catalog 打开时启用 SQLite 只读和 `query_only`，同步查询由后台 actor 仓库串行执行。

### 4. 可恢复的完整图鉴更新

- App 启动时串行完成图鉴选择、校验和 Repository 创建，避免页面读取到半安装状态。
- 新图鉴先写入调用方拥有的暂存文件，通过全部校验后再切换活动指针。
- 保留当前版本和一个已验证的上一版本；激活后打开失败会自动回滚。
- 远端更新使用 Ed25519 验证发布者身份，并检查固定 HTTPS 主机、版本兼容、防重放、文件长度、SHA-256、ZIP 结构、SQLite 完整性、外键和探针查询。
- 当前只支持完整 Catalog 包，不支持逻辑增量补丁、后台更新或 App 二进制更新。

### 5. 完整离线视觉资源

- 595 张去重原始精灵立绘覆盖全部 621 个具体形态。
- 191 张去重异色立绘覆盖 193 个可切换引用。
- 773 个技能或特性图标、35 个属性与分类图标随 App 打包。
- 图鉴视觉资源清单包含 1,594 个文件、1,673 个引用和 124,766,985 字节，并记录来源与本地哈希。
- 工具资源包含 53 个活动图标和 220 个时装预览，共 273 个文件、12,379,751 字节。
- 标题使用冻结的 Wiki 字体，数值使用系统等宽数字；长说明和输入框保留平台字体及缺字回退。

### 6. 自动化质量门禁

- Python 测试覆盖来源契约、安全解析、规范化、身份稳定、引用闭包、数据库构建、资源清单和发布检查。
- Swift 测试覆盖 Repository、双数据库生命周期、更新与恢复、搜索筛选、具体形态、来源关系、离线图片及签名验证；iOS UI 测试覆盖实际导航和个人数据流程。
- GitHub Actions 分别在 Ubuntu 和 macOS 上验证 Python 数据管线及原生 Swift 客户端，不使用 Wiki、签名私钥或商店凭据。
- 发布检查会拒绝 SQLite 事务边车、占位元数据、错误覆盖声明、哈希漂移、来源锁不一致、未审核删除和结构探针失败。

## 技术栈

| 层级 | 技术 |
| --- | --- |
| iOS 客户端 | Swift、SwiftUI、Xcode |
| 本地数据 | 系统 SQLite、参数绑定、JSON |
| 数据工具 | Python 3.11、标准库单元测试、确定性构建脚本 |
| 安全更新 | Ed25519、SHA-256、规范化 Base64url、ZIP 完整包 |
| 平台能力 | iOS、应用私有存储、Swift Concurrency、Foundation、CryptoKit |
| 工程质量 | XCTest、XCUITest、原生构建、GitHub Actions |

## 仓库结构

```text
ios/                    当前 Swift/SwiftUI 客户端、Xcode 工程和原生测试
app/                    保留的 Flutter 迁移参考及共用的不可变离线资源
config/                 来源、身份、术语、关系和资源清单配置
data/raw/               本地冻结响应；正文忽略提交，来源锁可追溯
data/normalized/        确定性的 Catalog 构建输入
data/release/           不可变版本数据库、清单、署名和构建报告
docs/                   技术规格、决策记录、功能文档、证据和阶段报告
licenses/               数据署名边界和运行依赖许可清单
release/                发布候选检查、说明和已知限制
schemas/                Catalog、User 和远端清单的规范结构
tests/                  Python 离线契约与构建回归测试
tools/                  BWIKI 导入、规范化、构建、签名和发布检查工具
.github/workflows/      无凭据离线持续集成
```

## 本地运行

使用 Xcode 打开 `ios/RocoHandbook.xcodeproj`，选择 `RocoHandbook` Scheme 和一个 iOS 模拟器后运行。当前客户端不需要 Flutter、Dart、CocoaPods 或 Android 环境。

App 构建时复用 `app/assets/` 中的冻结资源，首次启动安装内置图鉴。普通浏览不需要网络；设置页中的主动更新操作才会连接固定的 GitHub Releases 地址。

## 本地验证

从仓库根目录运行数据与项目契约测试：

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 -m unittest discover -s tests -p 'test_*.py'
```

验证不可变 Catalog 发布内容：

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools python3 tools/release/check_catalog.py \
  --release data/release/2
```

验证原生客户端：

```bash
swift test --package-path ios --scratch-path /tmp/roco-handbook-spm
xcodebuild -project ios/RocoHandbook.xcodeproj -scheme RocoHandbook \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/roco-handbook-xcode CODE_SIGNING_ALLOWED=NO build
```

iOS UI 测试命令见 [原生客户端说明](ios/README.md)。

## 当前状态与验收边界

- Swift / SwiftUI 客户端位于 `ios/`，保留精灵、技能、七个图鉴工具、收藏、收集标记、笔记和设置功能。Python 导入与构建管线、Catalog 数据版本 2、两份规范 SQL 和离线资源继续复用。
- 保留原 iOS 应用标识和个人数据库路径；图鉴恢复与更新不会覆盖 `user.db`。旧 Flutter 工程暂作迁移参考，Android 构建和发布已退出当前范围。
- 完整包的签名验证及固定 GitHub Releases 传输已移植到 Swift；尚未签名和发布数据版本 2 的远端更新包，本次验证未访问上游或在线更新源。
- 当前原生界面、构建与本地测试证据见 Phase 9 报告；旧 Flutter / Android 证据不能作为原生 iOS 验收结果。
- 真机安装、旧版 Flutter 到原生版的签名升级、iOS 15 运行、VoiceOver、低存储与崩溃耐久性、正式归档、商店上传、审核和发布尚未完成。

## 相关文档

- [技术规格基线](docs/technical-spec-v1.md)：项目范围、数据契约和阶段验收基础。
- [离线图鉴功能](docs/features/offline-catalog-browser.md)：搜索、筛选、详情和工具页行为。
- [个人数据](docs/features/personal-library.md)：收藏、收集标记、笔记和数据库隔离。
- [图鉴更新与恢复](docs/features/catalog-update-and-recovery.md)：安装、指针切换、回滚与清理边界。
- [独立图鉴更新](docs/features/independent-catalog-updates.md)：签名清单、GitHub Releases 和前台更新流程。
- [视觉与本地化](docs/features/localized-visual-handbook.md)：中文术语、图片、字体和页面呈现。
- [原生 iOS 决策](docs/decisions/ADR-0023-native-swift-ios-client.md)：Swift、平台范围及兼容边界。
- [Phase 9 实施报告](docs/implementation-reports/phase-9.md)：当前原生客户端、验证结果和剩余风险。
