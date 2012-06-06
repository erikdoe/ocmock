
default:
	xcodebuild -target "GHUnitIOS (Device)" -configuration Release
	xcodebuild -target "GHUnitIOS (Simulator)" -configuration Release
	BUILD_DIR="build" BUILD_STYLE="Release" sh ../Scripts/CombineLibs.sh
	sh ../Scripts/iOSFramework.sh

# If you need to clean a specific target/configuration: $(COMMAND) -target $(TARGET) -configuration DebugOrRelease -sdk $(SDK) clean
clean:
	-rm -rf build/*

test:
	GHUNIT_CLI=1 xcodebuild -target Tests -configuration Debug -sdk iphonesimulator build
