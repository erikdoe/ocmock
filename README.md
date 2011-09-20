OCMock 
====== 
 
OCMock is an Objective-C implementation of mock objects. If you are unfamiliar with the concept of mock objects, please visit [mockobjects.com][1], which has more details & discussions about this approach to testing software.  


Project Setup
-------------

### Add OCMock as a [Git submodule][2]

This will help you [pull in updates][3] and [make contributions][4].

    cd ~/Projects/OCMockSampleAppIOS/ # sample project root directory

    # Let's make a new directory called Libraries for third-party code.
    git submodule add https://github.com/erikdoe/ocmock.git Libraries/OCMock
    git submodule update --init
    git commit -am 'Add OCMock as a submodule.'


### Add OCMock to Your Xcode Project

In Xcode, select your project at the top of the Project Navigator (⌘1), and press ⌥⌘N to create a new group. Name it, e.g., "Libraries." Then, select the Libraries group, press ⌥⌘0 to Show Utilities, click the small icon to the right just below Path, choose the Libraries directory. Drag the Libraries group to move it before the Frameworks group.

With the Libraries group selected, press ⌥⌘A to add files, select `OCMock.xcodeproj` in `Libraries/OCMock/OCMock`, and confirm that "Copy items into destination group's folder (if needed)" is unchecked, "Create groups for any added folders" is selected, and all targets are unchecked. Then, click Add.

    git commit -am 'Add Libraries/OCMock group & OCMock project.'


### Edit Your Application Target's Settings

In Xcode, select your main Xcode project at the top of the Project Navigator (⌘1), and then, select the test target to which you want to add OCMock.

#### [Edit Build Phases][5]

Select the "Build Phases" tab.

* Under the "Target Dependencies" group, click the plus button, select OCMockIOS (or OCMock for Mac OS X) from the menu, and click Add.
* Under the "Link Binary With Libraries" group, click the plus button, select `libOCMock.a` (or OCMock.framework for Mac OS X) from the menu, and click Add.

#### [Edit Build Settings][6]

Select the "Build Settings" tab. Make sure "All" is selected in the top left of the bar under the tabs.

* Search for "Header Search Paths," click on it, hit enter, paste `Libraries/OCMock`, and hit enter. (This leaves "Recursive" unchecked.)
* Do the same for "Other Linker Flags," except paste [`-ObjC -force_load ${BUILT_PRODUCTS_DIR}/libOCMock.a`][7]

    git commit -am 'Edit app target settings for OCMock.'


Using OCMock in Your App
-----------------------

* Include OCMock in any files that use it:

        #import <OCMock/OCMock.h>
        
* To [reduce build times][8], create a precompiled header file. E.g., `OCMockSampleAppIOSTests-Prefix.pch`:

        #include "OCMockSampleAppIOS-Prefix.pch"

        #ifdef __OBJC__

        // Frameworks
        #import <SenTestingKit/SenTestingKit.h>

        // Libraries
        #import <OCMock/OCMock.h>

        #endif
        
    Specify the path to this precompiled header in your test target's Build Settings under Prefix Header.


OCMock Sample App (iOS)
-----------------------

Check out [OCMockSampleAppIOS][9] for a sample iOS app that uses OCMock.

*Please visit [ocmock.org][10] for more documentation & support.*


  [1]: http://www.mockobjects.com/
  [2]: http://book.git-scm.com/5_submodules.html
  [3]: #update
  [4]: #contribute
  [5]: http://j.mp/pBH1KE
  [6]: http://j.mp/mR5Jco
  [7]: http://developer.apple.com/library/mac/#qa/qa1490/_index.html
  [8]: http://j.mp/mmGElg
  [9]: https://github.com/acani/OCMockSampleAppIOS
  [10]: http://ocmock.org/
