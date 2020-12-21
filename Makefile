# This makefile has the following top-level targets:
#   - ci    used by Travis for continuous integration
#   - dist  used to build the binary distribution
#
# Note that the dist target will checkout the source code to a temporary
# directory. Any uncommited changes will not affect the build. That said,
# it will use the locally checked out version of the Xcode configs.

SYMROOT = $(CURDIR)/Build
DISTDIR = $(SYMROOT)/Product
XCODECI = xcodebuild -project "$(CURDIR)/Source/OCMock.xcodeproj" -xcconfig "$(CURDIR)/Source/OCMockCI.xcconfig"
XCODEDIST = xcodebuild -project "$(DISTDIR)/Source/OCMock.xcodeproj" -xcconfig "$(CURDIR)/Source/OCMockDist.xcconfig"
SHELL = /bin/bash -e -o pipefail

.PHONY: checkout macos ioslib ios tvos watchos
	
clean:
	rm -rf "$(CURDIR)/Build"


ci: ci-macos ci-ios

ci-macos:
	@echo "Building macOS framework and running tests..."
	$(XCODECI) -scheme OCMock -sdk macosx test | xcpretty -c

ci-ios:
	@echo "Building iOS library and running tests..."
	$(XCODECI) -scheme OCMockLib -destination 'platform=iOS Simulator,OS=latest,name=iPhone 11' test | xcpretty -c


dist: clean product dmg
	
checkout:
	@echo "** Checking out source..."
	mkdir -p "$(DISTDIR)"
	git archive master | tar -x -C "$(DISTDIR)" Source

macos: checkout
	@echo "** Building macOS framework..."
	$(XCODEDIST) -target OCMock -sdk macosx install INSTALL_PATH="/macOS" | xcpretty -c

ioslib: checkout
	@echo "** Building iOS library..."
	$(XCODEDIST) -target OCMockLib -sdk iphonesimulator install INSTALL_PATH="/iOS library" | xcpretty -c

ios: checkout
	@echo "** Building iOS framework..."
	$(XCODEDIST) -target "OCMock iOS" -sdk iphonesimulator install INSTALL_PATH="/iOS" | xcpretty -c

tvos: checkout
	@echo "** Building tvOS framework..."
	$(XCODEDIST) -target "OCMock tvOS" -sdk appletvsimulator install INSTALL_PATH="/tvOS" | xcpretty -c
		
watchos: checkout
	@echo "** Building watchOS framework..."
	$(XCODEDIST) -target "OCMock watchOS" -sdk watchsimulator install INSTALL_PATH="/watchOS"| xcpretty -c

product: macos ioslib ios tvos watchos
	@echo "** Verifying products..."
	Tools/distcheck.rb $(DISTDIR)

dmg: 
	@echo "** Creating disk image..."
	Tools/makedmg.rb $(DISTDIR) $(SYMROOT)
