//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMockObject.h>
#import <OCMock/OCMockRecorder.h>
#import <OCMock/OCMConstraint.h>
#import <OCMock/OCMArg.h>
#import <OCMock/OCMLocation.h>
#import <OCMock/OCMMacroState.h>
#import <OCMock/OCMStubMacroState.h>
#import <OCMock/OCMVerifyMacroState.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>


#define OCMClassMock(cls) [OCMockObject niceMockForClass:cls]

#define OCMStrictClassMock(cls) [OCMockObject mockForClass:cls]

#define OCMProtocolMock(protocol) [OCMockObject niceMockForProtocol:protocol]

#define OCMStrictProtocolMock(protocol) [OCMockObject mockForProtocol:protocol]

#define OCMPartialMock(obj) [OCMockObject partialMockForObject:obj]

#define OCMObserverMock() [OCMockObject observerMock]


#define OCMStub(invocation) \
({ \
    [OCMMacroState beginStubMacro]; \
    invocation; \
    [OCMMacroState endStubMacro]; \
})

#define OCMExpect(invocation) \
({ \
    [OCMMacroState beginExpectMacro]; \
    invocation; \
    [OCMMacroState endExpectMacro]; \
})

#define ClassMethod(invocation) \
    [(OCMStubMacroState *)[OCMMacroState globalState] setShouldRecordAsClassMethod:YES]; \
    invocation;


#define OCMVerifyAll(mock) [mock verifyAtLocation:OCMMakeLocation(self, __FILE__, __LINE__)]

#define OCMVerify(invocation) \
({ \
    [OCMMacroState beginVerifyMacroAtLocation:OCMMakeLocation(self, __FILE__, __LINE__)]; \
    invocation; \
    [OCMMacroState endVerifyMacro]; \
})
