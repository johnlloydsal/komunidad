# Quick Build Commands for KOMUNIDAD App

# 1. Clean build cache
flutter clean

# 2. Build release APK (optimized, ~15-20 MB)
flutter build apk --release

# 3. Build split APKs per architecture (smallest, ~10-12 MB each)
flutter build apk --release --split-per-abi

# 4. Install directly to connected device
flutter install --release

# 5. Build App Bundle for Google Play
flutter build appbundle --release

# Note: Release builds are much smaller and install faster!
# Debug builds (~78 MB) are only for development with hot reload.
