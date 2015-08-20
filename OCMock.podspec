Pod::Spec.new do |s|
  s.name         = "OCMock"
  s.version      = "3.1.3"
  
  s.summary      = "Mock objects for Objective-C"
  s.description      = <<-DESC
                        OCMock is an Objective-C implementation of mock objects. It provides
                        stubs that return pre-determined values for specific method invocations,
                        dynamic mocks that can be used to verify interaction patterns, and
                        partial mocks to overwrite selected methods of existing objects.
                        DESC
  
  s.homepage     = "http://ocmock.org"
  s.license      = { :type => "Apache 2.0", :file => "License.txt" }

  s.author             = { "Erik Doernenburg" => "erik@doernenburg.com" }
  s.social_media_url   = "http://twitter.com/erikdoe"
  
  s.source       = { :git => "https://github.com/erikdoe/ocmock.git", :tag => "v3.1.3" }
  s.source_files  = "Source/OCMock/*.{h,m}"

  s.ios.deployment_target = '8.2'
  s.osx.deployment_target = '10.6'
  
  s.public_header_files = ["OCMock.h", "OCMockObject.h", "OCMArg.h", "OCMConstraint.h", "OCMLocation.h", "OCMMacroState.h", "OCMRecorder.h", "OCMStubRecorder.h", "NSNotificationCenter+OCMAdditions.h"].map { |file|
    "Source/OCMock/" + file
  }
  
  s.requires_arc = false
end
