#import <Foundation/Foundation.h>

@interface OCMSaveObjects : NSObject 
{
  NSMutableArray *array;
}

- (id)initWithArray:(NSMutableArray*)aArray;

- (void)setObject:(id)aObject;

@end
