#import "OCMArgumentCaptureConstraint.h"

@implementation OCMArg(OCMArgumentCaptureConstraint)

+ (id)capture:(void *)captor {
	return [[OCMArgumentCaptureConstraint alloc] initWithCaptor:(id __strong *)captor];
}

@end

@interface OCMArgumentCaptureConstraint()

@end

@implementation OCMArgumentCaptureConstraint

- (id)initWithCaptor:(id __strong *)captor {
    if (self = [super init]) {
		_captor = captor;
    }
    return self;
}

- (BOOL)evaluate:(id)value {
	if ([self isBlock:value]) {
		*_captor = [value copy];
	} else {
		*_captor = value;
	}
	return YES;
}

- (BOOL)isBlock:(id)item {
	BOOL isBlock = NO;
	
#if NS_BLOCKS_AVAILABLE
	// find the block class at runtime in case it changes in a different OS version
	static Class blockClass = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		id block = ^{};
		blockClass = [block class];
		while ([blockClass superclass] != [NSObject class]) {
			blockClass = [blockClass superclass];
		}
	});
	
	isBlock = [item isKindOfClass:blockClass];
#endif
	
	return isBlock;
}
@end
