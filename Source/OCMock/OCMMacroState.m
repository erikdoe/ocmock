//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMMacroState.h"
#import "OCMockRecorder.h"


@implementation OCMMacroState

OCMMacroState *globalState;


+ (OCMMacroState *)globalState
{
    return globalState;
}

+ (void)beginStubMacro
{
    globalState = [[OCMMacroState alloc] init];
}

+ (OCMockRecorder *)endStubMacro
{
    OCMockRecorder *recorder = [globalState recorder];
    [globalState autorelease];
    globalState = nil;
    return recorder;
}

+ (void)beginExpectMacro
{
    [self beginStubMacro];
    [globalState setShouldRecordExpectation:YES];
}

+ (OCMockRecorder *)endExpectMacro
{
    return [self endStubMacro];
}


- (void)setShouldRecordExpectation:(BOOL)flag
{
    shouldRecordExpectation = flag;
}

- (BOOL)shouldRecordExpectation
{
    return shouldRecordExpectation;
}


- (void)setShouldRecordAsClassMethod:(BOOL)flag
{
    shouldRecordAsClassMethod = YES;
}

- (BOOL)shouldRecordAsClassMethod
{
    return shouldRecordAsClassMethod;
}


- (void)setRecorder:(OCMockRecorder *)aRecorder
{
    if(recorder != nil)
    {
        [NSException raise:NSInternalInconsistencyException format:@"Trying to set recorder in global state, but a recorder has already been set."];
    }
    recorder = aRecorder;
}

- (OCMockRecorder *)recorder
{
    return recorder;
}

@end
