#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

@interface OCMArg(OCMArgumentCaptureConstraint)

+ (id)capture:(void *)captor;

@end

@interface OCMArgumentCaptureConstraint : OCMConstraint {
	id __strong *_captor;
}

- (id)initWithCaptor:(id __strong *)captor;

@end
