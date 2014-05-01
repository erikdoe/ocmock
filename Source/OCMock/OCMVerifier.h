//---------------------------------------------------------------------------------------
//  Copyright (c) 20014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMockObject;


@interface OCMVerifier : NSProxy
{
    OCMockObject    *mockObject;
}

- (id)initWithMockObject:(OCMockObject *)aMockObject;

@end
