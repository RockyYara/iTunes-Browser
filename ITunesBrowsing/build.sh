# 1
# Set bash script to exit immediately if any commands fail.
set -e
# 2
# Setup some constants for use later on.
FRAMEWORK_NAME="${PROJECT_NAME}"
OUTPUT_DIR="${SRCROOT}/build"
# 3
# If remnants from a previous build exist, delete them.
if [ -d "${OUTPUT_DIR}" ]; then
rm -rf "${OUTPUT_DIR}"
fi
# 4
# Build the framework for device and for simulator (using
# all needed architectures).

xcodebuild -project "${FRAMEWORK_NAME}.xcodeproj" -scheme "${FRAMEWORK_NAME}" -configuration Release -arch arm64 -arch arm64e only_active_arch=no defines_module=yes -sdk "iphoneos" -derivedDataPath "${OUTPUT_DIR}"
xcodebuild -project "${FRAMEWORK_NAME}.xcodeproj" -scheme "${FRAMEWORK_NAME}" -configuration Release -arch x86_64 only_active_arch=no defines_module=yes -sdk "iphonesimulator" -derivedDataPath "${OUTPUT_DIR}"

# 5
# Remove .framework file if exists from previous run.
if [ -d "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework" ]; then
rm -rf "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework"
fi
# 6
# Copy the device version of framework.
cp -r "${OUTPUT_DIR}/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework" "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework"
# 7
# Replace the framework executable within the framework with
# a new version created by merging the device and simulator
# frameworks' executables with lipo.
lipo -create -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${OUTPUT_DIR}/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${OUTPUT_DIR}/Build/Products/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
# 8
# Copy the Swift module mappings for the simulator into the
# framework. The device mappings already exist from step 6.
cp -r "${OUTPUT_DIR}/Build/Products/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/" "${OUTPUT_DIR}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule"
