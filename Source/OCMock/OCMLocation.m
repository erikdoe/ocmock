//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMLocation.h"

@interface NSException(OCMKnownExceptionMethods)
+ (NSException *)failureInFile:(NSString *)file atLine:(int)line withDescription:(NSString *)formatString, ...;
@end

@interface NSObject(OCMKnownTestCaseMethods)
- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)file atLine:(NSUInteger)line expected:(BOOL)expected;
- (void)failWithException:(NSException *)exception;
@end


@implementation OCMLocation

+ (id)locationWithTestCase:(id)aTestCase file:(NSString *)aFile line:(NSUInteger)aLine
{
    return [[[OCMLocation alloc] initWithTestCase:aTestCase file:aFile line:aLine] autorelease];
}

- (id)initWithTestCase:(id)aTestCase file:(NSString *)aFile line:(NSUInteger)aLine
{
    [super init];
    testCase = aTestCase;
    file = [aFile retain];
    line = aLine;
    return self;
}

- (void)dealloc
{
    [file release];
    [super dealloc];
}

- (id)testCase
{
    return testCase;
}

- (NSString *)file
{
    return file;
}

- (NSUInteger)line
{
    return line;
}


- (void)reportFailure:(NSString *)description
{
    if((testCase != nil) && [testCase respondsToSelector:@selector(recordFailureWithDescription:inFile:atLine:expected:)])
    {
        [testCase recordFailureWithDescription:description inFile:file atLine:line expected:NO];
    }
    else if((testCase != nil) && [testCase respondsToSelector:@selector(failWithException:)])
    {
        NSException *exception = nil;
        if([NSException instancesRespondToSelector:@selector(failureInFile:atLine:withDescription:)])
        {
            exception = [NSException failureInFile:file atLine:(int)line withDescription:description];
        }
        else
        {
            NSString *reason = [NSString stringWithFormat:@"%@:%lu %@", file, (unsigned long)line, description];
            exception = [NSException exceptionWithName:@"OCMockTestFailure" reason:reason userInfo:nil];
        }
        [testCase failWithException:exception];
    }
    else
    {
        NSLog(@"%@:%lu %@", file, (unsigned long)line, description);
        NSString *reason = [NSString stringWithFormat:@"%@:%lu %@", file, (unsigned long)line, description];
        NSException *exception = [NSException exceptionWithName:@"OCMockTestFailure" reason:reason userInfo:nil];
        [exception raise];
        
    }
    
}

@end


OCMLocation *OCMMakeLocation(id testCase, const char *fileCString, int line)
{
    return [OCMLocation locationWithTestCase:testCase file:[NSString stringWithUTF8String:fileCString] line:line];
}

