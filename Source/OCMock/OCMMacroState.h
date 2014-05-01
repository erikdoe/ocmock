//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMockRecorder;
@class OCMLocation;


@interface OCMMacroState : NSObject
{
    BOOL           shouldRecordExpectation;
    BOOL           shouldRecordAsClassMethod;
    BOOL           shouldVerifyInvocation;
    OCMockRecorder *recorder;
    OCMLocation    *location;
}

+ (OCMMacroState *)globalState;

+ (void)beginStubMacro;
+ (OCMockRecorder *)endStubMacro;

+ (void)beginExpectMacro;
+ (OCMockRecorder *)endExpectMacro;

- (void)setShouldRecordExpectation:(BOOL)flag;
- (BOOL)shouldRecordExpectation;

- (void)setShouldRecordAsClassMethod:(BOOL)flag;
- (BOOL)shouldRecordAsClassMethod;

- (void)setRecorder:(OCMockRecorder *)aRecorder;
- (OCMockRecorder *)recorder;

+ (void)beginVerifyMacro;
+ (void)endVerifyMacro;

- (void)setShouldVerifyInvocation:(BOOL)flag;
- (BOOL)shouldVerifyInvocation;

- (void)setLocation:(OCMLocation *)aLocation;
- (OCMLocation *)location;


@end