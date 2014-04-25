//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCMLocation.h"

@implementation OCMLocation

+ (id)locationWithTestCase:(id)aTestCase file:(NSString *)aFile line:(NSUInteger)aLine
{
    return [[[OCMLocation alloc] initWithTestCase:aTestCase file:aFile line:aLine] autorelease];
}

- (id)initWithTestCase:(id)aTestCase file:(NSString *)aFile line:(NSUInteger)aLine
{
    self = [super init];
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

@end


OCMLocation *OCMMakeLocation(id testCase, const char *fileCString, int line)
{
    return [OCMLocation locationWithTestCase:testCase file:[NSString stringWithUTF8String:fileCString] line:line];
}

