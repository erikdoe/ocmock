//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMMacroState.h"

@class OCMockRecorder;


@interface OCMStubMacroState : OCMMacroState
{
    BOOL           shouldRecordExpectation;
    BOOL           shouldRecordAsClassMethod;
    OCMockRecorder *recorder;
}

- (void)setShouldRecordExpectation:(BOOL)flag;
- (void)setShouldRecordAsClassMethod:(BOOL)flag;
- (OCMockRecorder *)recorder;

@end
