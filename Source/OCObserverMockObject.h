//---------------------------------------------------------------------------------------
//  $Id: OCObserverMockObject.h $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCObserverMockObject : NSObject 
{
	NSMutableArray *recorders;
}

- (id)expect;

- (void)verify;

@end
