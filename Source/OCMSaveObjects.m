#import "OCMSaveObjects.h"

@implementation OCMSaveObjects

- (id)initWithArray:(NSMutableArray*)aArray
{
	[super init];
  array = [aArray retain];
	return self;
}

- (void)dealloc
{
  [array release];
	[super dealloc];
}

- (void)setObject:(id)aObject
{
  if (aObject == nil)
  {
    [array addObject:[NSNull null]];
  }
  else
  {
    [array addObject:aObject];
  }
}

@end
