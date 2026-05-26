# Wallpaper Wall App

Flutter Android wallpaper wall app with Material 3 style.

## 功能

- 360 国内壁纸 API。
- 分类筛选：全部、综合、二次元、人物、随机。
- 双列/三列自适应瀑布流。
- Material 3 深色玻璃风 UI。
- 顶部操作台滑动隐藏。
- 点击壁纸选择，底部选中栏快捷播放/保存。
- 全屏电影感幻灯片：闪回、模糊背景、播放/暂停、左右翻页。
- 保存图片到相册 `Wallpaper Wall`。

## 当前状态

本工程已迁移为完整 Flutter 壁纸墙源码。

当前执行环境未安装 Flutter / Dart / Java / Gradle，因此无法在这里直接构建 APK。

## 本地构建

在安装 Flutter SDK 的环境执行：

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

APK 输出路径：

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Android HTTP 配置

360 API 的 HTTPS 端点在当前测试网络不可达，因此接口请求使用 HTTP。

已配置：

```text
android/app/src/main/res/xml/network_security_config.xml
```

并已在 `AndroidManifest.xml` 的 `<application>` 中启用：

```xml
android:usesCleartextTraffic="true"
android:networkSecurityConfig="@xml/network_security_config"
```

## 入口

```text
lib/main.dart
```

核心目录：

```text
lib/models/
lib/services/
lib/widgets/
lib/screens/
```