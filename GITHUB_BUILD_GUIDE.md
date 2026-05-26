# GitHub Actions 云端构建 APK 指南

## 1. 上传项目到 GitHub

在 GitHub 新建仓库，例如：

```text
wallpaper-wall-app
```

然后把当前工程完整上传到仓库根目录。必须包含：

```text
.github/workflows/build-apk.yml
android/
lib/
pubspec.yaml
```

## 2. 触发构建

有两种方式：

### 方式 A：push 自动触发

推送到 `main` 或 `master` 分支后自动构建。

### 方式 B：手动触发

进入仓库页面：

```text
Actions -> Build Flutter APK -> Run workflow
```

## 3. 下载 APK

构建完成后：

```text
Actions -> 最新一次 Build Flutter APK -> Artifacts
```

可以下载：

```text
wallpaper-wall-debug-apk
wallpaper-wall-release-apk
```

解压后得到：

```text
app-debug.apk
app-release.apk
```

## 4. 推荐安装哪个？

自用测试优先安装：

```text
app-release.apk
```

如果 release 安装失败，再试：

```text
app-debug.apk
```

## 5. 注意

当前 release APK 使用 debug 签名配置，适合自用安装测试，不适合上架应用商店。

若需要正式发布签名，需要后续配置 Android keystore secrets。