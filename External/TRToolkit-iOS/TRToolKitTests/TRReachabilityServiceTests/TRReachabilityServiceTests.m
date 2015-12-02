//
//  TRReachabilityServiceTests.m
//  TRToolKit
//
//  Created by Pedro Gomes on 20/03/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import "TRAsyncTestCase.h"
#import "TRReachability.h"
#import "TRReachabilityService.h"
#import "TRUnitTestingMacros.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef NS_ENUM(NSInteger, TRReachabilityServiceTestsCallback) {
    TRReachabilityServiceTestsCallbackWIFIReachable,
    TRReachabilityServiceTestsCallbackWIFIUnreachable,
    
    TRReachabilityServiceTestsCallbackInternetReachable,
    TRReachabilityServiceTestsCallbackInternetUnreachable,
    
    TRReachabilityServiceTestsCallbackTestHostReachable,
    TRReachabilityServiceTestsCallbackTestHostUnreachable
};

NSString *const kTestHostIdentifier = @"test-host";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRReachabilityServiceTests : TRAsyncTestCase <TRReachabilityServiceDelegate>

@property (nonatomic, strong) TRReachabilityService *reachabilityService;
@property (nonatomic, strong) NSDictionary *reachabilityIdentifierToCallbackMap;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRReachabilityServiceTests

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)setUp
{
    [super setUp];
    self.reachabilityService = [TRReachabilityService sharedInstance];
    self.reachabilityIdentifierToCallbackMap = @{kTRReachabilityServiceIdentifierInternet:
                                                     @{@(TRReachabilityServiceStatusReachable):    @(TRReachabilityServiceTestsCallbackInternetReachable),
                                                       @(TRReachabilityServiceStatusUnreachable):  @(TRReachabilityServiceTestsCallbackInternetUnreachable)},
                                                 kTRReachabilityServiceIdentifierLocalWIFI:
                                                     @{@(TRReachabilityServiceStatusReachable):    @(TRReachabilityServiceTestsCallbackWIFIReachable),
                                                       @(TRReachabilityServiceStatusUnreachable):  @(TRReachabilityServiceTestsCallbackWIFIUnreachable)},
                                                 kTestHostIdentifier:
                                                     @{@(TRReachabilityServiceStatusReachable):    @(TRReachabilityServiceTestsCallbackTestHostReachable),
                                                       @(TRReachabilityServiceStatusUnreachable):  @(TRReachabilityServiceTestsCallbackTestHostUnreachable)}
                                                 };
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)tearDown
{
    [super tearDown];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(WIFIReachable)
{
    [self.reachabilityService registerDelegate:self forIdentifier:kTRReachabilityServiceIdentifierLocalWIFI];
    
    [self registerExpectedCallback:@(TRReachabilityServiceTestsCallbackWIFIReachable)];

    [self.reachabilityService start];

    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:60.0];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(WIFIUnreachable)
{
    [self.reachabilityService registerDelegate:self forIdentifier:kTRReachabilityServiceIdentifierLocalWIFI];
    
    [self registerExpectedCallback:@(TRReachabilityServiceTestsCallbackWIFIUnreachable)];
    
    [self.reachabilityService start];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:60.0];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(InternetReachable)
{
    [self.reachabilityService registerDelegate:self forIdentifier:kTRReachabilityServiceIdentifierInternet];
    
    [self registerExpectedCallback:@(TRReachabilityServiceTestsCallbackInternetReachable)];
    
    [self.reachabilityService start];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:60.0];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(InternetUnreachable)
{
    [self.reachabilityService registerDelegate:self forIdentifier:kTRReachabilityServiceIdentifierInternet];
    
    [self registerExpectedCallback:@(TRReachabilityServiceTestsCallbackInternetUnreachable)];
    
    [self.reachabilityService start];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:60.0];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(TestHostReachable)
{
    [self.reachabilityService addHostname:@"thomsonreuters.com" withIdentifier:kTestHostIdentifier];
    [self.reachabilityService registerDelegate:self];
    
    [self registerExpectedCallback:@(TRReachabilityServiceTestsCallbackTestHostReachable)];
    
    [self.reachabilityService start];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:60.0];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(TestHostUnreachable)
{
    [self.reachabilityService addHostname:@"xxxthomsonreuters.com" withIdentifier:kTestHostIdentifier];
    [self.reachabilityService registerDelegate:self];
    
    [self registerExpectedCallback:@(TRReachabilityServiceTestsCallbackTestHostUnreachable)];
    
    [self.reachabilityService start];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:60.0];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)reachabilityWithIdentifierDidChange:(NSString *)identifier status:(TRReachabilityServiceStatus)status
{
    if(self.reachabilityIdentifierToCallbackMap[identifier] == nil) {
        [self notify:XCTAsyncTestCaseStatusFailed];
        return;
    }
    
    NSNumber *callbackSignal = self.reachabilityIdentifierToCallbackMap[identifier][@(status)];
    [self signalCallbackReceived:callbackSignal];
}

@end
