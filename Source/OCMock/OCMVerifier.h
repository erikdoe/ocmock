//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMockObject;


@interface OCMVerifier : NSProxy
{
    OCMockObject    *mockObject;
    BOOL            verifyAsClassMethod;
}

- (id)initWithMockObject:(OCMockObject *)aMockObject;

@end
