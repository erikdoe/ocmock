//
//  OCMFailureHandler.h
//  OCMock
//
//  Created by Ziad Khoury Hanna on 4/9/12.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OCMFailureHandler <NSObject>
@required

- (void)failWithException:(NSException *)anException;

@end
