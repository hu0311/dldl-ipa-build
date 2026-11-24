# 斗罗大陆独享服 · H5 封装工程（gid=225）

一个纯 WKWebView 壳，加载 `https://www.youyougu.cn/?ct=h5login&gid=225`，桌面名称 **斗罗大陆独享服**，图标已用游戏自带图标（裁边后 1024×1024，已放进 `App/Assets.xcassets/AppIcon.appiconset`）。

全屏无黑边、跟随网页方向、JS / 音视频内联播放、`weixin://` `alipay://` 等外链自动跳系统、加载失败可重试、游玩期间不自动锁屏、Cookie 持久化（关掉再开仍是登录态）。

## 目录结构

```
project.yml                      XcodeGen 工程描述（bundle id / 版本 / 签名开关都在这）
App/AppDelegate.swift            入口
App/WebViewController.swift      壳本体（换游戏只改 startURLString 一行）
App/Info.plist                   方向 / ATS / 状态栏
App/LaunchScreen.storyboard      启动黑屏（避免白屏和刘海机型缩放）
.github/workflows/build-ipa.yml  云端一键出未签名 IPA
scripts/build_local_mac.sh       有 Mac 时的本地编译
scripts/sign_ipa.sh              企业证书重签
dist/manifest-template.plist     OTA 安装清单模板
```

## 为什么不能在你电脑上直接出 IPA

`.ipa` 必须由 macOS 工具链（Xcode + ibtool + codesign）编译出 arm64 产物。Windows 上装不了，也绕不过去。
本工程的做法：**把源码推到 GitHub，用 GitHub Actions 免费的 macOS 跑构建**，你只需要浏览器，不需要 Mac。

## 第一步：出未签名 IPA（约 5 分钟）

1. GitHub 新建一个仓库（private 也可以）。
2. 把本目录所有文件（**包括 `.github` 目录**）推送到 `main` 分支。
   - 用 GitHub Desktop 或命令行 `git push` 最稳；
   - 网页版拖拽上传有时会漏掉 `.github` 这种点开头的目录，漏了就没有构建按钮。
3. 打开仓库 → `Actions` 标签 → 左侧 `Build IPA (unsigned)` → `Run workflow`。
4. 等 3~5 分钟，在运行详情页底部 `Artifacts` 下载 `YouyouguH5-unsigned-ipa`，里面就是 `YouyouguH5-1.0.0-unsigned.ipa`。

> 构建失败先看 `Archive (no codesign)` 那一步的日志，通常是 Xcode 版本或工程描述格式问题，把日志发我。

## 第二步：企业签名（你选的分发方式）

默认 bundle id 是 `cn.youyougu.app225`，**必须和你企业证书的 provisioning profile 匹配**（不确定就用通配 profile，或者改 `project.yml` 里的 `PRODUCT_BUNDLE_IDENTIFIER` 后重新构建）。

三条路，按省事程度排：

**A. 第三方签名服务（最快，几块钱）**
蒲公英 / fir.im / 爱思助手 / 各类企业签服务：上传未签名 ipa，选“企业证书”，在线签完直接给下载链接。适合你现在就要装的情况。

**B. 自有企业证书 + Mac**
```bash
security find-identity -v -p codesigning          # 查证书全名
./scripts/sign_ipa.sh YouyouguH5-1.0.0-unsigned.ipa \
  "iPhone Distribution: 你的公司名" ./enterprise.mobileprovision
```

**C. Windows 上签（zsign）**
```powershell
zsign -k cert.p12 -p 证书密码 -m xxx.mobileprovision -o YouyouguH5-signed.ipa YouyouguH5-1.0.0-unsigned.ipa
```

签完自检：`codesign -dv --verbose=4 Payload/YouyouguH5.app`，看 `Authority` 和 `TeamIdentifier` 对不对。

## 第三步：OTA 安装（发给测试用户）

iOS 的 OTA 安装**必须 https**，http 会直接失败。

1. 把签名后的 `YouyouguH5-signed.ipa`、`icon-57.png`、`icon-512.png` 传到你的 https 站点（比如 `https://www.youyougu.cn/app/`）。
2. 复制 `dist/manifest-template.plist`，把 3 个 `https://你的域名/...` 换成真实地址，标题按需要改。
3. manifest 也放 https。
4. 把下面这条发给用户，让他在 **Safari**（不要微信里）打开：

```
itms-services://?action=download-manifest&url=https://www.youyougu.cn/app/manifest.plist
```

## 常见要改的地方

| 想改什么 | 改哪里 |
|---|---|
| 换游戏 / 换登录地址 | `App/WebViewController.swift` 里的 `startURLString` |
| 桌面图标下的名字 | `App/Info.plist` 的 `CFBundleDisplayName` |
| bundle id | `project.yml` 的 `PRODUCT_BUNDLE_IDENTIFIER` |
| 版本号 | `project.yml` 的 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` |
| 加应用图标 | 新建 `App/Assets.xcassets/AppIcon.appiconset`，放一张 1024×1024 png；`project.yml` 加 `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` |

## 已知限制（先知道，省得返工）

- **上不了 App Store**：纯 H5 壳会被 4.2「最低功能要求」拒，企业签 / 自签才是它的归宿。
- **企业证书不能大规模公开分发**：苹果对滥用是直接吊销，一吊销所有装有该证书的 App 全部闪退打不开。
- **微信 / 支付宝支付要真机验证**：壳里能跳系统 App，但部分 H5 支付的回调跳不回壳内，上线前务必实测一笔。
- **这个壳里没有加速器脚本**，也不要往里加：那等于把外挂打包分发，客户端反作弊（37 那层的 TimerHook）会识别，封的是渠道和证书。

## 拿到包后的自测清单

1. 首屏是否全屏、无黑边、无白屏闪烁
2. 登录 → 选服 → 进游戏，横屏战斗是否自动转屏
3. 支付、客服、公告外链是否正常
4. 断网后是否出现“重新加载”
5. 切后台再回来，登录态是否还在
