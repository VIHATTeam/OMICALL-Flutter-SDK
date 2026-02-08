# OMICALL Flutter SDK Deployment Guide

## Tổng quan

Script `deploy.sh` kết hợp chức năng của `tag.sh` và `publish.sh` thành một quy trình deploy tự động và an toàn.

## Cài đặt

```bash
chmod +x deploy.sh
```

## Sử dụng

### Cách 1: Sử dụng version hiện tại từ pubspec.yaml

```bash
./deploy.sh
```

### Cách 2: Chỉ định version mới

```bash
./deploy.sh 3.2.7
```

Script sẽ tự động:
- Cập nhật version trong `pubspec.yaml`
- Tạo git tag
- Publish lên pub.dev

## Quy trình Deploy

### Bước 1: Kiểm tra Git Status
- ✅ Kiểm tra uncommitted changes
- ⚠️ Cảnh báo nếu có thay đổi chưa commit
- 🔄 Cho phép tiếp tục hoặc hủy

### Bước 2: Kiểm tra Tag
- ✅ Kiểm tra tag đã tồn tại chưa
- 🗑️ Tùy chọn xóa tag cũ nếu cần

### Bước 3: Run Tests (Optional)
- 🧪 Chạy `flutter test`
- ✅ Đảm bảo code không bị lỗi

### Bước 4: Analyze Code (Optional)
- 🔍 Chạy `flutter analyze`
- ⚠️ Phát hiện potential issues

### Bước 5: Dry Run
- 🔍 Chạy `flutter pub publish --dry-run`
- ✅ Kiểm tra package trước khi publish

### Bước 6: Create & Push Tag
- 🏷️ Tạo git tag với message
- 📤 Push tag lên remote repository

### Bước 7: Publish
- 📦 Publish lên pub.dev
- ✅ Xác nhận thành công

## Tính năng

### ✨ Tự động hóa
- Auto-detect version từ pubspec.yaml
- Auto-update version nếu được chỉ định
- Auto-validate semver format

### 🛡️ An toàn
- Kiểm tra git status trước khi deploy
- Kiểm tra tag conflicts
- Dry-run trước khi publish
- Xác nhận từng bước quan trọng

### 🎨 User-friendly
- Colored output cho dễ đọc
- Interactive prompts
- Clear error messages
- Deployment summary

### 📊 Validation
- Semver format validation
- Git status check
- Tag existence check
- Test execution (optional)
- Code analysis (optional)

## Ví dụ Sử dụng

### Deploy version mới 3.2.7

```bash
./deploy.sh 3.2.7
```

**Output:**
```
==============================================
  OMICALL Flutter SDK Deployment
==============================================

📝 Updating version in pubspec.yaml...
✅ Version updated to 3.2.7

You are about to deploy version: 3.2.7
Continue? (y/n) y

🔍 Checking git status...
✅ Working directory is clean

Run tests? (y/n) y
🧪 Running tests...
✅ Tests passed

Analyze code? (y/n) y
🔍 Analyzing code...
✅ Code analysis passed

🔍 Running dry-run publish...
✅ Dry-run publish successful

🏷️  Creating git tag 3.2.7...
✅ Tag created: 3.2.7

📤 Pushing tag to remote...
✅ Tag pushed to remote

⚠️  About to publish to pub.dev
Proceed with publishing? (y/n) y

📦 Publishing to pub.dev...
✅ Package published successfully!

==============================================
  🎉 Deployment Successful!
==============================================

Version: 3.2.7
Package: https://pub.dev/packages/omicall_flutter_plugin
GitHub: https://github.com/VIHATTeam/OMICALL-Flutter-SDK/releases/tag/3.2.7
```

### Deploy với version hiện tại

```bash
./deploy.sh
```

Sẽ sử dụng version từ `pubspec.yaml` (hiện tại: 3.2.6)

### Xem help

```bash
./deploy.sh --help
```

## So sánh với Script Cũ

### ❌ Script cũ (tag.sh + publish.sh)

**tag.sh:**
```bash
git tag -a $1 -m "Release version $1"
git push --tags
```

**publish.sh:**
```bash
flutter pub publish --dry-run
flutter pub publish
```

**Vấn đề:**
- Không kiểm tra git status
- Không validation
- Không interactive
- Phải chạy 2 lần
- Không có error handling

### ✅ Script mới (deploy.sh)

**Ưu điểm:**
- ✅ All-in-one script
- ✅ Safety checks
- ✅ Interactive prompts
- ✅ Colored output
- ✅ Error handling
- ✅ Auto-update version
- ✅ Optional tests & analyze
- ✅ Deployment summary

## Workflow Khuyến nghị

### 1. Chuẩn bị Release

```bash
# Update CHANGELOG.md
vim CHANGELOG.md

# Commit changes
git add .
git commit -m "chore: prepare release 3.2.7"
git push
```

### 2. Deploy

```bash
./deploy.sh 3.2.7
```

### 3. Tạo GitHub Release (Optional)

Sau khi deploy, vào GitHub tạo release notes:
https://github.com/VIHATTeam/OMICALL-Flutter-SDK/releases/new

## Troubleshooting

### Lỗi: Tag already exists

```bash
# Delete local tag
git tag -d 3.2.7

# Delete remote tag
git push origin :refs/tags/3.2.7

# Run deploy again
./deploy.sh 3.2.7
```

### Lỗi: Uncommitted changes

```bash
# Option 1: Commit changes
git add .
git commit -m "your message"

# Option 2: Stash changes
git stash

# Then run deploy
./deploy.sh
```

### Lỗi: Publish failed

```bash
# Check pub.dev credentials
flutter pub token list

# Add new token if needed
flutter pub token add
```

## Migration từ Script Cũ

### Xóa script cũ (Optional)

```bash
rm tag.sh publish.sh
```

### Cập nhật CI/CD (nếu có)

Thay:
```yaml
- ./tag.sh $VERSION
- ./publish.sh
```

Bằng:
```yaml
- ./deploy.sh $VERSION
```

## Best Practices

1. **Luôn chạy tests** trước khi deploy
2. **Kiểm tra CHANGELOG.md** đã update chưa
3. **Commit tất cả changes** trước khi deploy
4. **Tạo GitHub Release** sau khi deploy thành công
5. **Thông báo team** về version mới

## Lưu ý

- Script yêu cầu Flutter SDK đã được cài đặt
- Cần có quyền publish lên pub.dev
- Git repository phải có remote origin
- Nên test trên branch trước khi deploy từ main

## Support

Nếu gặp vấn đề:
1. Kiểm tra `./deploy.sh --help`
2. Đọc error message cẩn thận
3. Kiểm tra git status: `git status`
4. Kiểm tra pub.dev credentials: `flutter pub token list`
