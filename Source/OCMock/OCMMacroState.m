//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMMacroState.h"
#import "OCMockRecorder.h"
#import "OCMVerifyMacroState.h"
#import "OCMStubMacroState.h"


@implementation OCMMacroState

OCMMacroState *globalState;


+ (void)beginStubMacro
{
    globalState = [[OCMStubMacroState alloc] init];
}

+ (OCMockRecorder *)endStubMacro
{
    OCMockRecorder *recorder = [((OCMStubMacroState *)globalState) recorder];
    [globalState autorelease];
    globalState = nil;
    return recorder;
}


+ (void)beginExpectMacro
{
    [self beginStubMacro];
    [(OCMStubMacroState *)globalState setShouldRecordExpectation:YES];
}

+ (OCMockRecorder *)endExpectMacro
{
    return [self endStubMacro];
}


+ (void)beginVerifyMacroAtLocation:(OCMLocation *)aLocation
{
    globalState = [[OCMVerifyMacroState alloc] initWithLocation:aLocation];
}

+ (void)endVerifyMacro
{
    [globalState autorelease];
    globalState = nil;
}


+ (OCMMacroState *)globalState
{
    return globalState;
}


- (void)handleInvocation:(NSInvocation *)anInvocation
{
    // to be implemented by subclasses
}


@end
