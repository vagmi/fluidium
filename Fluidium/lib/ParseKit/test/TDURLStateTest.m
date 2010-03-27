//
//  TDURLStateTest.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDURLStateTest.h"

@implementation TDURLStateTest

- (void)setUp {
    t = [[PKTokenizer alloc] init];
    URLState = t.URLState;
}


- (void)tearDown {
    [t release];
}


//- (void)testFooComBlahBlah {
//    s = @"http://foo.com/blah_blah";
//    t.string = s;
//        
//    tok = [t nextToken];
//    
//    TDTrue(tok.isURL);
//    TDEqualObjects(tok.stringValue, s);
//    TDEquals(tok.floatValue, (CGFloat)0.0);
//    
//    tok = [t nextToken];
//    TDEqualObjects(tok, [PKToken EOFToken]);
//}
//
//
//- (void)testFooComBlahBlahSlash {
//    s = @"http://foo.com/blah_blah/";
//    t.string = s;
//    
//    tok = [t nextToken];
//    
//    TDTrue(tok.isURL);
//    TDEqualObjects(tok.stringValue, s);
//    TDEquals(tok.floatValue, (CGFloat)0.0);
//    
//    tok = [t nextToken];
//    TDEqualObjects(tok, [PKToken EOFToken]);
//}
//
//
//- (void)testSomethingLikeFooComBlahBlahSlash {
//    s = @"(Something like http://foo.com/blah_blah)";
//    t.string = s;
//    
//    tok = [t nextToken];
//    TDTrue(tok.isSymbol);
//    TDEqualObjects(tok.stringValue, @"(");
//    TDEquals(tok.floatValue, (CGFloat)0.0);
//    
//    tok = [t nextToken];
//    TDTrue(tok.isWord);
//    TDEqualObjects(tok.stringValue, @"Something");
//    TDEquals(tok.floatValue, (CGFloat)0.0);
//    
//    tok = [t nextToken];
//    TDTrue(tok.isWord);
//    TDEqualObjects(tok.stringValue, @"like");
//    TDEquals(tok.floatValue, (CGFloat)0.0);
//    
//    tok = [t nextToken];
//    TDTrue(tok.isURL);
//    TDEqualObjects(tok.stringValue, @"http://foo.com/blah_blah");
//    TDEquals(tok.floatValue, (CGFloat)0.0);
//    
//    tok = [t nextToken];
//    TDTrue(tok.isSymbol);
//    TDEqualObjects(tok.stringValue, @")");
//    TDEquals(tok.floatValue, (CGFloat)0.0);
//    
//    tok = [t nextToken];
//    TDEqualObjects(tok, [PKToken EOFToken]);
//}

/*
 http://foo.com/blah_blah
 http://foo.com/blah_blah/
 (Something like http://foo.com/blah_blah)
 http://foo.com/blah_blah_(wikipedia)
 (Something like http://foo.com/blah_blah_(wikipedia))
 http://foo.com/blah_blah.
 http://foo.com/blah_blah/.
 <http://foo.com/blah_blah>
 <http://foo.com/blah_blah/>
 http://foo.com/blah_blah,
 http://www.example.com/wpstyle/?p=364.
 http://✪df.ws/123
 rdar://1234
 rdar:/1234
 http://userid:password@example.com:8080
 http://userid@example.com
 http://userid@example.com:8080
 http://userid:password@example.com
 http://example.com:8080 x-yojimbo-item://6303E4C1-xxxx-45A6-AB9D-3A908F59AE0E
 message://%3c330e7f8409726r6a4ba78dkf1fd71420c1bf6ff@mail.gmail.com%3e
 http://➡.ws/䨹
 www.➡.ws/䨹
 <tag>http://example.com</tag>
 Just a www.example.com link.
 */

@end
