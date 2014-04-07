//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMLocation : NSObject
{
    id          testCase;
    NSString    *file;
    NSUInteger  line;
}

+ (id)locationWithTestCase:(id)aTestCase file:(NSString *)aFile line:(NSUInteger)aLine;

- (id)initWithTestCase:(id)aTestCase file:(NSString *)aFile line:(NSUInteger)aLine;

- (id)testCase;
- (NSString *)file;
- (NSUInteger)line;

- (void)reportFailure:(NSString *)description;

@end

extern OCMLocation *OCMMakeLocation(id testCase, const char *file, int line);
