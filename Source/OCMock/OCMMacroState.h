//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMLocation;
@class OCMockRecorder;


@interface OCMMacroState : NSObject
{
}

+ (void)beginStubMacro;
+ (OCMockRecorder *)endStubMacro;

+ (void)beginExpectMacro;
+ (OCMockRecorder *)endExpectMacro;

+ (void)beginVerifyMacroAtLocation:(OCMLocation *)aLocation;
+ (void)endVerifyMacro;

+ (OCMMacroState *)globalState;

- (void)handleInvocation:(NSInvocation *)anInvocation;

@end
