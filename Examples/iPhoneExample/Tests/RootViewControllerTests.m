//
//  RootViewControllerTests.m
//  iPhoneExample
//
//  Created by Erik Doernenburg on 20/07/10.
//  Copyright 2010 Mulle Kybernetik. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "RootViewControllerTests.h"
#import "RootViewController.h"


@implementation RootViewControllerTests

- (void)testControllerReturnsCorrectNumberOfRows
{
	RootViewController *controller = [[[RootViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	
	STAssertEquals(1, [controller tableView:nil numberOfRowsInSection:0], @"Should have returned correct number of rows.");
}

- (void)testControllerSetsUpCellCorrectly
{
	RootViewController *controller = [[[RootViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	id mockTableView = [OCMockObject mockForClass:[UITableView class]];
	[[[mockTableView expect] andReturn:nil] dequeueReusableCellWithIdentifier:@"HelloWorldCell"];
	
	UITableViewCell *cell = [controller tableView:mockTableView cellForRowAtIndexPath:nil];
	
	STAssertNotNil(cell, @"Should have returned a cell");
	[mockTableView verify];
}


@end
