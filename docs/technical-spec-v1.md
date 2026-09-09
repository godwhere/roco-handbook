# 《洛克王国：世界》离线精灵手册

**技术架构、数据规范与代码实施边界 V1.0**

> **项目定位：**独立开发、非商业、iOS / Android 双平台的离线精灵手册。开发端从 BWIKI MediaWiki API 获取资料，构建 SQLite 图鉴数据库；Flutter App 随安装包携带数据库，日常查询不依赖网络。
>
> **第一版发布方式：**图鉴数据随新版 App 发布，由应用商店分发；不自建业务服务器，不先实现 App 内独立数据下载和补丁系统。
>
> **文档日期：**2026-09-09。**文档状态：**架构与实施规范基线，包含可执行的参考 SQL；不代表 Flutter App、数据导入器或全量数据集已经实现、构建、上架。
>
> **证据范围：**用户在本次对话中提供的 Mac 终端输出、Lua 源码片段，以及文末列出的官方技术文档。用户 Mac 的完整 `/tmp/*.json` 文件没有作为附件交付给本文编写环境，不能声称已全量解析这些文件。
>
> **执行原则：**涉及代码时，必须同时遵守职责、输入输出、允许修改路径、禁止修改路径、错误处理和验收要求。文档中的项目名与仓库目录为建议命名，不代表已经存在的仓库。

---

## 文档导航

