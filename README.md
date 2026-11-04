# DeskStyle（桌面美化）

给 iPhone 主屏幕做「能做的那一半」：看截图、挑风格、出壁纸、出图标、预览格子，再由你自己摆上去。

这个仓库没有 Mac 工程文件。推送后由 GitHub Actions 的 macOS  runner 用 XcodeGen 生成工程，打出一个**未签名**的 `DeskStyle.ipa`。你在 Windows 上用 Sideloadly 和免费 Apple ID 装到手机上。

界面是简体中文。系统要求 iOS 17 或更高，仅 iPhone。

## 它能做什么

1. **截图分析。** 从照片里选一张主屏幕截图。Vision 识别图标下面的文字，按大致行列估计位置，再用内置关键词表分成社交、购物、系统等类，并按图标主色给出「颜色接近的放一行」之类的建议。也可以不截图，直接用示例名单或手打名字。
2. **风格。** 六套预设：极简、暗黑、莫兰迪、可爱风、海洋、暖阳。每套包含配色、壁纸倾向、图标圆角和字体。
3. **壁纸。** 纯色、渐变，或用 Core Image 把一张照片做高斯模糊。可以在上方留一块淡淡的小组件区域。按当前屏幕分辨率保存到照片。
4. **图标。** 给名单里的每个名字画一张图标（对得上的用系统符号，对不上的用首字），连同一张带名字的总览图保存到照片。App 里有逐步说明：用「快捷指令 → 打开 App → 添加到主屏幕」替换图标。
5. **小组件。** 同一个扩展里有时钟、日历、照片、倒数日、一句话，支持小号、中号、大号。风格、画面、倒数日标题和日期都在主屏幕的「编辑小组件」里选，不依赖主 App 的数据。
6. **布局预览。** 4 列格子加共享程序坞。可以拖动，也可以点选后用按钮微调，能放文件夹占位和小组件占位。导出预览图到照片，方便对着摆。方案写成 JSON，存在 App 的「文件」目录里，也可以直接分享。

## 它不能做什么

这些是 iOS 的限制，不是漏做：

- 不能读取你安装了哪些 App，也不能拿到它们的 Bundle ID。`bundleHint` 在这一版永远是空的。
- 不能排列主屏幕，不能移动图标，不能改其他 App 的图标，也不会调用任何私有接口。
- 免费 Apple ID 不能使用 App Groups、推送、iCloud 和 Siri。主 App 和小组件**不能共享数据**。你在 App 里选的风格，不会自动出现在小组件上，需要在「编辑小组件」里再选一次同名风格。
- 照片小组件只有三张内置画面（海平线、色块、暮色）。自定义相册照片需要把图片写进小组件沙盒，没有 App Groups 做不到，所以这一版不做。
- 用快捷指令换上的图标，点开时会先闪一下快捷指令再进入 App。删掉对应的快捷指令，图标就失效。

## 从 Actions 下载 IPA

1. 打开本仓库的 [Actions](https://github.com/yuanyeye0210-debug/DeskStyle/actions/workflows/build.yml)。
2. 选最近一次成功的 **Build IPA**（绿色勾）。
3. 在页面底部的 Artifacts 里下载 **DeskStyle-ipa**。
4. 解压这个 zip，里面是 `DeskStyle.ipa`。
5. 产物保留 14 天。过期后打开 Actions，选 Build IPA，点 **Run workflow** 再打一次。这个按钮在工作流进入默认分支 `main` 之后会出现。

安装包是未签名的。里面应有 `Payload/DeskStyle.app`，以及 `Payload/DeskStyle.app/PlugIns/DeskStyleWidget.appex`。没有这个 appex，主屏幕上就不会出现小组件。

工作流做的事：安装 XcodeGen 2.46.0，根据 `project.yml` 生成工程，用 `CODE_SIGNING_ALLOWED=NO` 编 Release（iphoneos），确认主程序和小组件都是 arm64 且没有描述文件，再打成 ipa 上传。

## 用 Sideloadly 装到 iPhone（Windows）

准备：Windows 电脑、数据线、iPhone（iOS 17+）、一个免费 Apple ID。免费账号每 7 天大约只能注册 10 个 App ID。这个 App 会占用 **2 个**（主 App `app.deskstyle.ios` 和小组件 `app.deskstyle.ios.widget`）。

1. 安装 [Sideloadly](https://sideloadly.io/)。如果电脑认不出手机，再安装 Apple 官网的 iTunes，或 Microsoft Store 里的「Apple 设备」。
2. 用数据线连接 iPhone，在手机上点「信任」。
3. 打开 Sideloadly，把 `DeskStyle.ipa` 拖进去。
4. 填入 Apple ID。开了双重认证的话，按提示输入验证码。
5. **不要勾选 Remove extensions / 移除扩展。** 勾了会把小组件删掉。其他高级选项保持默认。
6. 如果提示 Bundle ID 已被占用，改成你自己的，例如 `com.你的名字.deskstyle`。仍然不要移除扩展，让 Sideloadly 把小组件一起重签。
7. 点 Start，等到完成。

装好之后在手机上：

1. 打开 **设置 → 通用 → VPN 与设备管理**（有的系统写「设备管理」），点你的 Apple ID，选择信任。
2. 打开 **设置 → 隐私与安全性 → 开发者模式**，打开后按提示重启，重启后再确认一次。iOS 16 起，不打开开发者模式，自签 App 打不开。
3. 打开「桌面美化」。

免费证书大约 **7 天**后过期，App 和小组件会一起打不开。到期前用同一台电脑、同一个 Apple ID 再装一次即可，一般不用先删掉 App，布局 JSON 会留着。不要勾选移除扩展。

## 用完这一版之后

- 壁纸：保存到照片后，到 **设置 → 墙纸** 里选用。
- 图标：按 App 里的「换图标步骤」，一个 App 一条快捷指令。
- 小组件：长按主屏幕，点左上角加号，搜索「桌面美化」或 DeskStyle，添加时钟、日历、照片、倒数日或一句话。再长按该小组件，点「编辑小组件」选风格。照片小组件只能选内置画面。
- 布局：在「布局」页摆好，导出预览图，自己在主屏幕上照着拖。JSON 在「文件」App 的「桌面美化」文件夹，文件名 `layout-plan.json`，也可以从布局页分享。字段说明见 `docs/layout-plan.schema.json`。

给以后的桌面自动化（例如用 WebDriverAgent 拖图标）看的约定：

- 以 `pages` 和 `dock` 为准，不要用 `library` 里的估算行列。
- 原点在页面左上角，`column`、`row` 从 0 开始。内容区是 `row < dockRow`，程序坞是 `dock`，只存一份，`pageIndex` 为 -1。
- `columnSpan` / `rowSpan`：小号小组件 2×2，中号 4×2，大号 4×4。
- 这一版没有真实 Bundle ID。

## 工程结构

只有两个 target，避免免费账号的 App ID 限额：

- `DeskStyle`：主 App
- `DeskStyleWidget`：一个 WidgetKit 扩展，里面放全部小组件
- `Shared`：风格和布局模型的源码，编译进两个 target。没有运行时共享容器。

`project.yml` 是工程描述。不要提交 `.xcodeproj`。有 Mac 的话可以装 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 后在仓库根目录执行 `xcodegen generate`。没有 Mac 就只看 Actions。
