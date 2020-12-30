# This makefile has the following top-level targets:
#   - ci    used by Travis for continuous integration
#   - dist  used to build the binary distribution
#
# Note that the dist target uses git checkout to copy the source into the
# product directory. This means you should make sure that you don't have 
# uncommited local changes when building a distribution.

BUILD_DIR   = $(CURDIR)/Build
PRODUCT_DIR = $(BUILD_DIR)/Product
XCODECI     = xcodebuild -project "$(CURDIR)/Source/OCMock.xcodeproj" -xcconfig "$(CURDIR)/Source/OCMockCI.xcconfig" -destination-timeout 300
XCODEDIST   = xcodebuild -project "$(CURDIR)/Source/OCMock.xcodeproj" -xcconfig "$(CURDIR)/Source/OCMockDist.xcconfig"
SHELL       = /bin/bash -e -o pipefail

.PHONY: macos ioslib ios tvos watchos sourcecode product dmg
	
clean:
	rm -rf "$(CURDIR)/Build"


ci: ci-macos ci-ios

ci-macos:
	@echo "Building macOS framework and running tests..."
	$(XCODECI) -scheme OCMock -sdk macosx test | xcpretty -c

ci-ios:
	@echo "Building iOS library and running tests..."
	$(XCODECI) -scheme OCMockLib -destination 'platform=iOS Simulator,OS=latest,name=iPhone 11' test | xcpretty -c


dist: product sourcecode dmg
		
macos:
	@echo "** Building macOS framework..."
	$(XCODEDIST) -scheme OCMock install INSTALL_PATH="/macOS" | xcpretty -c
	
ioslib:
	@echo "** Building iOS library..."
	$(XCODEDIST) -target OCMockLib -sdk iphonesimulator install INSTALL_PATH="/iOS library" | xcpretty -c

ios:
	@echo "** Building iOS framework..."
	$(XCODEDIST) -target "OCMock iOS" -sdk iphonesimulator install INSTALL_PATH="/iOS" | xcpretty -c

tvos:
	@echo "** Building tvOS framework..."
	$(XCODEDIST) -target "OCMock tvOS" -sdk appletvsimulator install INSTALL_PATH="/tvOS" | xcpretty -c
		
watchos:
	@echo "** Building watchOS framework..."
	$(XCODEDIST) -target "OCMock watchOS" -sdk watchsimulator install INSTALL_PATH="/watchOS" | xcpretty -c
	
sourcecode:
	@echo "** Checking out source code..."
	mkdir -p "$(PRODUCT_DIR)"
	git archive master | tar -x -C "$(PRODUCT_DIR)" Source

product: macos ioslib ios tvos watchos
	@echo "** Verifying build products..."
	Tools/buildcheck.rb $(PRODUCT_DIR)

dmg: 
	@echo "** Creating disk image..."
	Tools/makedmg.rb $(PRODUCT_DIR) $(BUILD_DIR)
