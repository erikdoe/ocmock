/*
 *  Copyright (c) 2013-2020 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "OCMIssueReporter.h"
#import "OCMock.h"
#import "OCClassMockObject.h"

@interface OCMIssueReporterTests : XCTestCase
@end


@implementation OCMIssueReporterTests

- (void)testPushPopOfIssueTreatment
{
    // Default Settings
    OCMIssueReporter *reporter = [OCMIssueReporter defaultReporter];
    XCTAssertEqual([reporter issueTreatment], OCMIssueTreatmentWarnings);
    [reporter pushIssueTreatment:OCMIssueTreatmentWarnings];
    XCTAssertEqual([reporter issueTreatment], OCMIssueTreatmentWarnings);
    [reporter popIssueTreatment];
    XCTAssertEqual([reporter issueTreatment], OCMIssueTreatmentWarnings);
    [reporter pushIssueTreatment:OCMIssueTreatmentErrors];
    [reporter pushIssueTreatment:OCMIssueTreatmentErrors];
    XCTAssertEqual([reporter issueTreatment], OCMIssueTreatmentErrors);
    [reporter popIssueTreatment];
    XCTAssertEqual([reporter issueTreatment], OCMIssueTreatmentErrors);
    [reporter popIssueTreatment];
    XCTAssertEqual([reporter issueTreatment], OCMIssueTreatmentWarnings);
}

- (void)testPushPopOfIssueTreatmentOnThreadThrows
{
    XCTestExpectation *finishedThreadExpectation = [self expectationWithDescription:@"Waiting On Thread"];
    [NSThread detachNewThreadWithBlock:^{
        OCMIssueReporter *reporter = [OCMIssueReporter defaultReporter];
        XCTAssertThrowsSpecificNamed([reporter pushIssueTreatment:OCMIssueTreatmentErrors], NSException, NSInternalInconsistencyException);
        XCTAssertThrowsSpecificNamed([reporter popIssueTreatment], NSException, NSInternalInconsistencyException);
        [finishedThreadExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testDefaultIssueReporterThrowsOnOverPop
{
    OCMIssueReporter *reporter = [OCMIssueReporter defaultReporter];
    XCTAssertThrowsSpecificNamed([reporter popIssueTreatment], NSException, NSInternalInconsistencyException);
}

- (void)testRepectsEnvironmentSettings
{
    id processInfoMock = OCMClassMock([NSProcessInfo class]);
    OCMStub([processInfoMock processInfo]).andReturn(processInfoMock);
    OCMExpect([processInfoMock environment]).andReturn(@{OCMIssueTreatmentDefaultEnvironmentVariable: @(OCMIssueTreatmentErrors)});

    OCMIssueReporter *reporter = [[OCMIssueReporter alloc] init];
    XCTAssertEqual([reporter issueTreatment], OCMIssueTreatmentErrors);
}

- (void)testThrowsWithBadEnvironmentSettings
{
    id processInfoMock = OCMClassMock([NSProcessInfo class]);
    OCMStub([processInfoMock processInfo]).andReturn(processInfoMock);
    OCMExpect([processInfoMock environment]).andReturn(@{OCMIssueTreatmentDefaultEnvironmentVariable: @(5)});

    XCTAssertThrowsSpecificNamed([[OCMIssueReporter alloc] init], NSException, NSInvalidArgumentException);
    OCMVerifyAll(processInfoMock);
}

- (void)testThrowsWhenIssuesAreErrors
{
    OCMIssueReporter *reporter = [OCMIssueReporter defaultReporter];
    [reporter pushIssueTreatment:OCMIssueTreatmentErrors];
    id stub = OCMClassMock([NSString class]);
    [stub stopMocking];
    XCTAssertThrowsSpecificNamed([stub lowercaseString], NSException, NSInternalInconsistencyException);
    [reporter popIssueTreatment];
}

- (void)testLogsWhenIssuesAreWarnings
{
    OCMIssueReporter *reporter = [OCMIssueReporter defaultReporter];
    [reporter pushIssueTreatment:OCMIssueTreatmentWarnings];
    id stub = OCMClassMock([NSString class]);
    [stub stopMocking];
    XCTAssertNoThrow([stub lowercaseString]);
    [reporter popIssueTreatment];
}

@end
