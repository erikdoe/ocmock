//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMStubMacroState.h"
#import "OCMockObject.h"
#import "OCMockRecorder.h"

@implementation OCMStubMacroState

- (void)setShouldRecordExpectation:(BOOL)flag
{
    shouldRecordExpectation = flag;
}

- (void)setShouldRecordAsClassMethod:(BOOL)flag
{
    shouldRecordAsClassMethod = flag;
}

- (OCMockRecorder *)recorder
{
    return recorder;
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
    OCMockObject *mock = [anInvocation target];
    recorder = shouldRecordExpectation ? [mock expect] : [mock stub];
    if(shouldRecordAsClassMethod)
        [recorder classMethod];
    [recorder forwardInvocation:anInvocation];
}

@end
