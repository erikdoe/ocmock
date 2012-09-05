//
//  NSObject+OCMFailureHandler.m
//  OCMock
//
//  Created by Ziad Khoury Hanna on 5/9/12.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import "NSObject+OCMFailureHandler.h"
#import <OCMock/OCMFailureHandler.h>

@implementation NSObject (OCMFailureHandler)

- (void)failWithException:(NSException *)anException {
	[anException raise];
}

@end
