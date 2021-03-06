//
//  BlogJetpackTest.m
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <OHHTTPStubs/OHHTTPStubs.h>
#import "BlogJetpackTest.h"
#import "CoreDataTestHelper.h"
#import "AsyncTestHelper.h"
#import "Blog+Jetpack.h"

@implementation BlogJetpackTest {
    Blog *_blog;
}

- (void)setUp {
    [[CoreDataTestHelper sharedHelper] registerDefaultContext];
    _blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
    _blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    _blog.url = @"http://test.blog/";
    _blog.options = @{@"jetpack_version": @{
                              @"value": @"1.8.2",
                              @"desc": @"stub",
                              @"readonly": @YES,
                              },
                      @"jetpack_client_id": @{
                              @"value": @"1",
                              @"desc": @"stub",
                              @"readonly": @YES,
                              },
                      };
    [_blog removeJetpackCredentials];
}

- (void)tearDown {
    _blog = nil;
    [[CoreDataTestHelper sharedHelper] reset];
    [OHHTTPStubs removeAllRequestHandlers];
}

- (void)testAssertionsOnWPcom {
    _blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityWithName:@"Blog"];
    _blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    _blog.url = @"http://test.wordpress.com/";
    XCTAssertThrows([_blog hasJetpack], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog jetpackVersion], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog jetpackUsername], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog jetpackPassword], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog jetpackBlogID], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog removeJetpackCredentials], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog validateJetpackUsername:@"test" password:@"test" success:nil failure:nil], @"WordPress.com blogs don't support Jetpack methods");
}

- (void)testHasJetpack {
    XCTAssertTrue([_blog hasJetpack]);
    _blog.options = nil;
    XCTAssertFalse([_blog hasJetpack]);
}

- (void)testJetpackVersion {
    XCTAssertEqualObjects([_blog jetpackVersion], @"1.8.2");
}

- (void)testJetpackBlogId {
    XCTAssertEqualObjects([_blog jetpackBlogID], @1);
}

- (void)testJetpackUsername {
    XCTAssertNil([_blog jetpackUsername]);
}

- (void)testJetpackPassword {
    XCTAssertNil([_blog jetpackPassword]);
}

- (void)testValidateCredentials {
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:@"https://public-api.wordpress.com/get-user-blogs/1.0?f=json"] &&
        [[request valueForHTTPHeaderField:@"Authorization"] isEqualToString:@"Basic dGVzdDE6dGVzdDE="]; // test1:test1
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFile:@"get-user-blogs_doesnt-have-blog.json" contentType:@"application/json" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];

    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:@"https://public-api.wordpress.com/get-user-blogs/1.0?f=json"] &&
        [[request valueForHTTPHeaderField:@"Authorization"] isEqualToString:@"Basic dGVzdDI6dGVzdDI="]; // test2:test2
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFile:@"get-user-blogs_has-blog.json" contentType:@"application/json" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];

    ATHStart();
    [_blog validateJetpackUsername:@"test1" password:@"test1" success:^{
        XCTFail(@"User test1 shouldn't have access to test.blog");
        ATHNotify();
    } failure:^(NSError *error) {
        XCTAssertEqual(error.domain, BlogJetpackErrorDomain);
        XCTAssertEqual(error.code, BlogJetpackErrorCodeNoRecordForBlog);
        ATHNotify();
    }];
    ATHEnd();

    ATHStart();
    [_blog validateJetpackUsername:@"test2" password:@"test2" success:^{
        ATHNotify();
    } failure:^(NSError *error) {
        XCTFail(@"User test2 should have access to test.blog");
        ATHNotify();
    }];
    ATHEnd();
}

@end