| 章节 | 内容 | 主要阅读对象 |
|---|---|---|
| [0—2](#section-0) | 使用约定、最终决策、证据与待验证项 | 项目负责人、所有开发者 |
| [3—4](#section-3) | 产品范围、App 与开发端总体架构 | Flutter / 数据工具开发者 |
| [5—8](#section-5) | 上游读取、快照、解析、ID 与字段映射 | 数据导入器开发者 |
| [9—11](#section-9) | 图鉴数据库、个人数据库、查询契约 | 数据库与 Flutter 开发者 |
| [12—14](#section-12) | 页面、状态管理、数据库安装与恢复 | Flutter 开发者 |
| [15—16](#section-15) | 发布流程、未来全量与增量更新 | 发布维护者 |
| [17—19](#section-17) | 目录、文件级代码边界、接口职责 | Codex / 实施代理 |
| [20—22](#section-20) | 分阶段执行、验收矩阵、CI 与变更治理 | 实施代理、审查者 |
| [23—25](#section-23) | 来源许可、风险、执行提示词 | 项目负责人、实施代理 |
| [附录 A—F](#appendix-a) | 完整 SQL、参数契约、元数据映射、样本与来源 | 实施与复核 |

章节直达：

[0. 文档使用约定](#section-0) · [1. 最终架构决策与此前草案的收敛](#section-1) · [2. 已验证证据与尚未完成的验证](#section-2) · [3. 产品范围与页面功能](#section-3) · [4. 总体架构与系统职责](#section-4) · [5. 上游 API 导入规范](#section-5) · [6. 原始快照、完整性与增量同步](#section-6) · [7. 安全解析与规范化规则](#section-7) · [8. 身份模型、字段映射与关系规范](#section-8) · [9. `catalog.db` 结构规范](#section-9) · [10. `user.db` 与个人数据保护规范](#section-10) · [11. 查询、规范模型与业务接口](#section-11) · [12. 页面设计与状态规范](#section-12) · [13. Flutter 状态、线程与错误职责](#section-13) · [14. 图鉴安装、更新切换与恢复](#section-14) · [15. 数据构建与 App 发布流程](#section-15) · [16. 后续独立数据更新：设计预留，不在 V1 实现](#section-16) · [17. 仓库布局、产物与环境边界](#section-17) · [18. 文件级代码修改边界与职责矩阵](#section-18) · [19. 模块接口、流程与命令契约](#section-19) · [20. 分阶段实施计划与停止条件](#section-20) · [21. 验收矩阵与质量门禁](#section-21) · [22. CI、版本治理与交付纪律](#section-22) · [23. 来源、许可与素材范围](#section-23) · [24. 风险登记与范围调整](#section-24) · [25. 交给 Codex 的执行提示词与任务模板](#section-25)

---

<a id="section-0"></a>

## 0. 文档使用约定

### 0.1 规范强度

**必须 / 禁止**是验收硬约束；**建议**是默认选择，变更时要在决策记录中说明；**预留**仅表示接口或字段设计，不授权提前实现整套功能；**待验证**表示必须由实施阶段读取真实文件或实际运行后补齐，不能用猜测填充。

本文优先于前面对话中的探索性草案。尤其是数据库“是否拆特性表”“图鉴关系是否拆表”“特性冲突是否一律失败”等曾讨论过多个版本的问题，以本文的统一决策为准。

### 0.2 三类事实不能混写

| 标记 | 含义 | 示例 |
|---|---|---|
| 已实测 | 用户提供的响应直接支持 | `Core` 正文字节数为 394,098，与 API 报告一致 |
| 设计决策 | 本项目选择的实现方式 | 第一版不部署独立数据更新服务 |
| 待验证 | 现有输出不足以确定 | `Evolution` 全量节点、条件结构与默认形态选择规则 |

“API 能读到模块”不等于“所有实体已解析正确”；“大小一致”不等于“游戏资料绝对正确”；“上游有稳定格式的 ID”不等于“上游保证永不重新编号”。

### 0.3 本次交付范围

本次交付是这一份 Markdown 规范。附录中的 SQL 已作为独立数据库结构进行本地验证，验证范围在附录 E 说明。本文不是已提交至 GitHub 的代码变更，也不包含真实全量 `catalog.db`、游戏图片、可运行 Flutter 工程或发布凭证。

---

<a id="section-1"></a>

## 1. 最终架构决策与此前草案的收敛

| 编号 | 最终决策 | 边界与原因 |
|---|---|---|
| ADR-001 | 仅面向《洛克王国：世界》 | 不混入经典页游《洛克王国》的数据 |
| ADR-002 | Flutter + Riverpod + Drift / SQLite | SDK 和依赖版本在初始化阶段验证并锁定，不在本文猜测最新版本 |
| ADR-003 | BWIKI 仅是开发端上游 | 正式 App 不请求 BWIKI API、不解析 Lua、不抓取网页 |
| ADR-004 | API 分模块读取即可 | 不依赖 SMW，也不要求一次 HTTP 请求取得全部精灵 |
| ADR-005 | 第一版数据随 App 更新 | 无需自建服务器；应用商店分发 App，不负责解释精灵级数据差异 |
| ADR-006 | 图鉴库和个人库分开 | `catalog.db` 可替换；`user.db` 只能独立迁移，不随图鉴更新覆盖 |
| ADR-007 | 图鉴条目与具体形态分开 | `handbook_id` 与 `pet_id` 不混用；共享 `004` 合法 |
| ADR-008 | V1 将图鉴引用直接放在 `pets` | 同时保存 `hide_entry_name`、`show_topics`；目前每条精灵记录只观察到一个图鉴引用，不提前引入多对多表 |
| ADR-009 | 特性与普通技能共用 `skills` | 不重复维护 `abilities`；界面可以分开显示两类内容 |
| ADR-010 | 保留共享 Learnset 模型 | 使用 `pet_learnsets` 与三类学习关系表；统一查询视图可供 App 使用 |
| ADR-011 | 六项固定资质直接放在 `pets` | V1 不再增加一对一 `pet_stats`；后续多版本资质另行设计 |
| ADR-012 | Core 与 Learnset 的特性同时保留 | Core 作为具体精灵优先值；差异必须报告、解释，不预设所有差异都是坏数据 |
| ADR-013 | 源数据 ID 不当作官方永久 ID | 保存上游映射与跨版本身份审计，不能按列表位置重新编号 |
| ADR-014 | 先整库替换，再评估独立更新 | 开发端增量同步现在可做；手机端补丁为后续独立阶段 |
| ADR-015 | 素材专项设计暂缓 | 只预留本地资源键与缺图占位；不批量下载图片、不研究素材包与美术版权细节 |
| ADR-016 | 不改变用户网络环境 | 禁止修改 Shadowrocket、TUN、DNS、系统代理、Shell 配置和证书来“修复”请求 |

**纠正过度绝对化表述：**把技能展开为 `pet_skills` 并非技术上“错误”，只是本项目选择保留共享 Learnset 作为规范数据层；必要时可以生成视图或派生缓存。采用 `pet_id` 是当前可行的身份方案，但不承诺上游永远不变。

---

<a id="section-2"></a>

## 2. 已验证证据与尚未完成的验证

### 2.1 证据索引

| 证据 | 本次对话中的来源 | 能支持的结论 |
|---|---|---|
| E01 | 用户贴出的 `siteinfo` JSON | 当次 Mac 环境能访问该 Wiki 的基础 API；响应自报 MediaWiki 1.37.0 |
| E02 | 五个模块的 revision / size / UTF-8 检查输出 | `Index`、`Core`、`Skills`、`Evolution`、`Handbook` 当次读取成功 |
| E03 | 三个技能主体模块的检查输出 | `SkillCatalog`、`Learnsets`、`LearnsetCatalog` 当次读取成功 |
| E04 | 魔力猫三条记录的 Core 上下文 | 三个 `pet_id` 共享 `handbook_000004`，并共享一个进化组引用 |
| E05 | 三个技能模块的实际开头和关联片段 | 特性属于技能目录；精灵通过 Learnset 关联技能；存在原生、血脉和技能石列表 |
| R01—R13 | 文末官方资料 | 通用 API、Flutter、SQLite、发布与许可依据 |

E01—E05 是用户提供的会话证据，不是本环境重新访问用户 Mac 得到的结果。不要把文本中的转义、Markdown 链接包装或终端 `>....` 提示符当作原始文件内容。

### 2.2 已读取模块的快照记录

以下是**用户此次抓取的历史修订信息**，不是保证以后查询仍为这些版本，也不表示对应当前游戏最新版本。

| 模块 | Revision ID | 上游修订时间 UTC | 正文 UTF-8 字节数 | API 报告一致 |
|---|---:|---|---:|---|
| `PetData/Core` | 43006 | 2026-08-13T03:58:53Z | 394098 | 是 |
| `PetData/Index` | 42853 | 2026-08-07T02:48:05Z | 63246 | 是 |
| `PetData/Evolution` | 42851 | 2026-08-07T02:48:00Z | 114329 | 是 |
| `PetData/Handbook` | 42852 | 2026-08-07T02:48:04Z | 198733 | 是 |
| `PetData/SkillCatalog` | 43008 | 2026-08-13T03:58:57Z | 185997 | 是 |
| `PetData/Learnsets` | 42855 | 2026-08-07T02:48:09Z | 17335 | 是 |
| `PetData/LearnsetCatalog` | 42854 | 2026-08-07T02:48:07Z | 412526 | 是 |
| `PetData/Skills`，聚合模块 | 34741 | 2026-05-18T03:14:48Z | 1564 | 是 |

前七个数据模块正文合计 **1,386,264 字节**。这不是最终数据库、图片包、安装包或用户更新包的大小。不能从末尾出现 `pet_000596` 推导总计恰好 596 个有效精灵，也不能沿用早前未核实的“594 个精灵”。

Core 输出包含 SHA-1：`e3425aada1f5c0b2c70eed5aa619483bb80856b5`。当时只展示了该值，没有展示本地重新计算 SHA-1 后的比对结果，不能把“哈希校验通过”写为已完成。

### 2.3 三个读取失败的附加模块

`HeadOverrides`、`SkillStoneTopics`、`TopicRewards` 当次只得到 `JSONDecodeError`。这只能说明交给 JSON 解析器的正文无效或为空，不能据此认定页面不存在、被限流、服务器损坏或 TUN 故障。

正式客户端必须记录最终 HTTP 状态、Content-Type、响应体大小、经过脱敏的错误摘要和请求标识；不能仅打印 `JSONDecodeError`。第一版不提供这些模块支持的专题功能，因此允许其明确标记为未导入，但不能假装相关资料已完整。

### 2.4 目前仍需在代码实施阶段完成的事项

| 待验证项 | 谁负责 | 验证完成前的处理 |
|---|---|---|
| 完整 Lua 文件都能被安全解析器处理 | 数据工具负责人 | 使用已有文件离线测试；遇到表达式停止该模块解析，不执行 Lua |
| Handbook 完整结构、真实显示编号与默认形态 | Handbook adapter | 不根据 ID 尾数批量臆造编号和默认条目 |
| Evolution 完整结构、方向、条件 | Evolution adapter | 可先确认组成员；不能按排列顺序生成进化边 |
| SkillCatalog 全字段、威力与特殊能耗表达 | Skill adapter | 未确认的字段保留为扩展数据或 NULL，不填零 |
| `desc_notes` 的说明正文来源 | 数据工具负责人 | 保留引用 ID，不生成虚假术语解释 |
| Core 与 Learnset 特性差异是否为合法覆盖 | Validator + 人工审查 | 产生阻断待审项，逐条确认规则，不随意覆盖 |
| `source_stage` 的实际展示或学习约束语义 | Learnset adapter | 保留原值，不据此隐藏其他阶段技能 |
| 全量引用闭合、ID 跨版本稳定性 | Validator | 未通过前不能发布真实全量数据库 |
| iOS / Android 真实设备安装切换与恢复 | Flutter / 发布负责人 | 单纯 SQL 验证不能代替真机验收 |

**项目可进入实施，但不能把上述未完成项写成“已全部验证”。不再要求用户手工复制更多大段正文；实施工具应自动读取现有 JSON 文件并生成结构报告。**

---

<a id="section-3"></a>

## 3. 产品范围与页面功能

### 3.1 第一版必须具备的离线能力

| 模块 | 必须具备 | 明确不做 |
|---|---|---|
| 精灵图鉴 | 名称 / 标题 / 编号搜索、属性筛选、排序、图鉴与全部形态视图 | 在线抓取、实时游戏数据 |
| 精灵详情 | 资质、特性、形态切换、学习技能、经验证的进化关系 | 未验证的进化推导、战斗模拟 |
| 技能图鉴 | 名称与类别筛选、技能详情、反查学习者或拥有该特性的精灵 | 未核实的伤害公式、实时配队评分 |
| 我的收藏 | 精灵与技能收藏、图鉴已收集标记、个人笔记 | 账号、跨设备云同步、社区 |
| 设置与关于 | 主题、版本、数据时间、来源与许可、图鉴恢复入口 | 运行时下载插件或代码 |
| 数据生命周期 | 首次安装、随 App 更新替换、失败保留旧库 | V1 自建数据服务器、独立补丁下载 |

“离线”包括首次安装后不联网也能建立本地数据库并查看资料。不能以首次启动必须访问 BWIKI、登录、下载基础包或获取配置作为前提。

素材未准备好时使用本地占位图；列表和详情仍应完整提供文字数据。图片的网络热链不能作为“离线图片方案”。

### 3.2 导航与默认入口

底部入口固定为：**精灵图鉴 / 技能图鉴 / 我的收藏 / 设置**。默认精灵图鉴按 `handbook_entries` 展示；“全部形态”作为切换视图，使用 `pets` 记录。

搜索精确命中特殊形态时，直接进入该 `pet_id`；不能要求先进入默认图鉴条目才能找到它。图鉴数量与具体形态数量必须分别统计。

### 3.3 非功能要求与测量边界

| 要求 | 验收定义 |
|---|---|
| 完全离线 | 飞行模式下完成首次启动、搜索、详情、收藏、笔记、来源文字阅读 |
| 个人数据保护 | 更新或恢复图鉴后，个人数据逻辑导出与更新前一致；不要求 SQLite 文件字节完全相同 |
| 可恢复性 | 复制中断、空间不足、损坏数据库、未知 schema 均不覆盖可用旧库 |
| 可追溯 | 每个发布数据库可追溯到 source lock、Builder 版本、adapter 版本、校验报告 |
| 性能 | 建议目标：安装后普通冷启动 2 秒内，常见本地查询 P95 100ms 内；这是待测目标，不是已经达到的指标 |
| 可访问性 | 字体放大不遮挡核心操作，按钮有语义标签，属性不能只靠颜色区分 |
| 最少权限 | 不申请定位、联系人、VPN、相册批量访问、后台常驻或其他无关权限 |

性能测试必须记录设备、系统、构建模式、数据库版本与样本数量。第一版复制数据库的安装耗时应单独统计，不能混入正常查询指标。

---

<a id="section-4"></a>

## 4. 总体架构与系统职责

### 4.1 三个明确隔离的区域

```text
[开发端：允许受控联网]
BWIKI MediaWiki API
        ↓
Import Client → 不可变原始快照 + sources.lock.json
        ↓
安全 Lua 数据解析 → 字段展开 → 领域规范化
        ↓
引用 / 身份 / 差异 / 许可校验
        ↓
catalog.db + bundled_catalog.json + 构建报告
        ↓
[发布端：显式授权发布]
Flutter 构建 → 商店提交 → 用户安装 / 更新
        ↓
[用户端：日常离线]
CatalogInstaller → 版本化图鉴文件（只读）
        ↓
Repositories → Riverpod 页面状态 → Flutter UI
        ↕
user.db（收藏、收集标记、笔记、设置）
```

### 4.2 技术选型与依赖规则

Flutter 负责共用 UI 与业务代码，Riverpod 负责依赖注入与页面状态，Drift 负责 SQLite 查询与类型映射；Python 负责开发端数据处理。这是本项目的技术决策。Flutter 官方建议分离 UI 与数据职责；Drift 官方说明支持导入预置数据库。[R03][R04][R05]

初始化阶段必须记录 Flutter / Dart / Python 版本及各依赖锁文件。不能未经验证升级整个项目依赖，也不能在文档中写一个版本、锁文件中用另一个版本。

Catalog 的 SQL 结构以 `schemas/catalog_v1.sql` 为唯一规范来源。Drift 应通过选定版本支持的 SQL 导入或生成步骤使用同一结构；禁止 Python 和 Dart 各自维护一套名称相似但约束不同的建表定义。`user.db` 同样使用规范 SQL 与版本化迁移测试。

### 4.3 依赖方向

```text
features/*/presentation
        ↓
features/*/application
        ↓
domain/models + domain/repositories（接口）
        ↑
data/repositories（实现） → data/catalog、data/user（Drift / DAO）

services/catalog_installer → 专用验证与文件管理
app/bootstrap             → 连接以上组件，启动页面
```

UI 不知道 BWIKI 字段缩写；DAO 不知道某个按钮如何排版；Installer 不处理技能语义；Importer 不操作 App 个人数据；Builder 不调用应用商店发布。

### 4.4 为什么 V1 不需要自己的服务器

数据与应用构建一起发布，App 不需要在线查新版数据。应用商店负责应用分发，平台可能优化更新下载量，但实际体积取决于平台和打包结果，不能承诺修改一条精灵就只下载一条记录。[R08][R09]

以后 App 独立下载数据库时，需要的是可访问的文件托管位置，而不必是自建业务后端。该能力属于第 16 章后续范围，不应被初始化阶段顺手实现。

---

<a id="section-5"></a>

## 5. 上游 API 导入规范

### 5.1 唯一上游入口

```text
https://wiki.biligame.com/rocom/api.php
```

使用 MediaWiki Action API。标准 revisions 查询可以取得页面内容、修订编号和时间，也支持按指定 revision 获取数据；实际可用参数必须以该 BWIKI 实例响应为准，不假设其版本与 MediaWiki 最新文档完全一致。[R01]

### 5.2 模块清单与导入级别

| source_key | 请求标题 | 级别 | 作用 |
|---|---|---|---|
| core | `Module:PetData/Core` | 核心必需 | 精灵基础资料与引用 |
| index | `Module:PetData/Index` | V1 必需 | 名称、标题、ID 索引与核对 |
| handbook | `Module:PetData/Handbook` | V1 必需 | 图鉴条目与编号映射 |
| evolution | `Module:PetData/Evolution` | 完整 V1 必需 | 进化关系与条件 |
| skill_catalog | `Module:PetData/SkillCatalog` | 核心必需 | 普通技能与特性目录 |
| learnsets | `Module:PetData/Learnsets` | 核心必需 | 精灵到技能集映射 |
| learnset_catalog | `Module:PetData/LearnsetCatalog` | 核心必需 | 技能集内容 |
| pet_module | `Module:Pet` | 适配器审查输入 | 对照上游字段展开、引用组装规则；不执行 |
| skills_module | `Module:PetData/Skills` | 适配器审查输入 | 对照技能聚合规则；不执行 |
| head_overrides | `Module:PetData/HeadOverrides` | V1 不启用 | 头像修正，素材范围另议 |
| skill_stone_topics | `Module:PetData/SkillStoneTopics` | V1 不启用 | 技能石专题来源 |
| topic_rewards | `Module:PetData/TopicRewards` | V1 不启用 | 专题奖励 |

上游 `Module:Pet` 的公开代码确实引用了上述主要模块，并对数据做字段展开及图鉴、头像等组合处理。因此，“原始 Core”不等于“网页最终展示的全部信息”；本项目按功能范围实现必要的适配规则，而不是下载并运行整个上游模块。[R11]

### 5.3 请求策略

默认串行、并发数 1；请求间隔建议不少于 1 秒。连接超时建议 10 秒、读超时 60 秒、单次导入总超时受配置限制。以上是本项目保守默认值，不是宣称 BWIKI 公布了这些限额。

读取正文优先按模块单独请求。成功后可优化少量元数据批量查询，但不能把“支持 API 一次多标题”当作已经完成了本项目所有批量场景验证。

对 429 / 503 / `maxlag` 等可恢复情况尊重 `Retry-After`，采用有上限的退避；默认最多 3 次重试。认证错误、访问拒绝、验证码或反自动化页面不做绕过。MediaWiki 的使用礼仪强调降低服务器负载、正确标识客户端并处理限流，本项目采取保守实现。[R02]

User-Agent 使用真实项目名称和维护者明确提供的联系地址；未配置时不伪造联系方式或官方身份。禁止伪装成浏览器绕过访问控制，禁止从个人浏览器提取 Cookie。

### 5.4 响应必须经过分层检查

```text
请求完成
  ↓
检查传输错误、最终 HTTP 状态、重定向目标
  ↓
检查响应类型与字节上限，保存原始响应
  ↓
JSON 解析
  ↓
检查 API error / warnings / missing / invalid / revisions
  ↓
检查页面 ID、标题、revision、main slot、正文类型
  ↓
长度与哈希验证
  ↓
纳入候选快照
```

`HTTP 200` 不是成功的充分条件。有效 JSON 中也可能有 API 错误；HTML、空正文、缺少 slot、隐藏修订正文都不能通过。任何例外警告必须在报告中保留，不得用空字典兜底后继续构建。

如果存在 `continue`，必须按返回的续取参数继续，并核对期望页面集合。`rvlimit` 不是精灵数量，也不是拆分 Lua 文件的参数。请求多个标题时不能假设响应顺序等于请求顺序。

### 5.5 网络与安全边界

用户已经在当前环境取得有效响应，只能说明当次链路可用；不能由此判断每次请求走代理还是直连。导入失败时输出可诊断信息，**绝不修改系统网络**。

严格禁止自动运行 `networksetup` 改配置、修改 DNS、调整路由、编辑 `/etc/hosts`、改 `.zshrc` 代理变量、安装根证书、关闭 TLS 校验、修改 Shadowrocket 或 TUN。不得将用户订阅链接、Cookie、Token、节点密码写入日志或报告。

---

<a id="section-6"></a>

## 6. 原始快照、完整性与增量同步

### 6.1 从缓存到冻结快照

每个模块的原始 API JSON、提取后的 Lua 正文、请求元数据都存放在项目自己的数据目录，不长期依赖 `/tmp`。用户已有 `/tmp/Module_PetData_*.json` 可以作为一次性导入来源，复制后计算哈希并保持原文件不变。

```text
data/raw/<snapshot_id>/
    api/core.json
    lua/core.lua
    api/skill_catalog.json
    lua/skill_catalog.lua
    ...
    sources.lock.json
    import-report.json
```

`source_lock` 至少记录：请求标题、规范标题、page ID、revision ID、上游修订时间、实际抓取时间、正文长度、API SHA-1、本地正文 SHA-256、原始响应 SHA-256、解析器版本、导入状态。

### 6.2 冻结 revision，避免混杂读取

导入流程先查询模块元数据并冻结候选 revision 集合，再按这些 revision 获取正文；下载后核对实际 revision 与冻结值。不应“先看版本 A，稍后无条件下载最新 B，却仍记录为 A”。

下载结束重新检查上游 revision 集合。如果读取期间相关模块发生变化，标记快照为可能混合，重新开始或等待下次构建；不自动无限重试。即便首尾 revision 不变，也只证明抓取期间稳定，不能证明维护者对多个模块的更新是原子操作。因此仍需全量引用校验。

### 6.3 完整性判断

检查分为四层：传输成功、正文一致、安全解析成功、领域引用正确。任何一层不能替代后一层。

MediaWiki 的 revision 总大小 / SHA-1 与 slot 大小 / SHA-1 有区别；只下载 main slot 时，应在实例支持的情况下请求并核对该 slot 的元数据。只有确认是单一 main slot，才将总 revision 大小作为正文大小依据。不能把 HTTP `Content-Length`、JSON 文件大小或字符数当作 Lua UTF-8 正文字节数。[R01]

本文用户样本的总大小与 main 正文 UTF-8 字节数一致，是有效的完整性证据；正式工具还需重新计算哈希，并完成语法、结构和关联验证。

不得对正文先做换行替换、Unicode 归一化或去空格后再计算源哈希。应分别保存原始正文哈希与规范化结果哈希。SHA-1 用于与上游对照，不能充当将来更新包发布者的身份认证。

### 6.4 复用缓存的规则

只复用与冻结 revision 及已验证哈希一致的缓存。元数据已确认未变，可以不重新下载正文；元数据查询失败，不能把旧数据当成最新查询成功。

存在两种明确模式：`sync` 模式尝试取得新快照；`build --offline` 模式仅基于已有冻结快照构建。后者必须标注数据来源时间，不更新“抓取时间”伪装为新资料。

### 6.5 删除、新增、修正与身份变化

只有完整快照才允许生成实体差异。某模块请求失败、解析条数突然变少、字段名改变，都不是合法删除依据。

差异报告至少区分：新增、字段修改、关系修改、疑似删除、ID 重映射、资料恢复。任何疑似删除必须人工确认。V1 对已发布的精灵、技能与图鉴条目优先保留最小 `retired` 身份记录，使旧收藏仍可解释；正常列表默认不显示撤下记录。

允许在构建端增量同步模块，但第一版仍重建完整图鉴库。**开发端增量同步与手机端增量更新是两套不同机制。**

---

<a id="section-7"></a>

## 7. 安全解析与规范化规则

### 7.1 只读取数据，不执行上游代码

允许解析的数据形式是经明确支持的 Lua 数据表，例如 `return { ... }`。禁止 `eval`、`exec`、Lua 解释器执行、`require` 自动加载、运行 `Module:Pet` 或其他下载代码。

建议使用不执行代码的成熟 AST 解析器，再遍历允许节点；或实现范围明确、带测试的 table-literal 解析器。选型须在依赖记录中说明维护状态与许可。不能以全局正则替换 `=`、花括号或布尔值来“转换成 JSON”。

解析器必须处理经测试的 UTF-8 字符串、转义、注释、布尔、数字、嵌套 table、显式键与列表项。遇到函数、调用、循环、运算表达式或未支持节点时，返回包含 source_key、revision、偏移位置的错误，不自动执行作为后备。

### 7.2 保留 Lua table 的结构差异

Lua table 可能是列表、字典、混合键表；空表也不能仅凭语法判断是空数组还是空对象。解析阶段保留键和值；由具体 adapter 按字段契约解释。不能将所有数字键字典强行转为列表，或丢失原始顺序。

设置可配置的文件体积、嵌套深度、token 数量与解析超时上限。超限产生可操作错误，不截断后继续构建。

### 7.3 `_meta.key` 的展开范围

从当前模块读取 `_meta.key`，在数据记录范围内递归展开字段键；保留 `_meta` 自身用于审计，不对其中的翻译表再次改名。实体索引键如 `pet_000007`、`skill_000003` 不参与缩写翻译，字符串值也不能被全局替换。

某模块没有 `_meta` 时，不得擅自套用另一个模块的映射。确需按 Core 的字典展开，必须由该 adapter 明确声明，并有上游聚合逻辑和样本测试支持。

展开后出现键冲突必须失败。例如短键与完整键同时出现并映射到同一个字段，不能采用“后写覆盖前写”。未知字段保留到 `extra_json` 或开发端 unmapped 报告，不直接丢弃。

### 7.4 上游字段与本地数据库字段分离

元数据负责解释上游缩写，adapter 负责映射成本项目稳定模型。**数据库列名不能每次随 `_meta` 自动生成。** 上游新增字段不应自动修改线上数据库结构。

原始 JSON / Lua 保留在开发端；App 不需要携带整套上游代码。重要未知字段可以放入本地 `extra_json`，但 UI 不能据此动态执行逻辑或直接渲染未知 HTML。

### 7.5 数据类型与空值

未知、未提供和数值零必须分开。可选布尔用 `NULL / 0 / 1`，不能把缺少 `le` 自动宣称为上游明确提供 `false`。高度、体重先保留原始文本，例如 `1.5~2.15M`；不凭范围文本擅自生成单一测量值。

类别与形态标签保留原始中文；不能把所有特殊形态的上游标签统一改成“超进化”。App 可使用“特殊形态”作为产品入口，但应展示真实源标签。

---

<a id="section-8"></a>

## 8. 身份模型、字段映射与关系规范

### 8.1 三种 ID，不同职责

| 标识 | 当前例子 | 职责 |
|---|---|---|
| 具体精灵标识 | `pet_000007` | 一条可查询、可收藏的精灵 / 形态记录 |
| 图鉴条目标识 | `handbook_000004` | 编号与默认图鉴入口 |
| 进化组标识 | `evo_000004` | 关联进化结构，不等于图鉴条目 |

另外，`skill_000003` 是技能目录键；技能记录中的 `id=200076` 是另一个上游数值字段。其“游戏官方内部 ID”身份尚未由当前证据独立证明，因此本地列名采用 `upstream_numeric_id`，不采用带保证意味的 `game_skill_id`。

### 8.2 魔力猫样本的确定关系

| 名称 | pet_id | handbook_id | 进化组引用 | 原始 form | Core 特性引用 |
|---|---|---|---|---|---|
| 魔力猫 | pet_000007 | handbook_000004 | evo_000004 | 未提供 | skill_000003 |
| 叶冕魔力猫 | pet_000538 | handbook_000004 | evo_000004 | 首领形态 | skill_000197 |
| 武斗酷猫 | pet_000595 | handbook_000004 | evo_000004 | 首领形态 | skill_000226 |

这三条映射来自 E04。不能给它们虚构新的官方编号；也不能因为共享进化组就生成“魔力猫 → 叶冕魔力猫 → 武斗酷猫”的链。进化方向必须由 Evolution adapter 的真实数据确定。

### 8.3 跨版本身份稳定

V1 初次导入允许将经过验证的上游 `pet_*`、`skill_*`、`handbook_*` 作为本地标识初始值；发布后，本项目必须维护身份锁文件 `config/identity_registry.json`。

身份锁至少记录：实体类型、本地 ID、来源系统、来源记录键、首次确认 revision、辅助指纹和人工重映射记录。上游改名不自动换本地 ID；上游相同 ID 指向完全不同实体时不得把旧收藏自动指向新对象。

Learnset ID 只用于图鉴内部共享配置，不用作用户收藏键。关系列表的 ordinal 仅在当前数据快照内定位，不能作为跨版本个人数据标识。

### 8.4 Core → pets 映射

| 上游缩写 / 路径 | 展开后的语义 | 本地字段或处理 |
|---|---|---|
| 外层 `pet_*` 与 `i` | id | `pets.pet_id`，先核对二者一致 |
| `n` / `t` | name / title | `name` / `title`；不是全库唯一键 |
| `hb.i` | handbook.id | `handbook_id`，允许确实无图鉴引用的记录为空 |
| `hb.hen` / `hb.stp` | hide_entry_name / show_topics | 同名布尔字段；不当作默认形态选择开关 |
| `f` / `c` / `d` | form / class / description | `form` / `class_name` / `description` |
| `sg` | stage | `stage` |
| `bsn` | belong_season | `belong_season_raw`；筛选前核实含义与映射 |
| `sl` / `rg` | starlight / review_gold | 保留对应字段，不擅自解释为解锁等级或进化费用 |
| `ht` / `wt` | height / weight | `height_text` / `weight_text` |
| `dr` / `hs` / `le` | can_double_ride / has_shiny / is_lord_evolution | 可空布尔字段 |
| `fs` | feature_skill | `feature_skill_id` |
| `st.hp/at/df/sa/sd/se` | hp / atk / def / spa / spd / spe | 六项整数资质，可缺值 |
| `tp` | types | `pet_types`，保留槽位顺序 |
| `evg` | evolution_groups | `pet_evolution_groups` |
| `img.il` / `img.hd` | illustration / head | 资源键；不是已下载文件路径 |
| `egp`、`gr`、`img.eg/fr/frs` 等 | 蛋组、性别权重、蛋 / 果实资源 | 当前不做专项 UI，保留在 `extra_json` 或规范化扩展记录 |

六项合计由已知六项计算；任一项缺失则总和显示未知，不把缺值当零。中文标签在展示层统一为生命、物攻、物防、魔攻、魔防、速度。

### 8.5 SkillCatalog → skills 映射

| 源字段 | 本地字段 | 规则 |
|---|---|---|
| 外层 `skill_*` | skill_id | 目录引用主键 |
| `id` | upstream_numeric_id | 可选、不擅自加唯一约束 |
| `name` | name | 必填、允许不同 ID 同名 |
| `category` | category | 原文保存；`特性` 只是其中一种类别 |
| `desc` | description | 保存已处理安全标记的文本，不执行 HTML / Lua |
| `element` | element_raw + 可空 type_id | `无系别` 不能误映射为普通系 |
| `energy` | energy_value + energy_text | 数值可计算，原文可显示；未提供不是零 |
| 威力相关字段 | power_value + power_text | 待全字段扫描确认实际键名，不推测填充 |
| `target` | target_text | 原文保存 |
| `icon_id` | icon_key | 按文本保存，不直接构造任意网络地址 |
| `desc_notes` | skill_description_notes | 保存 ID 和顺序，说明正文来源未验证 |
| 其他字段 | extra_json / unmapped 报告 | 必须可审计，不静默丢弃 |

### 8.6 Learnset 映射

`Learnsets` 的已见结构是 `pet_id → learnset_id`。`LearnsetCatalog` 的已见结构如下：

| 路径 | 完整字段 | 目标 |
|---|---|---|
| `fs` | feature_skill | `learnsets.feature_skill_id` |
| `ns[].sk/lv/sg` | native_skills[].skill/level/stage | 原生技能表；保留 level、source_stage 和顺序 |
| `bs[].sk/lv/bl` | blood_skills[].skill/level/blood | 血脉技能表；保留血脉原文 |
| `ss[]` | skill_stones[] | 技能石技能关系表 |

魔力猫的映射为 `pet_000007 → learnset_000001`。样本显示另外两个 pet ID 也复用该集合；不能据此推断所有同图鉴形态都共享同一集合，仍应读取各自映射。

原生技能中的 `stage=1` 不应自动要求 `pets.stage=1` 才显示，因为共享技能集可能被不同阶段的精灵使用。血脉技能也不能被合并成“同时无条件拥有所有血脉技能”的描述。

### 8.7 特性解析优先级与差异审查

本项目规则为：Core 提供具体精灵特性时优先使用；Core 未提供而 Learnset 提供时，使用 Learnset 默认值；两者均缺失则显示资料未提供。

两边都有值但不一致时，生成 `FEATURE_CONFLICT` 审查项。未审查不得发布；审查后可以确认为合法的具体形态覆盖，并以带实体 ID、源 revision、理由的规则记录放行。禁止全局“忽略所有特性差异”，也不能宣称全量数据必须天然相等。

### 8.8 Handbook 与 Evolution 的适配边界

SQL 结构可以先确定，但上游字段路径尚需在 Phase 1 自动检查。Handbook 默认显示记录优先采用已验证的上游规则；没有可靠规则时，使用明确的人工映射，不根据 `show_topics`、`hide_entry_name` 或编号最小值猜测。

Evolution 模型保留组、组成员、带方向的边及条件。组成员可以先由 Core 引用核对；边必须由真实 Evolution 记录建立。条件文本和原始结构共同保留，不把条件写成可执行表达式。图形布局必须有访问节点保护，不能假设所有关系永远无环。

---

<a id="section-9"></a>

## 9. `catalog.db` 结构规范

### 9.1 规范表与查询视图

完整 DDL 见附录 A。V1 共 **19 张表、2 个查询视图**；不能因为表多就为每张表单独增加无业务价值的 Service。

| 表 | 职责 | 重要约束 |
|---|---|---|
| `catalog_meta` | 数据集、结构版本、数据版本、快照与构建信息 | 只能有 singleton=1 的记录 |
| `source_revisions` | 当前及必要历史来源修订 | `source_ref` 唯一；同 source_key + revision 唯一 |
| `handbook_entries` | 图鉴入口与显示编号 | ID 与显示编号分开；不强制未经验证的编号唯一规则 |
| `handbook_display` | 每个图鉴入口的默认精灵 | Builder 验证默认精灵有效且确实归属该图鉴 |
| `pets` | 具体形态与固定资质 | `pet_id` 主键，可共享 handbook_id |
| `pet_aliases` | 别名、历史名称、索引别名 | 同别名可以对应多个精灵 |
| `types` | 本地属性词表 | 名称唯一，不把无系别映射成普通系 |
| `pet_types` | 精灵属性与顺序 | 每个精灵槽位唯一；不提前限制最多两个 |
| `skills` | 普通技能、特性统一目录 | 上游数字 ID 不设未经验证的唯一约束 |
| `skill_description_notes` | 描述术语引用与顺序 | 只保存实际引用，不伪造解释 |
| `learnsets` | 共享技能集及默认特性 | 与具体精灵分离 |
| `pet_learnsets` | 精灵对应的技能集 | V1 每个精灵最多一个映射 |
| `learnset_native_skills` | 原生技能、等级、源阶数 | 主键为集合与 ordinal，允许同技能多个学习条件 |
| `learnset_blood_skills` | 血脉技能与血脉条件 | 原文与规范属性映射分开 |
| `learnset_skill_stones` | 技能石可学技能 | 不是“技能石道具”的完整数据库 |
| `evolution_groups` | 进化组 | 不推导为图鉴组 |
| `pet_evolution_groups` | 组成员与源顺序 | 同精灵允许属于多个组 |
| `evolution_edges` | 实际方向、方法与条件 | 起终点必须属于该组 |
| `entity_sources` | 实体的多来源证据 | 多态关联由 Builder 验证，不伪造跨表外键 |

`pet_skill_sources` 统一返回三类学习方式；`pet_feature_skills` 返回特性及采用来源。前者使用 `UNION ALL` 保留同技能的不同条件，不能用 `UNION` 或不加条件的去重抹掉来源差别。

### 9.2 主键与空值规则

所有文本主键显式 `NOT NULL`。引用不存在的对象不能通过随意插入空壳记录来“修复外键”。允许无图鉴引用的精灵存在，但这种情况必须来自源数据或审查记录，不能掩盖 Handbook 导入失败。

除明确要求为整数的资质和等级外，威力、能耗采用数值与显示文本并存；未知值为 NULL。SQL 的基本 CHECK 不是完整领域验证，Builder 还必须验证数据类型和合理范围；不依赖 SQLite 类型亲和性自动把字符串当成正确数字。

### 9.3 为什么不使用额外的 `pet_handbook` 与 `pet_stats`

目前每条精灵记录观察到一个 handbook 引用，相关展示标记也只有两项，直接放在 `pets` 更简单。六项资质也是固定一对一字段，V1 放在 `pets` 中。未来若出现同一形态对应多个图鉴体系、历史平衡版本或不同赛季资质，再通过 schema 升级处理，不在 V1 预埋复杂关系。

### 9.4 来源与撤下记录

`source_key` 表示逻辑模块，例如 `core`；`source_ref` 表示具体来源修订，可采用 `bwiki.rocom:13216:43006` 这类本项目定义的字符串。来源表允许保留撤下实体对应的旧修订，以免用最新页面声称支持已从该页面删除的内容。

撤下记录至少保留身份、名称快照及来源。已经无意义的学习关系可以在新库中移除；用户笔记仍按原 ID 保留。不得把“撤下”渲染为“游戏必定永久删除该精灵”，除非源数据明确提供该结论。

### 9.5 结构唯一来源与 Drift 对接

规范 SQL 是事实来源；生成的 Dart 类型、查询辅助代码与结构快照是派生产物。修改任何列、外键、索引或视图，都必须更新 SQL、对应模型、查询测试、结构版本与变更记录。

`catalog.db` 在 App 中以只读方式打开，同时启用防误写保护；不对它运行普通用户数据库的自动建表 / 自动升级回调。外键保护在构建和任何写连接上显式启用，SQLite 官方说明不能假定每个连接已默认开启。[R06]

---

<a id="section-10"></a>

## 10. `user.db` 与个人数据保护规范

### 10.1 五张个人数据表

| 表 | 用途 | 不允许的行为 |
|---|---|---|
| `user_meta` | 个人库结构版本、创建时间 | 使用图鉴数据版本替代个人库 schema 版本 |
| `favorites` | 收藏精灵、技能、图鉴入口 | 仅用名称关联；图鉴更新时清空 |
| `collection_marks` | 图鉴条目级已收集标记 | 默认推断该条目下全部特殊形态也已拥有 |
| `notes` | 与对象关联的个人笔记 | 为修复图鉴而重建或丢弃笔记 |
| `settings` | 明确允许的展示偏好 | 保存凭证、代理配置、可执行脚本或任意下载地址 |

所有对象引用使用 `dataset_id + object_type + object_id`，防止将来不同数据集出现相同 ID 时串联。`name_snapshot` 用于对象撤下或资料库异常时仍能说明收藏对象。

### 10.2 不使用跨库外键

个人库不对图鉴库建立外键，也不要求同时在一个事务里更新两库。SQLite 的外键不能跨 schema 边界，关联由 Repository 根据稳定 ID 解析。[R06]

界面遇到撤下或未找到对象时，显示名称快照与“当前资料库中不可用”，允许查看、编辑或删除个人笔记，不自动删除用户数据。

### 10.3 迁移与恢复

个人库迁移由 `UserDatabaseMigrator` 管理，采用逐版本、可测试的迁移。迁移失败保留原库或已验证备份，并提供错误状态；禁止 catch 异常后删除数据库重新创建。个人库迁移的具体 API 与测试方式以锁定的 Drift 版本为准。[R13]

备份需要关闭所有相关写连接，或采用经过验证的 SQLite 一致性备份方式；不能在数据库处于活动写入状态时只复制主文件而忽略日志。一致性备份实现可参照 SQLite 官方备份接口。[R12] 应用升级保护不等于设备损坏、用户卸载或系统清理后永不丢失数据。

本地导出 / 导入个人备份可作为后续增强，不是“已实现云备份”。V1 设置页须说明数据保存在本机及卸载风险。

### 10.4 事务边界

收藏使用显式 `setFavorite(true/false)` 而不是依赖重复点击翻转状态；写入成功后更新 UI，或在乐观更新失败时还原。重复收藏必须幂等，唯一约束防止重复行。

笔记写入只影响 `user.db`；保存失败保留编辑文本并提示重试。清理图鉴缓存不能触碰笔记、收藏或个人库迁移备份。

---

<a id="section-11"></a>

## 11. 查询、规范模型与业务接口

### 11.1 统一 DTO，隔离上游与数据库细节

| DTO | 至少包含 | 不包含 |
|---|---|---|
| `PetSummary` | petId、handbookId、编号、名称、形态、属性、状态、资源键 | 原始 Lua、API 响应 |
| `PetDetail` | Summary、资质、特性、基本资料、形态组、学习来源、来源引用 | 数据库连接、HTTP 客户端 |
| `SkillDetail` | 技能基础字段、类别、描述、数值、来源、说明引用状态 | 未解析的上游执行代码 |
| `LearnableSkill` | skillId、学习类型、等级、源阶数、血脉、顺序 | 简化成仅 skillId 的无条件技能列表 |
| `EvolutionGraph` | 组、节点、边、条件、资料完整性状态 | 根据编号临时计算的方向 |
| `CatalogInfo` | 数据集、结构 / 数据版本、快照、构建时间、覆盖范围 | 用户笔记正文 |
| `SourceReference` | 来源名称、修订、许可、原页面地址 | Cookie、请求凭证 |

DTO 由 Domain 定义；Drift 自动生成的数据库行类型不直接暴露给 Widgets。

### 11.2 查询契约

| 接口 | 输入 | 输出与排序规则 |
|---|---|---|
| `searchHandbooks` | 关键词、属性、模式、分页、排序枚举 | 图鉴条目列表，默认按已验证的图鉴顺序 |
| `searchPets` | 关键词、属性、形态、资质排序 | 具体形态列表，最终以 petId 稳定打破并列 |
| `getPetDetail` | petId | 详情或明确 NotFound / Retired 状态 |
| `getFormsForHandbook` | handbookId | 同图鉴的可查询形态；不暗示进化顺序 |
| `getLearnableSkills` | petId、来源过滤 | 保留所有学习条件，特性单独返回 |
| `getSkillDetail` | skillId | 技能详情；缺失数值显示未知 |
| `getSkillUsers` | skillId、关系类型、分页 | 区分可学习者与特性拥有者；可按 pet 去重但保留全部来源 |
| `getEvolutionGraph` | petId | 参与组的真实结构，禁止推测 |
| `getCatalogInfo` | 无 | 本地版本与资料覆盖状态 |

普通查询只读本地 SQLite。显示收藏状态需要与 `UserRepository` 做应用层合并，不让 SQL 页面查询直接依赖另一个数据库的迁移状态。

### 11.3 搜索与筛选

V1 首先支持名称、标题、别名、精确图鉴编号匹配。编号输入 `4` 与 `004` 可以作为用户输入归一化，但归一化不得改变数据库保存的真实显示编号；非纯数字编号不得被强制转整数。

所有用户文本参数绑定，排序列使用枚举白名单。`LIKE` 搜索需正确处理 `%`、`_` 等字符；不能把输入拼成 SQL。V1 不默认承诺拼音、简繁转换或中文分词能力，这些需要独立规则和样本测试。

多属性筛选应明确“满足任一选中属性”或“同时包含全部选中属性”，默认使用任一，并在 UI 说明。技能反查按学习来源保留条件，不把同技能的多种获取方式算成多个独立精灵。

### 11.4 数据变化通知

图鉴替换只在启动阶段执行，正常浏览时图鉴连接固定。个人数据库的收藏、笔记变化可以使用 Drift 查询流映射到 Riverpod；不得在每次 Widget build 时重新打开数据库或启动未释放的监听。

---

<a id="section-12"></a>

## 12. 页面设计与状态规范

### 12.1 精灵图鉴

顶部为搜索与视图模式，下面为筛选条件与排序，主体为卡片或列表。默认只显示 active 图鉴条目；全部形态视图显示 active pets。卡片保留编号、名称、形态、属性和收藏按钮，不塞入所有技能与资质。

点击默认卡片进入 `handbook_display.default_pet_id`；搜索精确形态直接进入相应 petId。默认形态选择来自已验证规则或人工映射，不把第一条数据库结果当成默认值。

### 12.2 精灵详情

阅读顺序：标题与编号 → 形态切换 → 基本资料与特性 → 六项资质 → 学习技能 → 进化关系 → 收藏 / 笔记 → 来源信息。

三种魔力猫共用 `004`，但显示自己的名称、特性和资质。切换形态必须同时切换全部相关数据和收藏对象，不能只换头像与标题。

高度体重按源文本显示；未知数值显示“资料未提供”。数据中 `form` 缺失可以在 UI 中显示“默认”，但该词是展示兜底，不反写源字段。

### 12.3 技能图鉴与详情

支持普通技能与特性分类切换。详情中为特性显示“拥有该特性的精灵”，普通技能显示“可学习的精灵”及原生、血脉、技能石来源。

`desc_notes` 只有 ID 而无已验证解释时，不展示可点击但打不开的术语卡片。可以显示原描述，并在数据覆盖说明中注明扩展术语解释尚未收录。

### 12.4 进化展示

有真实方向与条件时显示关系卡片或简单图形；没有完成映射时只能显示明确标注的相关组成员，不能伪造箭头。完整 V1 发布要么完成进化验收，要么调整范围并把缺失功能写入版本说明，不能隐藏未实现状态。

无需引入战斗规则引擎、自动推导配队、远程动态图形脚本或网页嵌入。复杂图形必须有可读列表替代。

### 12.5 收藏、收集与笔记

收藏精灵精确到 petId，收藏技能精确到 skillId；已收集标记 V1 按 handbookId。两者 UI 文案必须区分，避免“已收集魔力猫”被解释为所有特殊形态均已拥有。

笔记默认本机保存，编辑器离线工作。对象撤下时保留名称快照和笔记，不把对象不存在渲染成应用崩溃。

### 12.6 设置与关于

显示 App 版本、App 构建号、Catalog schema、数据版本、源修订时间范围、构建时间、资料来源与许可。不要用单个最新模块时间表示全部数据均在该时间同步于游戏。

“恢复内置图鉴”只作用于图鉴，不清空个人数据。V1 不显示实际并不存在的“在线更新数据”按钮；可以引导用户通过所安装渠道更新 App。

### 12.7 页面状态矩阵

| 状态 | 展示 | 用户可做 |
|---|---|---|
| 本地首次准备 | 安装本地数据提示，不显示下载文案 | 等待本次前台操作或退出，下次可恢复 |
| 查询正常 | 列表 / 详情 | 全部离线操作 |
| 搜索无结果 | 无匹配与清空筛选入口 | 修改查询 |
| 可选资料缺失 | 资料未提供或模块未收录 | 使用其余已验证内容 |
| 图鉴候选更新失败但旧库可用 | 旧数据与清晰提示 | 正常继续使用 |
| 所有图鉴候选不可用 | 恢复内置图鉴入口 | 不删除个人数据 |
| 个人库写入失败 | 保存失败提示 | 保留编辑内容、重试 |

界面设计到此为止；不在本规范中创建 Logo、配色资产、精灵立绘或素材下载系统。

---

<a id="section-13"></a>

## 13. Flutter 状态、线程与错误职责

### 13.1 状态所有权

每个 Feature 的 Controller / Notifier 保存自己的搜索条件、筛选、分页和选中对象。App 级 Provider 只持有当前 Catalog 句柄、User Repository、主题与启动状态，不创建一个掌管全部业务的巨型全局状态对象。

搜索建议做短防抖；新查询到达后旧查询结果不能覆盖新结果。详情按 petId / skillId 参数化，页面关闭后释放无用订阅。

### 13.2 UI 线程与数据库线程

数据库读写使用所选 Drift 版本支持的后台执行方式。复制文件、哈希、完整性检查和大型转换不得在界面 build 中执行。V1 启动完成后不再执行 Lua 或全库规范化。

### 13.3 错误分类

| 错误 | 负责组件 | 处理方式 |
|---|---|---|
| 上游请求或 JSON 错误 | Importer | 中止候选快照，输出报告 |
| Lua 结构 / 字段变化 | Parser / Adapter | 明确 source 与偏移 / 字段，停止相应构建 |
| 引用缺失 / ID 冲突 | Validator | 阻断发布，禁止静默跳过 |
| 数据库不兼容 / 损坏 | CatalogInstaller | 保留旧库，回退或提示恢复 |
| 本地查询失败 | CatalogRepository | 转为类型化错误，不返回空列表伪装无数据 |
| 收藏 / 笔记失败 | UserRepository | 回滚事务，保留 UI 内容 |
| 权限 / 磁盘空间失败 | 文件与平台服务 | 给出操作建议，不申请无关权限 |

日志不包含用户笔记正文、收藏全量内容、账号凭证或代理配置。上游错误正文只记录有长度上限的脱敏摘要。

### 13.4 不把占位接口当作已完成

Repository 接口允许先由测试 Fake 实现，但生产构建不能偷偷使用样本精灵库或内存收藏。所有 Fake、Mock 和人工样本必须只存在于测试或明确的开发构建中。

---

<a id="section-14"></a>

## 14. 图鉴安装、更新切换与恢复

### 14.1 版本体系

| 标识 | 示例 | 谁维护 |
|---|---|---|
| App version | 1.0.1 | Flutter 发布配置 |
| App build number | 平台要求的递增构建标识 | 发布脚本 |
| catalog_schema_version | 1 | 数据结构规范 |
| catalog_data_version | 101 | 本项目发布序列，正整数 |
| user_schema_version | 1 | 个人库迁移规范 |
| adapter_version / builder_version | 版本字符串或提交标识 | 数据工具 |
| source revision IDs | 多个模块各自 revision | BWIKI 快照 |

示例数据版本不是已发布版本。`data_version` 不是某一个 BWIKI revision 的替代名称；同一 source snapshot 在修复 adapter 后也可能产生新的数据版本。

旧 App 不认识新 schema 时不能安装，即使候选是完整数据库。V1 用编译时允许的 catalog schema 集合判断兼容性，不靠字符串大小比较 App 版本。

### 14.2 安装包内与运行目录

```text
安装包资源：
assets/catalog/catalog.db
assets/catalog/bundled_catalog.json
assets/catalog/ATTRIBUTION.txt

App 私有持久化目录：
catalogs/
    catalog-v100-s1.db
    catalog-v101-s1.db
    .staging-<operation_id>.db
catalog-state/
    active_catalog.json
    active_catalog.json.tmp
user/
    user.db
    migration-backups/
```

App 应使用平台提供的私有持久化目录，不把用户库放在易清理缓存目录。资源数据库需复制到可打开的本地文件位置；仅判断“文件存在就不复制”会导致更新 App 后一直使用旧库，因此必须比较内置数据版本。[R04]

### 14.3 内置 manifest 契约

```json
{
  "manifest_version": 1,
  "dataset_id": "roco-world-zh-cn",
  "catalog_schema_version": 1,
  "data_version": 101,
  "snapshot_id": "example-snapshot",
  "database_asset": "assets/catalog/catalog.db",
  "database_bytes": 123456,
  "database_sha256": "REPLACE_WITH_ACTUAL_64_HEX_SHA256",
  "coverage": {
    "pets": true,
    "skills": true,
    "evolutions": true,
    "topic_rewards": false,
    "skill_stone_topics": false,
    "description_note_definitions": false
  }
}
```

以上是格式示例，长度、版本、哈希和覆盖状态必须由 Builder 从真实产物生成。示例哈希故意不是有效值，验证器必须拒绝它。覆盖标记由校验结果产生，不允许 UI 或打包脚本手工改成 true。

### 14.4 启动状态机

```text
BOOT
  ↓
检查当前指针及其数据库
  ↓
读取并验证内置 manifest
  ↓
选择兼容的目标版本
  ├─ 当前版本有效且无需替换 → OPEN_CURRENT
  └─ 首次安装 / 新内置版本 / 当前库损坏
          ↓
       COPY_TO_STAGING
          ↓
       VERIFY_CANDIDATE
          ↓
       CLOSE_OLD_HANDLES
          ↓
       COMMIT_ACTIVE_POINTER
          ↓
       OPEN_AND_PROBE_NEW
          ├─ 成功 → READY；保留前一版待清理
          └─ 失败 → RESTORE_PREVIOUS_POINTER → OPEN_OLD
```

整个安装过程只允许一个操作实例。V1 在正常页面与查询启动前完成切换，避免运行中大量连接同时读不同版本。

### 14.5 验证候选数据库

验证 dataset、schema、data version、文件长度、SHA-256、`catalog_meta` 与 manifest 一致性、必需表 / 视图存在、`PRAGMA integrity_check`、`PRAGMA foreign_key_check` 以及少量关键只读查询。普通生命周期重启可按已验证指针采取轻量检查，但候选安装必须完整验证。

正式 App 以只读方式使用图鉴，禁止对其运行 Drift 自动建表和 schema migration。Builder 发布前须结束所有事务、确保内容不依赖未打包的 WAL 或 journal、关闭连接后再计算产物哈希。

### 14.6 原子切换的边界

禁止在旧数据库仍打开时直接覆盖同名文件。候选数据库使用新的版本化文件名；文件准备完成后通过同目录临时指针文件替换当前指针，并保留 previous 记录。

文件落盘、flush、rename 与崩溃恢复须在 iOS 和 Android 真机验证。不能因为 SQLite 事务具有原子提交机制，就声称“数据库文件＋JSON 指针＋个人库”自动构成一个跨文件原子事务。[R07]

恢复时只接受项目生成、路径在私有目录白名单内的文件；拒绝绝对路径注入、`..`、未知数据库和不匹配哈希。指针损坏时先尝试验证过的前一版本或内置库，不扫描任意外部文件。

### 14.7 故障处理与删除策略

| 故障点 | 必须行为 |
|---|---|
| 空间不足 / 复制失败 | 删除本次 staging，保留旧库和 user.db |
| 校验失败 | 不切换指针，保留失败报告 |
| 切换前进程退出 | 下次继续使用旧有效版本或清理未完成 staging |
| 切换后打开失败 | 回退 previous；首次安装则显示内置恢复错误 |
| 新库 schema 不兼容 | 不能强行打开；使用兼容旧库或明确提示需要兼容 App |
| 旧库损坏但内置库有效 | 恢复内置图鉴，不重建个人库 |
| user.db 迁移失败 | 不能以图鉴恢复顺带删除个人数据 |

正常启动成功后，最多保留当前和上一份已验证图鉴。旧文件清理由 Installer 专用目录范围内的白名单执行，禁止广泛递归删除 App 支持目录。

### 14.8 个人库与图鉴切换的隔离

图鉴更新成功不能触发个人库版本增加；个人库 schema 更新也不必重新导入 BWIKI。User migrator、Catalog installer 分别提供错误与恢复状态。

用户主动选择恢复内置图鉴时，可允许回到较旧但兼容的数据版本，并明确提示。未来启用独立数据下载后，App 自带较旧数据不能自动覆盖较新的兼容本地数据，除非是用户确认的恢复操作。

---

<a id="section-15"></a>

## 15. 数据构建与 App 发布流程

### 15.1 一次发布的端到端流程

| 顺序 | 执行者 | 输入 | 输出 | 失败边界 |
|---|---|---|---|---|
| 1 | Importer | 模块清单、旧 source lock | 新冻结候选快照 | 不能覆盖旧快照 |
| 2 | Parser / Adapters | 原始 API / Lua 文件 | 规范化 JSON、结构报告 | 遇到未支持结构停止，不执行代码 |
| 3 | Validator | 全实体与身份锁 | 引用、身份、差异、覆盖报告 | 阻断项存在时不发布 |
| 4 | 人工审查 | 新增 / 删除 / 冲突报告 | 审批或具体修正规则 | 不允许通配符忽略错误 |
| 5 | Catalog writer | 规范 SQL、已审数据 | 临时 catalog.db | 失败仅删除临时产物 |
| 6 | Package validator | 临时数据库 | 校验通过的 DB、manifest、署名文件 | 不得手工跳过哈希 |
| 7 | Flutter 测试 | 新数据包与 App | 离线与升级测试报告 | 不允许覆盖 user.db |
| 8 | 发布负责人 | 已通过验证的应用构建 | 商店提交材料 | 未明确授权不上传、不发布 |

### 15.2 确定性与可复现性

同一 source lock、identity registry、adapter 配置与工具版本应生成相同的规范化实体及逻辑差异。所有对象键与记录顺序按规则固定，禁止使用运行时无序字典、当前本机时间或随机 ID 改变实体身份。

SQLite 文件的物理哈希可能受运行库和写入细节影响，因此“逻辑内容一致”与“文件字节一致”分别校验。发布后文件不可原地更改；相同数据版本必须指向相同发布产物，修复内容应分配新版本。

### 15.3 schema 与数据更新

仅修改条目内容：可增加 data_version，不改变 schema。修改表结构、字段语义、枚举兼容性或查询契约：必须评估 schema 增加、Dart 模型变更与旧 App 兼容性。

V1 图鉴结构升级采用新的全量数据库随新版 App 发布，不在用户手机上编写复杂的图鉴内容迁移。个人库采用自己的迁移链。

### 15.4 无服务器路线的边界

开发端可以手动运行，也可以将来在明确配置的 CI 中运行；不需要长期在线的业务服务。CI 自动拉取 BWIKI 并自动提交应用商店不属于默认授权。

应用商店负责分发不等于无需开发者账号、审核或平台发布准备；本文不估算平台费用，也不承诺审批通过。商店的压缩或补丁优化不由本项目控制。[R08][R09]

---

<a id="section-16"></a>

## 16. 后续独立数据更新：设计预留，不在 V1 实现

### 16.1 启用条件与优先顺序

先有真实需求与数据包体积测量，再实现“只下载完整数据库”；全量下载上线稳定后，才考虑逻辑增量。不能为了预留能力先搭用户系统、数据库服务器、在线任务平台或复杂补丁链。

独立更新只分发静态数据，不分发 Dart、Lua 执行代码、动态库或任意 SQL 脚本。平台政策和目标应用商店条款在该阶段重新核对，本文不把数据文件格式当作必然通过审核的保证。

### 16.2 文件托管与后端区别

```text
文件托管位置（后续选型）
├── manifest.json
├── full/catalog-vN.zip
└── patches/from-A-to-B.json.gz
```

可以使用对象存储或其他可靠文件托管，不要求自己维护一台应用服务器。更新不可达时继续使用本地旧库。具体服务、账号、费用、域名和可达性在该阶段选定，V1 不创建任何付费资源。

### 16.3 manifest 的最低约束

远程 manifest 必须包含数据集、schema、目标版本、发布序列、最低协议版本、全量包地址与大小、SHA-256、签名信息；补丁还应包含明确起始版本与逻辑内容摘要。

地址使用 HTTPS，允许域名与重定向范围受限制。仅有 SHA-256 不足以认证来源，因为攻击者若能替换文件也可能替换同一位置的 manifest；签名验证公钥随 App 发布，私钥绝不进入 App 或仓库。

密钥轮换、防旧签名重放、失败重试与恢复包策略必须在该阶段单独完成设计与测试。当前只预留 `CatalogPackageSource` 类型边界，不实现签名系统或联网更新。

### 16.4 逻辑补丁而非默认二进制 diff

建议补丁表达规范实体 upsert、明确字段清空、撤下身份及关系集合替换，不直接发送 SQL。关系数据优先整组替换，例如一个 Learnset 的全部原生 / 血脉 / 技能石列表整体换新，防止旧关系残留。

```json
{
  "protocol_version": 1,
  "dataset_id": "roco-world-zh-cn",
  "schema_version": 1,
  "from_data_version": 100,
  "to_data_version": 101,
  "from_logical_digest": "ILLUSTRATIVE_ONLY",
  "to_logical_digest": "ILLUSTRATIVE_ONLY",
  "entities": {
    "pets_upsert": [],
    "pets_retire": [],
    "skills_upsert": [],
    "skills_retire": []
  },
  "replace_relations": {
    "learnsets": [],
    "pet_learnsets": [],
    "evolution_groups": []
  }
}
```

这是后续协议草案，不是当前可以直接上线的完整协议。正式实现还须覆盖所有规范表、溯源与元数据同步，明确 NULL / 缺字段差别、未知字段策略、逻辑摘要序列化和测试向量。

### 16.5 补丁应用流程

```text
验证签名与目标兼容性
    ↓
确认本地起始版本和逻辑摘要精确匹配
    ↓
将只读基线复制到 staging
    ↓
在 staging 的事务中应用白名单操作
    ↓
检查引用、数据版本、目标逻辑摘要
    ↓
关闭写连接，验证完整数据库
    ↓
交给同一个 CatalogInstaller 切换
```

任一步失败只影响 staging。App 不修改 `user.db`，也不在用户正在查询的连接上应用补丁。重复应用应被拒绝或明确识别为已安装，而不是重复插入。

### 16.6 全量回退条件

基线版本不匹配、schema 改变、补丁缺失、补丁链过长、总补丁体积不划算、逻辑校验失败或本地库损坏时，使用经过验证的全量包。阈值须由真实包体积和性能决定，不提前承诺固定大小收益。

正常在线更新不得静默降级；用户手动恢复内置库或使用可信修复包属于独立、明确的恢复流程。

---

<a id="section-17"></a>

## 17. 仓库布局、产物与环境边界

### 17.1 建议目录

```text
roco-handbook/
├── README.md
├── AGENTS.md
├── docs/
│   ├── technical-spec-v1.md
│   ├── decisions/
│   ├── evidence/
│   └── implementation-reports/
├── config/
│   ├── bwiki_sources.json
│   ├── identity_registry.json
│   ├── type_aliases.json
│   ├── handbook_display_overrides.json
│   └── reviewed_exceptions.json
├── schemas/
│   ├── catalog_v1.sql
│   ├── user_v1.sql
│   ├── normalized_contracts/
│   └── manifests/
├── tools/
│   ├── pyproject.toml
│   ├── bwiki_import/
│   │   ├── cli.py
│   │   ├── client.py
│   │   ├── response_validator.py
│   │   ├── snapshot_store.py
│   │   └── revision_checker.py
│   ├── catalog_builder/
│   │   ├── cli.py
│   │   ├── lua_parser.py
│   │   ├── key_expander.py
│   │   ├── identity_resolver.py
│   │   ├── adapters/
│   │   │   ├── core.py
│   │   │   ├── index.py
│   │   │   ├── handbook.py
│   │   │   ├── skills.py
│   │   │   ├── learnsets.py
│   │   │   └── evolution.py
│   │   ├── validator.py
│   │   ├── differ.py
│   │   ├── sqlite_writer.py
│   │   └── package_writer.py
│   └── release/
│       ├── check_catalog.py
│       └── prepare_app_assets.py
├── data/
│   ├── raw/<snapshot_id>/
│   ├── normalized/<snapshot_id>/
│   ├── reports/<snapshot_id>/
│   └── release/<data_version>/
├── app/
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── assets/catalog/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── bootstrap.dart
│   │   │   ├── router.dart
│   │   │   └── theme.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── data/
│   │   │   ├── catalog/
│   │   │   ├── user/
│   │   │   └── repositories/
│   │   ├── services/
│   │   │   ├── catalog_installer/
│   │   │   ├── local_assets/
│   │   │   └── user_database_migrator/
│   │   └── features/
│   │       ├── pokedex/{application,presentation}/
│   │       ├── skills/{application,presentation}/
│   │       ├── collection/{application,presentation}/
│   │       └── settings/{application,presentation}/
│   ├── test/
│   ├── integration_test/
│   ├── ios/
│   └── android/
├── tests/
│   ├── fixtures/
│   ├── import/
│   ├── parser/
│   ├── adapters/
│   ├── schema/
│   ├── builder/
│   └── release/
├── licenses/
│   ├── DATA_ATTRIBUTION.md
│   └── THIRD_PARTY_NOTICES.md
└── .github/workflows/             # 仅在实际使用 GitHub 时增加
```

这些是职责目录，不要求为了填满目录建立空文件。`{application,presentation}` 是树形展示缩写，不是字面文件夹名。

### 17.2 原始数据与 Git

原始快照较小也不意味着必须全部进 Git。建议提交小型脱敏或公开资料测试样本、sources lock、结构报告与必要映射；大型快照和生成产物按明确策略存储。发布数据库应以不可变版本保存，不能对同版本静默替换。

不把用户个人库、私钥、API Cookie、代理配置或平台签名材料放进仓库。`/tmp` 只作为已知输入来源，不作为正式项目缓存位置。

### 17.3 当前工作区保护

真正实施前必须读取当前仓库根目录与 `git status`，确认确实是本手册项目。不能把本方案直接写入用户的 Cleared、Echo of Genesis 或其他当前打开的项目。

未经用户明确选择，不创建远程仓库、不推送 main、不 force push、不回滚用户已有改动。需要变更目录或公共接口时先形成范围变更说明；可以完成允许范围内的工作并报告阻塞，不能偷改无关目录。

---

<a id="section-18"></a>

## 18. 文件级代码修改边界与职责矩阵

### 18.1 模块边界总表

| 模块 | 允许修改的主要路径 | 输入 / 输出 | 禁止跨越的职责 |
|---|---|---|---|
| API 客户端 | `tools/bwiki_import/client.py`、`response_validator.py`、`tests/import/` | 请求配置 → 有效响应或类型化错误 | 不解析精灵、不写数据库、不改网络配置 |
| 快照管理 | `snapshot_store.py`、`revision_checker.py`、导入 CLI | 有效响应 → 不可变快照与锁文件 | 不覆盖旧快照、不偷偷混用不同 revision |
| Lua 解析 | `lua_parser.py`、`tests/parser/` | 正文 → 受限 AST / table | 不联网、不执行 Lua、不映射 UI 字段 |
| 字段展开 | `key_expander.py` 与对应测试 | table + 字典 → 展开记录 | 不改字符串值、不自动创建 SQL 列 |
| Core adapter | `adapters/core.py`、Core fixture / tests | Core → Pet 规范记录 | 不替代 Handbook 或 Evolution 推导关系 |
| 技能 adapter | `adapters/skills.py`、技能 fixture / tests | SkillCatalog → Skill / note refs | 不下载图标、不假造术语解释 |
| Learnset adapter | `adapters/learnsets.py`、集合测试 | Learnsets + Catalog → 共享集合与来源关系 | 不按名字拼接技能、不合并掉条件 |
| 图鉴 adapter | `adapters/handbook.py`、展示 overrides、对应测试 | Handbook + Core → 图鉴入口与默认展示 | 不按 ID 尾数臆造官方编号 |
| 进化 adapter | `adapters/evolution.py`、对应测试 | Evolution + Core → 组 / 成员 / 边 | 不按同编号或列表位置生成进化链 |
| 身份映射 | `identity_resolver.py`、identity registry、测试 | 上下版本身份 → 本地稳定 ID 映射 | 不按名称批量改主键、不改 user.db |
| 校验与差异 | `validator.py`、`differ.py`、reviewed exceptions、测试 | 全记录 → 阻断 / 警告 / 差异报告 | 不静默删记录、不自动批准删除 |
| SQL 结构 | `schemas/catalog_v1.sql`、结构测试、受影响模型 | 规范模型 → DDL | 不单独修改 Dart 建表而不更新 SQL |
| 数据库写入 | `sqlite_writer.py`、`tests/builder/` | 已审记录 → 临时数据库 | 不联网、不使用用户库、不上传商店 |
| 数据打包 | `package_writer.py`、release tools、测试 | 已验 DB → manifest / 署名 / 发布目录 | 不手工标记虚假的 coverage，不覆盖已有版本 |
| Catalog DAO | `app/lib/data/catalog/`、相关测试 | 只读 DB → 数据行 | 不写图鉴、不访问 user.db、不控制界面 |
| User DAO / 迁移 | `app/lib/data/user/`、migrator、测试 | 用户操作 → 个人数据 | 不覆盖图鉴、不吞异常后重建个人库 |
| Repository | `domain/repositories/`、`data/repositories/`、模型测试 | DAO → DTO / 业务结果 | 不包含 Widget、不访问 BWIKI、不改网络 |
| Controller | 各 Feature 的 `application/` 与测试 | 用户事件 → 状态与 Repository 调用 | 不写 SQL、不复制数据库文件 |
| UI | 各 Feature 的 `presentation/`、主题与 Widget tests | 状态 → 界面 | 不直接调用 DAO、不决定源字段含义 |
| CatalogInstaller | `services/catalog_installer/`、安装测试 | manifest + 候选 DB → 当前句柄 | 不修改 user.db、不执行 schema 猜测迁移 |
| App bootstrap | `app/bootstrap.dart`、入口与启动测试 | Installer / migrator → 可用 App | 不把所有业务集中到 main.dart |
| 平台配置 | 必要的 `app/ios/`、`app/android/`、pubspec | 已验证依赖需求 → 可构建平台工程 | 不随意加权限、改系统环境、改变签名身份 |
| 发布自动化 | `tools/release/`、CI 与版本记录 | 已测产物 → 待提交构建 | 不默认授权正式上传、发布、支付或创建服务 |

### 18.2 跨模块变更规则

需要修改接口时，先在任务说明中列出调用方与被调用方、数据迁移影响、需要更新的测试。一个 UI 任务发现数据缺字段时，应提出 adapter / schema 的具体变更，不直接在 Widget 中写一个 BWIKI API 请求“临时补齐”。

模块负责人负责自身测试；接口变更负责人还必须运行上下游契约测试。独立任务不能通过删除测试、放宽全部验证或加任意 `try/except: pass` 来获得通过结果。

### 18.3 明确禁止的快捷做法

| 禁止做法 | 正确替代 |
|---|---|
| API 异常后返回空列表并继续发布 | 终止候选构建，保留旧发布版本 |
| 用正则或字符串替换解析整份 Lua | 安全 AST / table parser + adapter |
| 执行下载 Lua 的 `require` | 读取显式允许的数据模块并自行组装 |
| 为通过外键插入虚假精灵 / 技能 | 找出真实缺失引用，补齐或明确缩减范围 |
| 所有图鉴相关记录共用一个 petId | 保留具体形态 ID 与共同 handbookId |
| 让 UI 直接读取 `_meta` 或 Lua 短字段 | 在开发端展开并规范化，UI 使用 DTO |
| App 更新时递归删除整个数据目录 | Installer 只清理自己的版本化图鉴文件 |
| 用新 catalog 覆盖 user.db | 分库，个人库逐版本迁移 |
| 在打开的图鉴文件上直接写补丁 | 使用 staging 副本并验证后切换 |
| 不知道脚本失败原因就改代理 / DNS | 记录 HTTP / 解析错误，保留网络环境 |
| 在代码里硬编码“596 个精灵” | 从通过验证的当前数据统计 |
| 把文档中的样例版本和哈希当正式值 | Builder 自动生成并校验真实值 |

### 18.4 环境、命令与依赖权限

Python 依赖安装在项目专用虚拟环境；不得 `sudo pip` 或修改系统 Python。Flutter 依赖变更只在项目配置与锁文件范围内进行。不要为“加速下载”修改用户全局镜像、Git 配置或网络代理。

未经授权不安装额外系统服务、数据库守护进程、VPN、证书或后台任务。移动平台必需的 SDK / 构建环境若缺失，应报告当前缺项和已完成范围，不声称已通过未运行的真机测试。

---

<a id="section-19"></a>

## 19. 模块接口、流程与命令契约

以下签名是接口设计，不代表这些代码已经存在。实施时补充准确类型、错误模型、文档与测试，不能把带占位说明的示例直接视为完成实现。

### 19.1 Python 导入与构建接口

```python
class WikiClient:
    def fetch_metadata(self, titles: list[str]) -> "MetadataBatch": ...
    def fetch_revision(self, revision_id: int) -> "RevisionDocument": ...

class SnapshotStore:
    def import_local_responses(self, paths: list[str]) -> "CandidateSnapshot": ...
    def freeze(self, candidate: "CandidateSnapshot") -> "SnapshotLock": ...

class LuaDataParser:
    def parse(self, text: str, source: "SourceRef") -> "LuaTable": ...

class KeyExpander:
    def expand(self, table: "LuaTable", mapping: dict[str, str]) -> "ExpandedTable": ...

class CatalogNormalizer:
    def normalize(self, snapshot: "SnapshotLock") -> "NormalizedCatalog": ...

class CatalogValidator:
    def validate(self, catalog: "NormalizedCatalog") -> "ValidationReport": ...

class CatalogDiffer:
    def compare(self, previous: "NormalizedCatalog", current: "NormalizedCatalog") -> "DiffReport": ...

class CatalogWriter:
    def build(self, catalog: "ValidatedCatalog", output_dir: str) -> "CatalogArtifacts": ...
```

`ValidatedCatalog` 只能由通过校验的流程产生，不能在 CLI 中以一个布尔变量绕过 Validator。所有网络请求在 WikiClient 中集中管理；Parser、Normalizer、Writer 的单元测试必须能完全断网运行。

### 19.2 核心接口的前置条件与后置条件

| 接口 | 前置条件 | 后置条件 |
|---|---|---|
| `fetch_revision` | revision 为正整数、来源在白名单 | 返回实际 revision 与请求一致的完整正文，否则错误 |
| `freeze` | 所有必需模块已验证、锁文件无重复 | 输出不可变快照与可复用 source lock |
| `parse` | 源长度与编码已验证 | 所有语法节点都属于允许集合，不存在执行副作用 |
| `normalize` | 当前 adapter 版本理解源结构 | 输出稳定 ID、明确空值、可追溯字段 |
| `validate` | 所有实体集合齐备 | 报告所有阻断项、警告与覆盖，不只输出总计数字 |
| `compare` | 两份有效规范数据与身份映射 | 删除与重映射分开，关系替换可识别 |
| `build` | 无未审查阻断项 | 输出单独版本目录，不改变旧发布物 |

### 19.3 Flutter 接口边界

```dart
abstract interface class CatalogRepository {
  Future<List<PetSummary>> searchPets(PetQuery query);
  Future<PetDetailResult> getPetDetail(String petId);
  Future<PetSkillBundle> getSkillsForPet(String petId);
  Future<SkillDetailResult> getSkillDetail(String skillId);
  Future<EvolutionGraphResult> getEvolutionGraph(String petId);
  Future<CatalogInfo> getCatalogInfo();
}

abstract interface class UserRepository {
  Future<void> setFavorite(ObjectRef object, bool enabled);
  Future<void> setCollected(String handbookId, bool collected);
  Future<void> saveNote(NoteDraft draft);
  Stream<List<FavoriteItem>> watchFavorites();
}

abstract interface class CatalogInstaller {
  Future<CatalogOpenResult> prepareBundledCatalog();
  Future<CatalogOpenResult> restoreBundledCatalog();
}
```

`ObjectRef` 必须包含 datasetId、objectType、objectId 和必要名称快照。真实接口可扩展分页和错误类型，但不允许将返回值改成直接暴露数据库连接或原始 API JSON。

### 19.4 Installer 的内部职责拆分

| 组件 | 只负责 |
|---|---|
| `BundledCatalogSource` | 读取安装包 manifest 与数据库资源 |
| `CatalogPackageValidator` | 验证元数据、哈希、结构与探测查询 |
| `CatalogFileStore` | 白名单目录内 staging、版本文件与指针持久化 |
| `CatalogConnectionFactory` | 使用正确只读配置打开连接，检查 schema |
| `CatalogInstaller` | 串联上述步骤，执行恢复状态机 |

后续远程来源可以实现新的 PackageSource，但不能因此替换 FileStore 或绕过 Validator。V1 不需要为尚未实现的远程来源增加空页面、计时器或后台服务。

### 19.5 CLI 契约

以下是实施后应提供的命令形式，**现在不能假设直接执行就存在**：

```bash
python -m bwiki_import import-local --input-dir <已有JSON目录> --output <快照目录>
python -m bwiki_import sync --sources config/bwiki_sources.json --output data/raw
python -m catalog_builder inspect --snapshot <snapshot目录>
python -m catalog_builder normalize --snapshot <snapshot目录> --offline
python -m catalog_builder validate --normalized <规范数据目录>
python -m catalog_builder diff --previous <旧规范数据目录> --current <新规范数据目录>
python -m catalog_builder build --normalized <目录> --data-version <正整数>
python tools/release/check_catalog.py --release <发布目录>
```

`inspect` 应输出顶层键、字段类型、数组 / 字典结构、记录计数、未知语法、引用集合和样本映射；不要求用户继续在终端手工截取字符串。

CLI 必须提供非零失败退出码，并区分输入错误、网络错误、解析错误、数据校验错误、写入错误。除专门的发布命令外，不得触发商店上传、远程推送或计费资源创建。

---

<a id="section-20"></a>

## 20. 分阶段实施计划与停止条件

### Phase 0：确认仓库、落地规范与测试基线

**目标：**建立边界明确的项目骨架，而不是立即写整个 App。

| 项目 | 要求 |
|---|---|
| 允许路径 | README、AGENTS、docs、config 模板、schemas、tools 的项目配置、测试基础 |
| 必做流程 | 确认正确仓库与 git 状态；保存规范；记录环境；落地 SQL；建立类型与测试约定 |
| 不做 | 网络修改、抓全站、正式 App 发布、付费服务、无关仓库重构 |
| 验收 | 目录与依赖边界可读，参考 SQL 可执行，测试命令能区分失败和成功 |
| 停止条件 | 工作区不是本项目或会覆盖用户现有文件，先报告范围冲突 |

### Phase 1：从已有快照完成数据结构检查与安全解析

**目标：**用用户已成功获取的文件完成机器可重复的结构验证。

| 项目 | 要求 |
|---|---|
| 允许路径 | `tools/bwiki_import/`、Parser、KeyExpander、adapters、相关 config、tests、data/raw、reports |
| 必做流程 | 导入现有 JSON → 校验正文 → 安全解析 → 展开字段 → 自动结构报告 → 样本实体映射 |
| 必须补齐 | Handbook、Evolution、SkillCatalog 全字段；Learnset stage 语义；未知字段清单 |
| 不做 | Flutter 页面、图片抓取、执行 Lua、上架、覆盖原 `/tmp` 文件 |
| 验收 | 全部 V1 必需模块能离线解析；三种魔力猫保持不同 petId 与共同 handbookId；技能映射闭合 |
| 停止条件 | 任何模块需要执行代码、存在未支持语法或无法确定关键字段，输出精确阻塞，不制造数据 |

若本机文件缺失，允许通过已定义 API Client 正常读取；失败则报告真实状态，不改网络环境。网络功能可测试，但不是每次单元测试的前提。

### Phase 2：构建规范数据库与发布数据包

**目标：**生成可重复构建、完整校验的真实 `catalog.db`。

| 项目 | 要求 |
|---|---|
| 允许路径 | schemas、validator、identity resolver、differ、writers、配置映射、tests、data/normalized、data/release |
| 必做流程 | 全量规范化 → 身份审计 → 引用校验 → 差异审查 → 建库 → 数据包校验 |
| 验收 | SQL 约束通过；关键查询正确；manifest 与 DB 一致；未审查删除 / 特性冲突为零 |
| 不做 | App 网络更新、用户系统、手工删除错误记录以通过测试 |
| 停止条件 | 核心覆盖不完整或存在未审阻断项；只保留诊断产物，不发布伪全量数据库 |

### Phase 3：Flutter 离线浏览与查询

**目标：**在两个平台上运行基础离线图鉴。

| 项目 | 要求 |
|---|---|
| 允许路径 | app 初始化、pubspec、必要平台生成文件、Catalog DAO、Repository、图鉴与技能页面、必要 Installer 初装路径、测试 |
| 必做流程 | 读取内置 DB → 只读连接 → Repository → 页面状态 → 列表 / 详情 / 搜索 / 形态切换 |
| 验收 | 飞行模式首启可用；查武斗酷猫直接进入对应 ID；技能来源与特性不混淆 |
| 不做 | 直接 BWIKI 请求、在线图片依赖、账号、复杂战斗模拟 |
| 停止条件 | ORM 与规范 SQL 不一致、只读库被自动建表、页面依赖在线数据 |

### Phase 4：收藏、收集标记与笔记

**目标：**完成可长期保留的个人数据层。

| 项目 | 要求 |
|---|---|
| 允许路径 | user schema / migrations、User DAO、UserRepository、collection 与关联按钮、测试 |
| 必做流程 | 创建个人库 → 幂等收藏 → 已收集标记 → 笔记 → 撤下条目兼容 |
| 验收 | 重启后保留；重复操作无重复行；写失败不丢编辑内容；对象缺失不删除笔记 |
| 不做 | 跨库外键、图鉴数据复制到个人表充当长期真值、云同步 |
| 停止条件 | 迁移失败会删除数据库或用户数据无法解释 |

### Phase 5：随 App 更新的整库替换与故障恢复

**目标：**把能浏览的 App 变成可安全升级的 App。

| 项目 | 要求 |
|---|---|
| 允许路径 | CatalogInstaller、文件 / 连接服务、bootstrap、设置中的恢复入口、integration tests |
| 必做流程 | 旧版安装 → 写收藏笔记 → 安装新 App 数据 → staging 验证 → 切换 / 失败回滚 |
| 验收 | 新增、修改、撤下生效；user.db 逻辑数据不变；强退 / 磁盘不足 / 错 schema 恢复正确 |
| 不做 | 在线补丁、直接覆盖打开的 DB、清空整个支持目录 |
| 停止条件 | 任何故障可能导致唯一可用库被覆盖或个人库丢失 |

### Phase 6：发布准备与最终验收

**目标：**得到可提交的应用构建与审计材料，正式上传仍须明确授权。

| 项目 | 要求 |
|---|---|
| 允许路径 | release tools、CI、版本元数据、必要平台发布配置、许可说明、测试报告 |
| 必做流程 | 锁定数据包 → 验证真机离线 / 更新 → 审核权限 → 核对来源许可 → 生成待提交构建 |
| 验收 | 数据可追溯；未完成范围已如实说明；无网络依赖、凭证、示例哈希或测试假数据混入 |
| 不做 | 未经授权上传商店、自动推送 main、创建付费托管服务 |
| 停止条件 | 发布许可、平台兼容性或关键真机测试未完成 |

### Phase 7：可选的独立全量 / 增量更新

不属于 V1。必须新建范围说明，重新确认资源托管、签名、平台规则、协议版本、下载权限与故障测试。先全量、后增量，不能作为前六个阶段的隐性依赖。

---

<a id="section-21"></a>

## 21. 验收矩阵与质量门禁

### 21.1 数据导入与解析测试

| 测试 ID | 场景 | 期望 |
|---|---|---|
| IMP-001 | 正常 siteinfo / revision JSON | 正确识别站点、页面与修订 |
| IMP-002 | HTTP 200 但 HTML | 分类为非 API 正文，拒绝构建 |
| IMP-003 | API error / missing / invalid | 输出具体错误，不变成空数据 |
| IMP-004 | 429 / Retry-After / 超时 | 有限退避，不高并发重试 |
| IMP-005 | revision 与锁文件不一致 | 拒绝纳入冻结快照 |
| IMP-006 | 有效 JSON 但正文被替换 | 大小 / 哈希 / 解析检查识别问题 |
| IMP-007 | 多 slot 与总大小不同 | 按 slot 校验，不误判正文截断 |
| IMP-008 | 部分模块失败 | 旧快照可用，新快照不发布 |
| PAR-001 | UTF-8、引号、转义、注释 | 正确保留文本与数据类型 |
| PAR-002 | 空表、数组、显式键、混合表 | 保留结构，由 adapter 判断 |
| PAR-003 | 函数调用、require、循环 | 拒绝执行，错误含源位置 |
| PAR-004 | 元数据映射键冲突 | 明确失败，不覆盖字段 |
| PAR-005 | 未知字段 | 保留并进入报告，不静默丢弃 |
| PAR-006 | 超大 / 深嵌套输入 | 有上限的受控失败 |

### 21.2 领域数据测试

| 测试 ID | 场景 | 期望 |
|---|---|---|
| DAT-001 | 三种魔力猫 | 三个 petId，共享 handbook_000004 |
| DAT-002 | 魔力猫特性 | Core 与已见 Learnset 都引用 skill_000003；目录名为氧循环 |
| DAT-003 | 共享 Learnset | 多个精灵可复用同一集合，不复制或错误覆盖 |
| DAT-004 | 同技能多学习方式 | 原生、血脉、技能石条件全部保留 |
| DAT-005 | stage=1 的共享记录 | 不因当前精灵 stage=3 自动删除技能 |
| DAT-006 | 所有引用完整 | pet、handbook、skill、learnset、evolution 引用均可解释 |
| DAT-007 | 特性来源冲突 | 产生精确审查项，可按已核实覆盖规则处理 |
| DAT-008 | 上游改名 / ID 复用 | 改名不丢身份；ID 复用必须阻断自动映射 |
| DAT-009 | 某模块为空 | 不产生全量删除补丁或假正常发布 |
| DAT-010 | 图鉴 ID 尾数与编号不同 | 显示编号仍来自已验证映射 |
| DAT-011 | 同组但无方向证据 | 不生成进化箭头 |
| DAT-012 | desc_notes 无解释源 | 保留引用、明确缺失，不生成假解释 |
| DAT-013 | NULL、0、false | 数据与 UI 语义不同 |
| DAT-014 | 未使用可选模块 | coverage 如实为 false，核心查询不受影响 |

### 21.3 SQL、App 与更新测试

| 测试 ID | 场景 | 期望 |
|---|---|---|
| DB-001 | 创建 Catalog / User schema | 表、视图、索引可创建，结构检查通过 |
| DB-002 | 外键与唯一约束 | 悬空引用与重复槽位被拒绝 |
| DB-003 | 正式 Catalog 只读 | 写入被拒绝，不触发自动建表 |
| DB-004 | ORM 与规范 SQL | 字段、类型、外键、默认值与版本一致 |
| DB-005 | personal 对象缺失 | 仍保留收藏与笔记 |
| APP-001 | 飞行模式首次启动 | 内置数据安装并可查询 |
| APP-002 | 搜索特殊形态 | 直接进入正确 petId，编号仍正确 |
| APP-003 | 切换形态 | 特性、资质、技能、收藏对象全部切换 |
| APP-004 | 查询并发与页面返回 | 旧结果不覆盖新筛选，无订阅泄漏 |
| APP-005 | 字体放大 / 深浅主题 | 内容可读、无关键按钮遮挡 |
| UPD-001 | 同 App 数据版本重复启动 | 不反复复制、清空或迁移 |
| UPD-002 | 旧数据到新内置数据 | 内容变化正确，个人数据逻辑快照不变 |
| UPD-003 | 复制中强退 | 旧版本仍可用或下次安全恢复 |
| UPD-004 | 错误 SHA / schema / dataset | 拒绝安装，不覆盖旧库 |
| UPD-005 | 指针写入后打开失败 | 回退到前一有效版本 |
| UPD-006 | 空间不足 | 受控错误，无个人数据损失 |
| UPD-007 | 恢复内置图鉴 | 只影响 catalog，保留 user.db |
| UPD-008 | 个人库迁移失败 | 不 catch 后删库重建 |
| REL-001 | 产物带 WAL / 未完成事务 | 发布检查拒绝或规范收尾后重新验证 |
| REL-002 | 示例数据 / 示例哈希混入 | 发布门禁拒绝 |
| REL-003 | 未通过可选模块却显示已覆盖 | 发布门禁拒绝 |

### 21.4 质量等级与放行条件

| 级别 | 示例 | 是否可发布 |
|---|---|---|
| Fatal | 必需模块读失败、解析失败、非法引用、schema 错误、ID 复用 | 不可 |
| ReviewRequired | 特性冲突、默认形态不明确、疑似删除 | 完成具体审查后才可 |
| Warning | 明确不在 V1 的模块缺失、可选描述为空 | 可，但 coverage 与 UI 必须如实 |
| Info | 修订未变、缓存复用、重复内容引用 | 可，记录即可 |

豁免规则必须带 rule ID、对象 ID、限定的来源 revision 或条件、原因、审查记录。禁止 `ignore_all_errors=true`、全局忽略外键或按异常类型一律放行。

### 21.5 “完成”的证据

每阶段报告必须列出实际运行的命令、通过 / 失败 / 未运行的测试、已修改文件、生成产物、剩余风险与下一阶段允许范围。不能只写“测试通过”而省略哪些测试未运行。

本文附录中的本地 SQL 检查只是规范自检，不表示以上所有测试已经实现或通过。

---

<a id="section-22"></a>

## 22. CI、版本治理与交付纪律

### 22.1 默认 CI

建议 CI 运行静态检查、格式化校验、Parser / Adapter fixture 测试、schema 执行测试、Repository 测试和 manifest 校验。默认不访问 BWIKI，不需要个人 Cookie、代理配置或商店发布密钥。

联网导入应为独立手动任务或明确授权的受限计划任务；不能把上游临时不可达变成每个 PR 都失败。需要真机的 iOS / Android 升级测试与普通单元测试分开标记。

### 22.2 变更分类

| 变更 | 必须同步 |
|---|---|
| 上游字段映射 | adapter 版本、fixture、映射说明、回归结果 |
| 本地主键或身份映射 | identity registry、旧收藏兼容审查、差异报告 |
| SQL 列 / 约束 / 视图 | schema、Drift 类型、Repository、兼容性说明 |
| UI 默认展示规则 | 默认映射、交互测试、数据语义说明 |
| 安装与恢复流程 | 状态机、故障注入测试、平台实现核对 |
| 数据源 / 许可 | 来源记录、许可页、发布检查 |
| 独立在线更新 | 新 ADR、协议与签名设计、额外授权 |

### 22.3 禁止混合大提交

一次任务尽量对应一个阶段或一个明确模块。新增 API Client 不应同时重做主题、迁移个人库和调整发布签名；发现其他问题应写入待办，不趁机扩大修改范围。

生成文件必须可追溯到生成命令与源文件；禁止只改生成的 Dart 文件而不改源定义。锁文件变更要说明原因，不自动升级无关依赖。

### 22.4 发布内容核对

最终发布物至少包含：App 构建、Catalog 数据版本、source lock 标识、数据库 SHA-256、校验报告、来源署名、已知限制和更新说明。没有完整来源证据或存在未审查删减时，不应以“离线数据库已经生成”为由跳过审查。

---

<a id="section-23"></a>

## 23. 来源、许可与素材范围

### 23.1 数据使用边界

BWIKI 当前相关页面标注 CC BY-NC-SA 4.0。许可摘要要求适当署名、提供许可链接、标明修改、非商业使用，并对适用的演绎内容采用相同许可；也不应暗示原作者或平台为本 App 背书。[R10][R11]

本项目需在关于页、数据包署名文件与源记录中保留这些信息。数据格式转换、标准化和人工修正应说明。App 自己的程序代码与第三方数据许可分别记录，不简单把整个仓库都标为同一种数据许可。

### 23.2 不能作出的保证

非商业不等于一切内容都无需授权；数据页面许可也不自动证明所有底层游戏美术、商标或其他第三方内容的权利均被涵盖。来源声明不是法律审批，也不能保证应用商店审核结果。

按用户要求，本文不展开独立素材方案。实施阶段只处理资源引用与本地缺图占位，不自动下载、转存或打包全部游戏图片。

### 23.3 建议署名模板

```text
资料来源：《洛克王国：世界》BWIKI 及相应贡献者。
本应用为非官方、非商业的离线资料工具，与游戏运营方及 BWIKI 无隶属关系。
对适用的 Wiki 内容，依其标注的 CC BY-NC-SA 4.0 协议使用。
本数据包进行了结构转换、字段规范化及已注明的资料修正。
来源页面、具体修订、许可链接与修改说明见“资料来源”。
```

真实署名还须保留来源已经提供的创作者、版权或免责等标识，不能仅复制模板就认为所有义务均已履行。发布前按实际内容核对，不添加未经证实的“官方授权”字样。

---

<a id="section-24"></a>

## 24. 风险登记与范围调整

| 风险 | 当前状态 | 缓解措施 | 不允许的捷径 |
|---|---|---|---|
| 上游结构变化 | 必须长期预期 | revision 锁、adapter 版本、fixture、未知字段报告 | 静默丢字段 |
| 上游分模块更新不同步 | 尚无原子发布保证 | 冻结 revision、首尾检查、全引用验证 | 把大小一致当作语义正确 |
| ID 重排或复用 | 没有永久稳定承诺 | 身份锁与人工重映射 | 按名称自动合并全部对象 |
| Handbook / Evolution 字段未全检 | Phase 1 待补齐 | 自动结构报告、真实记录映射测试 | 根据编号猜进化 |
| 部分附加模块非 JSON | 原因未知 | 记录状态与正文摘要，可选范围明确关闭 | 改系统网络、绕过访问限制 |
| 技能注释定义缺失 | 当前只知引用 ID | 保留引用、关闭未实现解释 UI | 编造术语说明 |
| 图鉴替换误删用户数据 | 高影响工程风险 | 分库、限定目录、故障注入 | 整个数据目录重置 |
| 全量源数据未交付本环境 | 当前文档限制 | 实施工具在用户已选工作区读取真实文件 | 声称已全量验证 |
| 上架与内容许可 | 发布阶段需核对 | 署名、许可、非官方说明、明确素材边界 | 宣称非商业必然可上架 |
| 过早实现服务器与补丁 | 可避免的范围风险 | 先随 App 发布，实际测量后再扩展 | 为离线手册引入复杂后端 |

第一版若要删减某项必需功能，必须同步更新产品范围、coverage、页面、验收和发布说明；不能仅通过在 Validator 中取消检查来实现“缩减”。

---

<a id="section-25"></a>

## 25. 交给 Codex 的执行提示词与任务模板

### 25.1 总控提示词

```text
请将本 Markdown 文档作为《洛克王国：世界》离线精灵手册的实施规范。

本次只执行我指定的阶段，不自动跨阶段，不提前做在线补丁或服务器。
开始前确认当前仓库确实属于本项目，读取 git status、AGENTS.md、README 与本文。
如果当前工作区是其他项目，停止在该工作区写入并报告范围冲突。

必须区分：用户终端已验证事实、本文设计决策、仍待真实数据验证的项。
不得声称读取了未提供的完整 JSON，不得按网页表象或 ID 尾数猜字段。
优先用已有 BWIKI JSON 快照在项目内建立可重复的离线检查流程。
不执行下载 Lua，不以正则替换代替安全解析器，不让 App 直接请求 BWIKI。

代码修改严格限制在该阶段的允许路径。
需要改公共接口或越界文件时先列出必要性、影响与测试，不能顺手重构其他模块。
禁止修改系统代理、TUN、DNS、路由、证书、Shell 配置或 Shadowrocket。
禁止删除用户已有改动、force push、擅自推送 main、上传商店或创建付费资源。

catalog.db 和 user.db 必须分开。
图鉴更新只能替换图鉴；个人数据库迁移失败不得删库重建。
所有源引用、版本、空值、特性差异、共享 Learnset 和撤下对象都按本文规则处理。

开始时输出：阶段目标、允许修改文件、明确不做项、验收命令。
完成后输出：实际改动、实际运行的测试、未运行项、阻塞项和下一阶段入口。
不要仅描述计划；在当前授权范围内实施并提供实际结果。
```

### 25.2 单模块任务模板

```text
任务名称：
所属阶段：
输入文件 / 已选仓库：
已验证的事实：
需要补齐的验证：
允许修改的路径：
禁止修改的路径：
需要保持不变的公共接口：
预期产物：
测试与验收：
失败 / 停止条件：
是否允许联网：
是否允许提交 / 推送 / 发布：默认不允许，除非另行明确授权。
```

### 25.3 本项目建议的第一项真实代码任务

执行 Phase 0 后，第一项实质任务应是 **“将已有 API JSON 快照导入项目，安全解析并生成结构与引用报告”**，不是先做华丽页面或补丁服务器。

交付应包含：输入文件清单与哈希、各模块记录数、未知字段、三种魔力猫映射、魔力猫 Learnset 与氧循环关系、Handbook / Evolution 待解决字段和可运行测试。达到这些要求后再进入真实全量数据库构建。

---

<a id="appendix-a"></a>

# 附录 A：`catalog.db` 参考 SQL

这是本项目自己的 V1 规范结构，不是 BWIKI 原始建表 SQL。具体源字段到本地列的适配仍须通过 Phase 1；禁止为了填满列而臆造值。

实施时保存为 `schemas/catalog_v1.sql`。以下脚本面向新建数据库；不要直接在正在使用的数据库上执行它来“升级”。

```sql
-- catalog.db：构建端可写，正式 App 只读。
-- 外键开关必须在事务之外设置；每个写连接都必须显式启用。
PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

BEGIN;

CREATE TABLE catalog_meta (
    singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
    dataset_id TEXT NOT NULL,
    schema_version INTEGER NOT NULL CHECK (schema_version = 1),
    data_version INTEGER NOT NULL CHECK (data_version > 0),
    snapshot_id TEXT NOT NULL,
    adapter_version TEXT NOT NULL,
    builder_version TEXT NOT NULL,
    built_at_utc TEXT NOT NULL,
    coverage_json TEXT NOT NULL
);

CREATE TABLE source_revisions (
    source_ref TEXT PRIMARY KEY NOT NULL,
    source_key TEXT NOT NULL,
    source_name TEXT NOT NULL,
    requested_title TEXT NOT NULL,
    canonical_title TEXT NOT NULL,
    page_id INTEGER NOT NULL CHECK (page_id > 0),
    revision_id INTEGER NOT NULL CHECK (revision_id > 0),
    revised_at_utc TEXT NOT NULL,
    fetched_at_utc TEXT NOT NULL,
    content_bytes INTEGER NOT NULL CHECK (content_bytes >= 0),
    api_sha1 TEXT,
    content_sha256 TEXT NOT NULL CHECK (length(content_sha256) = 64),
    source_url TEXT NOT NULL,
    attribution_text TEXT NOT NULL,
    license_id TEXT NOT NULL,
    UNIQUE (source_key, revision_id)
);

CREATE TABLE handbook_entries (
    handbook_id TEXT PRIMARY KEY NOT NULL,
    dex_no TEXT,
    display_name TEXT,
    sort_order INTEGER,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired'))
);

CREATE TABLE types (
    type_id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE skills (
    skill_id TEXT PRIMARY KEY NOT NULL,
    upstream_numeric_id INTEGER,
    name TEXT NOT NULL,
    category TEXT,
    element_raw TEXT,
    type_id TEXT REFERENCES types(type_id),
    description TEXT,
    energy_value REAL,
    energy_text TEXT,
    power_value REAL,
    power_text TEXT,
    target_text TEXT,
    icon_key TEXT,
    extra_json TEXT NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired'))
);

CREATE TABLE skill_description_notes (
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    note_id TEXT NOT NULL,
    PRIMARY KEY (skill_id, ordinal)
);

CREATE TABLE pets (
    pet_id TEXT PRIMARY KEY NOT NULL,
    handbook_id TEXT REFERENCES handbook_entries(handbook_id),
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    form TEXT,
    class_name TEXT,
    description TEXT,
    stage INTEGER CHECK (stage IS NULL OR stage >= 0),
    belong_season_raw TEXT,
    starlight INTEGER,
    review_gold INTEGER,
    height_text TEXT,
    weight_text TEXT,
    can_double_ride INTEGER CHECK (can_double_ride IN (0, 1)),
    has_shiny INTEGER CHECK (has_shiny IN (0, 1)),
    is_lord_evolution INTEGER CHECK (is_lord_evolution IN (0, 1)),
    hide_entry_name INTEGER CHECK (hide_entry_name IN (0, 1)),
    show_topics INTEGER CHECK (show_topics IN (0, 1)),
    feature_skill_id TEXT REFERENCES skills(skill_id),
    hp INTEGER CHECK (hp IS NULL OR hp >= 0),
    atk INTEGER CHECK (atk IS NULL OR atk >= 0),
    def INTEGER CHECK (def IS NULL OR def >= 0),
    spa INTEGER CHECK (spa IS NULL OR spa >= 0),
    spd INTEGER CHECK (spd IS NULL OR spd >= 0),
    spe INTEGER CHECK (spe IS NULL OR spe >= 0),
    illustration_key TEXT,
    head_key TEXT,
    extra_json TEXT NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired'))
);

-- 默认卡片选择独立保存，以免 handbook_entries 与 pets 形成插入环。
-- 它是展示选择，不等于游戏规则或新的官方编号。
CREATE TABLE handbook_display (
    handbook_id TEXT PRIMARY KEY NOT NULL
        REFERENCES handbook_entries(handbook_id),
    default_pet_id TEXT NOT NULL REFERENCES pets(pet_id),
    selection_reason TEXT NOT NULL
);

CREATE TABLE pet_aliases (
    pet_id TEXT NOT NULL REFERENCES pets(pet_id),
    alias TEXT NOT NULL,
    alias_kind TEXT NOT NULL,
    PRIMARY KEY (pet_id, alias, alias_kind)
);

CREATE TABLE pet_types (
    pet_id TEXT NOT NULL REFERENCES pets(pet_id),
    slot INTEGER NOT NULL CHECK (slot > 0),
    type_id TEXT NOT NULL REFERENCES types(type_id),
    PRIMARY KEY (pet_id, slot),
    UNIQUE (pet_id, type_id)
);

CREATE TABLE learnsets (
    learnset_id TEXT PRIMARY KEY NOT NULL,
    feature_skill_id TEXT REFERENCES skills(skill_id),
    extra_json TEXT NOT NULL DEFAULT '{}'
);

CREATE TABLE pet_learnsets (
    pet_id TEXT PRIMARY KEY NOT NULL REFERENCES pets(pet_id),
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id)
);

CREATE TABLE learnset_native_skills (
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    learn_level INTEGER CHECK (learn_level IS NULL OR learn_level >= 0),
    source_stage INTEGER CHECK (source_stage IS NULL OR source_stage >= 0),
    PRIMARY KEY (learnset_id, ordinal)
);

CREATE TABLE learnset_blood_skills (
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    blood_raw TEXT NOT NULL,
    blood_type_id TEXT REFERENCES types(type_id),
    learn_level INTEGER CHECK (learn_level IS NULL OR learn_level >= 0),
    PRIMARY KEY (learnset_id, ordinal)
);

CREATE TABLE learnset_skill_stones (
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    PRIMARY KEY (learnset_id, ordinal)
);

CREATE TABLE evolution_groups (
    evolution_group_id TEXT PRIMARY KEY NOT NULL,
    label TEXT,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired'))
);

CREATE TABLE pet_evolution_groups (
    evolution_group_id TEXT NOT NULL
        REFERENCES evolution_groups(evolution_group_id),
    pet_id TEXT NOT NULL REFERENCES pets(pet_id),
    source_order INTEGER CHECK (source_order IS NULL OR source_order >= 0),
    PRIMARY KEY (evolution_group_id, pet_id)
);

CREATE TABLE evolution_edges (
    evolution_group_id TEXT NOT NULL,
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    from_pet_id TEXT NOT NULL,
    to_pet_id TEXT NOT NULL,
    method_code TEXT,
    level_requirement INTEGER
        CHECK (level_requirement IS NULL OR level_requirement >= 0),
    condition_text TEXT,
    condition_json TEXT NOT NULL DEFAULT '{}',
    PRIMARY KEY (evolution_group_id, ordinal),
    FOREIGN KEY (evolution_group_id, from_pet_id)
        REFERENCES pet_evolution_groups(evolution_group_id, pet_id),
    FOREIGN KEY (evolution_group_id, to_pet_id)
        REFERENCES pet_evolution_groups(evolution_group_id, pet_id)
);

-- 多态溯源关系由 Builder 做实体存在性校验；不能用一条 SQL 外键
-- 同时引用 pets / skills / learnsets 等不同实体表。
CREATE TABLE entity_sources (
    entity_kind TEXT NOT NULL CHECK (entity_kind IN
        ('pet', 'handbook', 'skill', 'learnset', 'evolution_group')),
    entity_id TEXT NOT NULL,
    source_ref TEXT NOT NULL REFERENCES source_revisions(source_ref),
    source_record_key TEXT NOT NULL,
    PRIMARY KEY (entity_kind, entity_id, source_ref, source_record_key)
);

CREATE INDEX idx_handbooks_order
    ON handbook_entries(status, sort_order, handbook_id);
CREATE INDEX idx_pets_handbook ON pets(handbook_id, status);
CREATE INDEX idx_pets_name ON pets(name);
CREATE INDEX idx_pets_title ON pets(title);
CREATE INDEX idx_pets_speed ON pets(status, spe, pet_id);
CREATE INDEX idx_pets_atk ON pets(status, atk, pet_id);
CREATE INDEX idx_pets_spa ON pets(status, spa, pet_id);
CREATE INDEX idx_pet_aliases_alias ON pet_aliases(alias);
CREATE INDEX idx_pet_types_type ON pet_types(type_id, pet_id);
CREATE INDEX idx_skills_name ON skills(name);
CREATE INDEX idx_skills_filter ON skills(status, category, type_id);
CREATE INDEX idx_pet_learnsets_learnset ON pet_learnsets(learnset_id, pet_id);
CREATE INDEX idx_native_skill ON learnset_native_skills(skill_id, learnset_id);
CREATE INDEX idx_blood_skill ON learnset_blood_skills(skill_id, learnset_id);
CREATE INDEX idx_stone_skill ON learnset_skill_stones(skill_id, learnset_id);
CREATE INDEX idx_evolution_members_pet
    ON pet_evolution_groups(pet_id, evolution_group_id);
CREATE INDEX idx_evolution_edges_to ON evolution_edges(to_pet_id);
CREATE INDEX idx_entity_sources_source ON entity_sources(source_ref);

-- UI 统一读取技能来源，但不丢弃血脉、等级、阶数和原始顺序。
-- UNION ALL 是有意选择：同一技能的多种学习方式必须保留。
CREATE VIEW pet_skill_sources AS
SELECT p.pet_id, l.learnset_id, n.skill_id,
       'native' AS source_kind, n.learn_level,
       n.source_stage, NULL AS blood_raw, n.ordinal
FROM pets p
JOIN pet_learnsets l ON l.pet_id = p.pet_id
JOIN learnset_native_skills n ON n.learnset_id = l.learnset_id
WHERE p.status = 'active'
UNION ALL
SELECT p.pet_id, l.learnset_id, b.skill_id,
       'blood', b.learn_level, NULL, b.blood_raw, b.ordinal
FROM pets p
JOIN pet_learnsets l ON l.pet_id = p.pet_id
JOIN learnset_blood_skills b ON b.learnset_id = l.learnset_id
WHERE p.status = 'active'
UNION ALL
SELECT p.pet_id, l.learnset_id, s.skill_id,
       'stone', NULL, NULL, NULL, s.ordinal
FROM pets p
JOIN pet_learnsets l ON l.pet_id = p.pet_id
JOIN learnset_skill_stones s ON s.learnset_id = l.learnset_id
WHERE p.status = 'active';

-- Core 优先、Learnset 为缺值后备。冲突必须先在构建报告中解释，
-- 不能靠这个视图掩盖不一致；特性不混入“可学习主动技能”列表。
CREATE VIEW pet_feature_skills AS
SELECT p.pet_id,
       COALESCE(p.feature_skill_id, s.feature_skill_id) AS skill_id,
       CASE WHEN p.feature_skill_id IS NOT NULL THEN 'core'
            WHEN s.feature_skill_id IS NOT NULL THEN 'learnset'
            ELSE 'missing' END AS resolution_source
FROM pets p
LEFT JOIN pet_learnsets l ON l.pet_id = p.pet_id
LEFT JOIN learnsets s ON s.learnset_id = l.learnset_id
WHERE p.status = 'active';

COMMIT;
```

---

<a id="appendix-b"></a>

# 附录 B：`user.db` 参考 SQL

实施时保存为 `schemas/user_v1.sql`。以下脚本用于新建个人数据库；已有用户数据只能通过对应迁移升级，不得删除后重建。

```sql
-- user.db：只保存个人数据，独立迁移；不引用 catalog.db 外键。
PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

BEGIN;
CREATE TABLE user_meta (
    singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
    schema_version INTEGER NOT NULL CHECK (schema_version > 0),
    created_at_utc TEXT NOT NULL
);

CREATE TABLE favorites (
    dataset_id TEXT NOT NULL,
    object_type TEXT NOT NULL CHECK (object_type IN ('pet', 'skill', 'handbook')),
    object_id TEXT NOT NULL,
    name_snapshot TEXT NOT NULL,
    created_at_utc TEXT NOT NULL,
    PRIMARY KEY (dataset_id, object_type, object_id)
);

-- V1 的“已收集”标记以图鉴条目为单位，不自动表示所有形态已拥有。
CREATE TABLE collection_marks (
    dataset_id TEXT NOT NULL,
    handbook_id TEXT NOT NULL,
    collected INTEGER NOT NULL CHECK (collected IN (0, 1)),
    name_snapshot TEXT NOT NULL,
    updated_at_utc TEXT NOT NULL,
    PRIMARY KEY (dataset_id, handbook_id)
);

CREATE TABLE notes (
    note_id TEXT PRIMARY KEY NOT NULL,
    dataset_id TEXT NOT NULL,
    object_type TEXT NOT NULL CHECK (object_type IN ('pet', 'skill', 'handbook')),
    object_id TEXT NOT NULL,
    name_snapshot TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at_utc TEXT NOT NULL,
    updated_at_utc TEXT NOT NULL
);

CREATE TABLE settings (
    setting_key TEXT PRIMARY KEY NOT NULL,
    value_json TEXT NOT NULL,
    updated_at_utc TEXT NOT NULL
);

CREATE INDEX idx_favorites_created ON favorites(created_at_utc);
CREATE INDEX idx_notes_object ON notes(dataset_id, object_type, object_id);
COMMIT;
```

---

<a id="appendix-c"></a>

# 附录 C：API 与原始快照参数契约

## C.1 已由用户验证过的查询形式

```text
endpoint = https://wiki.biligame.com/rocom/api.php
method = GET

action = query
prop = revisions
titles = Module:PetData/Core
rvprop = ids|timestamp|size|sha1|content
rvslots = main
format = json
formatversion = 2
```

用于正文检查的路径为 `query.pages[*].revisions[0].slots.main.content`。标题可能被站点规范化为中文命名空间，如 `模块:PetData/Core`；应按返回的 page ID、规范标题与模块清单匹配，不能因 `Module` 变成 `模块` 就误判数据源不同。

## C.2 正式客户端的增强形式

元数据阶段不请求 content。正文阶段可使用冻结的 `revids`；不要同时混入含义冲突的 titles / revision 过滤参数。实例支持时可增加 roles、slotsize、slotsha1、contentmodel，先检测支持再使用，不把不支持的参数警告忽略掉。

一次读取一份数据模块足以实现自动全量导入；使用多个标题只是优化。正文引用的 `pet_*`、`skill_*` 数量与 API 分页限制无直接对应关系。

## C.3 Source lock 示例

```json
{
  "lock_version": 1,
  "dataset_id": "roco-world-zh-cn",
  "snapshot_id": "example-only",
  "sources": [
    {
      "source_key": "core",
      "requested_title": "Module:PetData/Core",
      "canonical_title": "模块:PetData/Core",
      "page_id": 13216,
      "revision_id": 43006,
      "revised_at_utc": "2026-08-13T03:58:53Z",
      "content_bytes": 394098,
      "api_sha1": "e3425aada1f5c0b2c70eed5aa619483bb80856b5",
      "content_sha256": null,
      "response_sha256": null,
      "validation_state": "example-not-frozen"
    }
  ]
}
```

这是用已提供字段解释锁文件结构的示例，不是完整可发布快照。两个 SHA-256 尚未由本环境取得完整文件计算，故明确为 null；真实冻结流程必须补齐，且来源集合不能只有 Core。

## C.4 数据删除判定禁止事项

不能通过以下任一单独现象生成删除：HTTP 失败、JSON 失败、模块 `missing`、返回数组为空、解析条数为零、字段名改变、只读到半份模块。候选删除必须建立在新的完整快照与已验证身份映射上，并进入人工审查。

---

<a id="appendix-d"></a>

# 附录 D：已观察到的 `_meta.key` 映射

以下字典来自用户贴出的 LearnsetCatalog 片段，用于回归样本与文档说明。实际解析必须读取当前快照的元数据，并检测差异；不能把这个历史字典写死为永不变化的事实。

```json
{
  "at": "atk",
  "bl": "blood",
  "bs": "blood_skills",
  "bsn": "belong_season",
  "c": "class",
  "d": "description",
  "df": "def",
  "dr": "can_double_ride",
  "eg": "egg",
  "egp": "egg_group",
  "evg": "evolution_groups",
  "f": "form",
  "fm": "female",
  "fr": "fruit",
  "frs": "fruits",
  "fs": "feature_skill",
  "gr": "gender_ratio",
  "hb": "handbook",
  "hd": "head",
  "he": "handbook_entry",
  "heg": "has_egg",
  "hen": "hide_entry_name",
  "hfr": "has_fruit",
  "hi": "handbook_id",
  "hp": "hp",
  "hs": "has_shiny",
  "ht": "height",
  "htl": "handbook_title",
  "i": "id",
  "il": "illustration",
  "img": "image",
  "le": "is_lord_evolution",
  "lg": "legendary",
  "lv": "level",
  "m": "male",
  "n": "name",
  "ns": "native_skills",
  "pn": "pet_name",
  "rc": "recipe",
  "rcc": "recipe_count",
  "rg": "review_gold",
  "rq": "requires",
  "sa": "spa",
  "sc": "skill_count",
  "sd": "spd",
  "se": "spe",
  "sg": "stage",
  "sk": "skill",
  "sl": "starlight",
  "ss": "skill_stones",
  "st": "stats",
  "stp": "show_topics",
  "t": "title",
  "tg": "target",
  "ti": "topic_id",
  "to": "topic",
  "tp": "types",
  "tps": "topic_points",
  "wt": "weight"
}
```

确认英文键名并不自动证明字段完整业务语义。例如 `starlight` 不能凭名称被改解释成“解锁等级”；`stage` 在精灵本体和学习记录中的作用也必须分别核对。

---

<a id="appendix-e"></a>

# 附录 E：本文 SQL 自检记录与可复核方法

## E.1 实际运行范围

本文编写时，在 SQLite **3.46.1** 的内存数据库中，对附录 A / B 的参考结构运行 **30 项结构与样本单元测试，最终全部通过**。

使用的数据包括用户已贴出的 ID、三种魔力猫的六项资质、已见 Learnset 关联，以及明确标为测试用途的合成记录。未给出真实技能名称的测试引用使用了测试占位文字，未生成可发布游戏数据包。

| 自检范围 | 结果 |
|---|---|
| 19 张 Catalog 表、2 个视图、5 张 User 表及 schema 版本 | 通过 |
| integrity_check、foreign_key_check 与外键开关 | 通过 |
| 三种魔力猫共用同一图鉴、各自资质独立 | 通过 |
| 特性查询、Learnset 后备与共享集合 | 通过 |
| 原生、血脉、技能石来源与重复技能条件保留 | 通过 |
| 不按当前精灵阶数误删共享集合记录 | 通过 |
| 负资质、非法布尔、NULL 主键、重复槽位、缺失引用拒绝 | 通过 |
| 进化边成员约束，同组不会自动生成方向 | 通过 |
| NULL 与零、同名不同 ID、来源历史修订保留 | 通过 |
| 收藏唯一约束、缺失对象笔记保留、两库逻辑隔离 | 通过 |
| 事务回滚、撤下对象视图过滤、SQL 只读保护 | 通过 |

这不是全量 BWIKI 数据校验，也不是 Flutter、Drift、文件原子切换、签名、商店更新或 iOS / Android 真机验证。第 21 章是实施阶段的验收要求，不能把这里的 30 项 SQL 测试当作它们全部通过。

## E.2 已知样本字段表

| 名称 | pet_id | HP | ATK | DEF | SPA | SPD | SPE |
|---|---|---:|---:|---:|---:|---:|---:|
| 魔力猫 | pet_000007 | 108 | 109 | 81 | 109 | 151 | 55 |
| 叶冕魔力猫 | pet_000538 | 108 | 127 | 81 | 127 | 151 | 55 |
| 武斗酷猫 | pet_000595 | 126 | 134 | 110 | 57 | 80 | 135 |

以上为用户抓取快照中的值，不是本文对当前游戏数值的重新核验或永久保证。后续源资料变更时，应更新快照与对应测试预期，而不是要求新数据永远等于历史值。

## E.3 仅复核参考 SQL 建库的最小脚本

以下脚本只在内存中创建数据库，不访问网络、不修改系统设置，也不创建真实 App 数据库。它复核 DDL 能否执行与基本结构检查，不代替上述完整单元测试或真实数据验证。

```python
from pathlib import Path
import re
import sqlite3
import sys

if len(sys.argv) != 2:
    raise SystemExit("用法：python verify_document_sql.py <本文Markdown路径>")

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
blocks = re.findall(r"```sql\n(.*?)\n```", text, flags=re.S)
if len(blocks) != 2:
    raise SystemExit(f"应找到 Catalog 和 User 两个 SQL 块，实际：{len(blocks)}")

for label, sql, expected_tables in zip(
    ("catalog", "user"), blocks, (19, 5)
):
    connection = sqlite3.connect(":memory:")
    try:
        connection.executescript(sql)
        tables = connection.execute(
            "SELECT count(*) FROM sqlite_master WHERE type='table'"
        ).fetchone()[0]
        integrity = connection.execute("PRAGMA integrity_check").fetchall()
        foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
        if tables != expected_tables or integrity != [("ok",)] or foreign_keys:
            raise RuntimeError((label, tables, integrity, foreign_keys))
        print(f"{label}: schema OK, tables={tables}")
    finally:
        connection.close()
```

---

<a id="appendix-f"></a>

# 附录 F：技术来源与引用说明

E01—E05 引用本次会话中用户实际提供的终端输出与源码片段；没有为不存在的上传文件制造文件链接。以下为编写时核对的官方 / 原始来源，访问日期为 **2026-09-09**。技术实现仍应以实施时锁定的软件版本和该 BWIKI 实例实际能力为准。

| 编号 | 来源 | 本文用途 |
|---|---|---|
| [R01] | MediaWiki：API Revisions | 修订、正文、slot、大小与查询参数 |
| [R02] | MediaWiki：API Etiquette | API 请求礼仪、限流与负载处理 |
| [R03] | Flutter：Guide to app architecture | UI 与数据层分离、职责方向 |
| [R04] | Drift：Importing and exporting databases | 预置数据库与本地导入 |
| [R05] | Riverpod：Getting started | 页面状态与依赖组织工具依据 |
| [R06] | SQLite：Foreign Key Support | 外键启用、约束与跨 schema 限制 |
| [R07] | SQLite：Atomic Commit | SQLite 事务机制与外部文件流程的区分 |
| [R08] | Android Developers：Upload your app to Play Console | 应用构建、版本与商店分发流程 |
| [R09] | Apple Developer：Doing advanced optimization to further reduce your app’s size | App 更新包与实际下载体积边界 |
| [R10] | Creative Commons：CC BY-NC-SA 4.0 中文许可摘要 | 署名、修改说明、非商业与相同方式共享 |
| [R11] | 《洛克王国：世界》BWIKI：模块 Pet | 模块依赖、字段展开与页面上的数据许可标注 |
| [R12] | SQLite：Online Backup API | 一致性备份参考 |
| [R13] | Drift：Migrations | 个人数据库迁移与测试参考 |

[R01]: https://www.mediawiki.org/wiki/API:Revisions
[R02]: https://www.mediawiki.org/wiki/API:Etiquette
[R03]: https://docs.flutter.dev/app-architecture/guide
[R04]: https://drift.simonbinder.eu/examples/existing_databases/
[R05]: https://riverpod.dev/docs/introduction/getting_started
[R06]: https://www.sqlite.org/foreignkeys.html
[R07]: https://www.sqlite.org/atomiccommit.html
[R08]: https://developer.android.com/studio/publish/upload-bundle
[R09]: https://developer.apple.com/documentation/xcode/doing-advanced-optimization-to-further-reduce-your-app-s-size
[R10]: https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh-hans
[R11]: https://wiki.biligame.com/rocom/%E6%A8%A1%E5%9D%97%3APet
[R12]: https://www.sqlite.org/backup.html
[R13]: https://drift.simonbinder.eu/migrations/

---

**V1 实施结论：先把真实 API 快照变成经过验证的离线数据库，再完成 Flutter 查询与个人数据，最后验证随 App 更新的安全替换。不要让服务器、独立补丁、素材专项或未验证的游戏规则成为第一版的隐性依赖。**
