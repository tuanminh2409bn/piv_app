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

# Cài đặt CocoaPods dependencies
echo "🥥 Installing Pods..."
cd ios

# Cần đảm bảo file Podfile.lock đồng bộ, nếu không thì dùng --repo-update
# Chạy pod install với repo update để chắc chắn có specs mới nhất
pod install --repo-update

echo "🎉 ci_post_clone.sh completed successfully."