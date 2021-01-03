#!/bin/sh
#find _b -iname '*.o' -delete
#find _b -iname '*.so' -delete

ANDROID_HOME=~/Library/Android/sdk
if [ ! -d $ANDROID_HOME ]; then 
    ANDROID_HOME=~/android-sdk
fi

V=$(ls $ANDROID_HOME/ndk|tail -n1)
rm_cache() {
  rm -rf _b/$1/*Cache.txt
  rm -rf _b/$1/luajit/src/mluajit-stamp/mluajit-{done,install}
}
set -e
rm_cache android-arm
echo ==============building android-aarch64 ==================
cmake -B_b/android-arm -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_TOOLCHAIN_FILE=$ANDROID_HOME/ndk/$V/build/cmake/android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-30
cmake --build _b/android-arm
echo ==============building android-x86_64 ==================

rm_cache android-x86
cmake -B_b/android-x86 -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_TOOLCHAIN_FILE=$ANDROID_HOME/ndk/$V/build/cmake/android.toolchain.cmake -DANDROID_ABI=x86_64 -DANDROID_PLATFORM=android-30
cmake --build _b/android-x86 

echo ==============building ios arm64 ==================

rm_cache ios
#find _b/ios -iname '*.o' -delete
cmake -B_b/ios -DOS=iphoneos -DARCH=arm64 -DCMAKE_INSTALL_PREFIX=./install
cmake --build _b/ios

echo ==============building ios simulator ==================
rm_cache ios-x86
cmake -B_b/ios-x86 -DOS=iphonesimulator -DARCH=x86_64 -DCMAKE_INSTALL_PREFIX=./install
cmake --build _b/ios-x86
echo ==============building macos ==================
rm_cache mac
#find _b/mac -iname '*.o' -delete
cmake -B_b/mac -DOS=macosx -DARCH=x86_64 -DCMAKE_INSTALL_PREFIX=./install 
cmake --build _b/mac
echo ==============building macos-arm64 ==================

rm_cache mac-arm64
cmake -B_b/mac-arm64 -DOS=macosx -DARCH=arm64 -DCMAKE_INSTALL_PREFIX=./install 
cmake --build _b/mac-arm64
mkdir -p ./install/{mac,ios}-universal

lipo ./install/{iOSim-x86_64,iOS-arm64}/lib/libluajit-5.1.a -create -output ./install/ios-universal/libluajit-5.1.a
lipo ./install/{macos-x86_64,macos-arm64}/lib/libluajit-5.1.a -create -output ./install/mac-universal/libluajit-5.1.a
