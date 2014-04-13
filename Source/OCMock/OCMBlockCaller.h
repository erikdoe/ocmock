//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2010 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>


@interface OCMBlockCaller : NSObject 
{
	void (^block)(NSInvocation *);
}

- (id)initWithCallBlock:(void (^)(NSInvocation *))theBlock;

- (void)handleInvocation:(NSInvocation *)anInvocation;

@end

