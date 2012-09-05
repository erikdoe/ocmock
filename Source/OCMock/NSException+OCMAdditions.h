//
//  NSException+OCMAdditions.h
//  OCMock
//
//  Created by Ziad Khoury Hanna on 4/9/12.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCMockRecorder, OCMObserverRecorder;

@interface NSException (OCMAdditions)

+ (NSException *)failureInMockInFile:(NSString *)filename atLine:(int)lineNumber withDescription:(NSString *)formatString, ...;
+ (NSException *)failureInMockRecorder:(OCMockRecorder *)recorder withDescription:(NSString *)formatString, ...;
+ (NSException *)failureInObserverRecorder:(OCMObserverRecorder *)recorder withDescription:(NSString *)formatString, ...;

@end
