//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2010 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

#ifdef MAC_OS_X_VERSION_10_6

@interface OCMBlockCaller : NSObject 
{
	void (^block)(NSInvocation *);
}

-(id)initWithCallBlock:(void (^)(NSInvocation *))theBlock;

@end

#endif
