//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMockRecorder;


@interface OCMMacroState : NSObject
{
    BOOL           shouldRecordExpectation;
    BOOL           shouldRecordAsClassMethod;
    OCMockRecorder *recorder;
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

@end