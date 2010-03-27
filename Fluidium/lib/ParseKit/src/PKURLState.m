//
//  PKURLState.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/26/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <ParseKit/PKURLState.h>
#import <ParseKit/PKReader.h>
#import <ParseKit/PKTokenizer.h>
#import <ParseKit/PKToken.h>
#import <ParseKit/PKTypes.h>
#import <RegexKitLite.h>

@interface PKToken ()
@property (nonatomic, readwrite) NSUInteger offset;
@end

@interface PKTokenizerState ()
- (void)resetWithReader:(PKReader *)r;
- (void)append:(PKUniChar)c;
- (NSString *)bufferedString;
- (PKTokenizerState *)nextTokenizerStateFor:(PKUniChar)c tokenizer:(PKTokenizer *)t;
@end

@interface PKURLState ()
- (BOOL)isBreak:(PKUniChar)c;
- (BOOL)matchesRegex:(NSString *)s;
@end

@implementation PKURLState

- (void)dealloc {
    [super dealloc];
}


- (PKToken *)nextTokenFromReader:(PKReader *)r startingWith:(PKUniChar)cin tokenizer:(PKTokenizer *)t {
    NSParameterAssert(r);
    [self resetWithReader:r];
    
    PKUniChar c = cin;
    do {
        [self append:c];
        c = [r read];
    } while (![self isBreak:c]);
    
    if (PKEOF != c) {
        [r unread];
    }
    
    NSString *s = [self bufferedString];
    if ([self matchesRegex:s]) {
        PKToken *tok = [PKToken tokenWithTokenType:PKTokenTypeURL stringValue:s floatValue:0.0];
        tok.offset = offset;
        return tok;
    } else {
        [r unread:[s length] - 1];
        return [[self nextTokenizerStateFor:cin tokenizer:t] nextTokenFromReader:r startingWith:cin tokenizer:t];
    }
}


- (BOOL)isBreak:(PKUniChar)c {
    return PKEOF == c || ' ' == c || '\n' == c || '\r' == c || '\t' == c || ')' == c || '<' == c || '>' == c;
}


- (BOOL)matchesRegex:(NSString *)s {
    // [:punct:] == ! ' # S % & ' ( ) * + , - . / : ; < = > ? @ [ / ] ^ _ { | } ~
    //    !'#%&'()*+,./:;<=>?@[/]^_{|}~-
    //    \\s!'#%&'()*+,./:;<=>?@[/\\]^_{|}~-
    
    // Gruber original
    //  \b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))
    BOOL matches = [s isMatchedByRegex:@"(([[:alpha:]-]+://?|www[.])[^[:space:]()<>]+(?:\\([:alnum:]+\\)|([^[:punct:][:space:]]|/)))"];
    return matches;

    // Allan Storm
    //    //  \b(([\w-]+://?|www[.])[^\s()<>]+(?:(?:\([\w\d)]+\)[^\s()<>]*)+|([^[:punct:]\s]|/)))
    //    return [s isMatchedByRegex:@"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:(?:\\([\\w\\d)]+\\)[^\\s()<>]*)+|([^[:punct:]\\s]|/)))"];
}

/*
 
 - (void)setString:(NSString *)s {
    if (s != string) {
        [string release];
        string = [s copy];
        regfree(&pattern);

        if (string) {
            NSString *tmp = [[self class] regexpFromURIGlob:string];
            regcomp(&pattern, [[NSString stringWithFormat:@"^%@$", tmp] UTF8String], REG_NOSUB|REG_EXTENDED);
        }
    }
}


- (BOOL)isMatch:(NSString *)s {
    return 0 == regexec(&pattern, [s UTF8String], 0, NULL, 0);
}

*/
@end
