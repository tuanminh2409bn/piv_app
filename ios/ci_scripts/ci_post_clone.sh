#!/bin/bash

# Dừng ngay nếu có lỗi
set -e

# In ra chi tiết các lệnh đang chạy để debug
set -x

echo "🧩 Starting ci_post_clone.sh..."

# Thiết lập encoding để tránh lỗi CocoaPods (quan trọng!)
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Xác định thư mục gốc của dự án
if [ -z "$CI_PRIMARY_REPOSITORY_PATH" ]; then
    echo "⚠️  CI_PRIMARY_REPOSITORY_PATH is not set. Using current directory."
    PROJECT_ROOT="."
else
    echo "📂 Navigating to repository root: $CI_PRIMARY_REPOSITORY_PATH"
    PROJECT_ROOT="$CI_PRIMARY_REPOSITORY_PATH"
fi

cd "$PROJECT_ROOT"

# Cài đặt Flutter
# Kiểm tra xem đã có flutter chưa (để tránh clone lại nếu test local)
if [ ! -d "$HOME/flutter" ]; then
    echo "⬇️  Cloning Flutter (stable)..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
else
    echo "ℹ️  Flutter directory already exists."
fi

# Cài đặt CocoaPods thông qua Homebrew để tránh lỗi tương thích Ruby trên Xcode Cloud
echo "🥥 Cài đặt CocoaPods mới nhất..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

# Thêm Flutter vào PATH
export PATH="$PATH:$HOME/flutter/bin"

echo "✅ Flutter installed. Verifying version..."
flutter --version

# Precache iOS artifacts (giúp build nhanh hơn và tránh lỗi thiếu file)
echo "📦 Running flutter precache..."
flutter precache --ios

# Cài đặt dependencies của Flutter
echo "📦 Running flutter pub get..."
flutter pub get

# Tạm thời tắt Swift Package Manager (SPM) của Flutter trên Xcode Cloud
# Xcode Cloud chặn việc tự động resolve package nếu không có file Package.resolved được commit.
# Các plugin như google_sign_in sẽ tự động fallback về dùng CocoaPods.
echo "🔧 Disabling Swift Package Manager..."
flutter config --no-enable-swift-package-manager

# Chạy lệnh cấu hình iOS để tạo các file xcconfig và chạy pod install tự động
echo "⚙️ Cấu hình iOS project..."
flutter build ios --config-only

echo "🎉 ci_post_clone.sh completed successfully."