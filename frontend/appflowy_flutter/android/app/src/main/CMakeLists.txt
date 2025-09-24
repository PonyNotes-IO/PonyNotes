cmake_minimum_required(VERSION 3.10.0)

project(AppFlowy)

message(CONFIGURE_LOG "NDK PATH: ${ANDROID_NDK}")
message(CONFIGURE_LOG "Copying libc++_shared.so")

# arm64-v8a
file(COPY
    ${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so
    DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/arm64-v8a
)

# armeabi-v7a
file(COPY
    ${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so
    DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/armeabi-v7a
)

# x86_64
file(COPY
    ${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so
    DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/jniLibs/x86_64
)