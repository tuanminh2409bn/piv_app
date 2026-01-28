#!/bin/sh

# Fail on any error
set -e

# Detailed logging
set -x

echo "🧩 Starting ci_post_clone.sh..."

# The environment variable CI_PRIMARY_REPOSITORY_PATH points to the root of the cloned repository.
# For a Flutter project, this is the directory containing pubspec.yaml.
if [ -z "$CI_PRIMARY_REPOSITORY_PATH" ]; then
    echo "⚠️  CI_PRIMARY_REPOSITORY_PATH is not set. Assuming current directory is project root or close to it."
    # Fallback or local testing logic could go here, but for now we assume Xcode Cloud environment.
    # If testing locally, you might be in ios/ci_scripts or just ios/
else
    echo "📂 Navigating to repository root: $CI_PRIMARY_REPOSITORY_PATH"
    cd "$CI_PRIMARY_REPOSITORY_PATH"
fi

# Install Flutter
echo "⬇️  Cloning Flutter (stable)..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "✅ Flutter installed."
flutter --version

# Run flutter pub get to generate local files (like Generated.xcconfig)
echo "📦 Running flutter pub get..."
flutter pub get

# Install CocoaPods dependencies
echo "🥥 Running pod install in ios/ directory..."
cd ios
# Install pods. Use repo update if needed, but usually strictly not necessary on fresh clones unless specs are old.
pod install

echo "🎉 ci_post_clone.sh completed successfully."
