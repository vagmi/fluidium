//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "CRTwitterPlugInPrefsViewController.h"
#import "CRTwitterPlugIn.h"
#import "AGKeychain.h"
#import <Fluidium/FUApplication.h>

#define KEYCHAIN_ITEM_NAME_FORMAT @"%@TwitterPlugIn"
#define KEYCHAIN_ITEM_KIND_USERNAME @"Username"
#define KEYCHAIN_ITEM_KIND_PASSWORD @"Password"

#define KEYCHAIN_USERNAME_FORMAT @"%@-username"
#define KEYCHAIN_PASSWORD_FORMAT @"%@-password"

@interface CRTwitterPlugInPrefsViewController ()
- (void)loadAccounts;

- (NSString *)usernameFromKeychainFor:(NSString *)accountID;
- (NSString *)passwordFromKeychainFor:(NSString *)accountID;
- (BOOL)deleteUsernameFromKeychainFor:(NSString *)accountID;
- (BOOL)deletePasswordFromKeychainFor:(NSString *)accountID;

- (void)storeUserAccounts;
- (void)storeAccountsInKeychain;
- (NSString *)newUniqueID;

- (void)startObservingRule:(NSMutableDictionary *)rule;
- (void)stopObservingRule:(NSMutableDictionary *)rule;
- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)inValue;

@property (nonatomic, copy) NSString *keychainName;
@end

@implementation CRTwitterPlugInPrefsViewController

- (id)init {
    return [self initWithNibName:@"CRTwitterPrefsView" bundle:[NSBundle bundleForClass:[self class]]];
}


- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b {
    if (self = [super initWithNibName:s bundle:b]) {
        NSString *appName = [[FUApplication instance] appName];
        self.keychainName = [NSString stringWithFormat:KEYCHAIN_ITEM_NAME_FORMAT, appName];

        [self loadAccounts];
    }
    return self;
}


- (void)dealloc {
    [self storeUserAccounts];
    [self storeAccountsInKeychain];
    self.arrayController = nil;
    self.accounts = nil;
    self.accountIDs = nil;
    self.keychainName = nil;
    [super dealloc];
}


- (IBAction)toggleShowUsernames:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:CRTwitterDisplayUsernamesDidChangeNotification object:nil];
}


- (void)updateUI {

}


- (void)loadAccounts {
    
    // this will trim accountIDs from the user defaults which correspond to accounts which for some reason have been deleted from the keychain
    NSArray *oldAccountIDs = [[NSUserDefaults standardUserDefaults] objectForKey:kCRTwitterAccountIDsKey];
    NSMutableArray *newAccountIDs = [NSMutableArray arrayWithCapacity:[oldAccountIDs count]];
    self.accounts = [NSMutableArray arrayWithCapacity:[accountIDs count]];

    for (NSString *accountID in oldAccountIDs) {
        NSString *username = [self usernameFromKeychainFor:accountID];
        NSString *password = [self passwordFromKeychainFor:accountID];
        
        if ([username length] && [password length]) {
            // both username and password were present in the keychain. we're good
            NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                               username, @"username",
                               password, @"password",
                               nil];
            
            [accounts addObject:d];
            [newAccountIDs addObject:accountID];
        } else {
            // either the username or password was missing (deleted by user). make sure they're both deleted (just to be tidy)
//            @try {
//                [self deleteUsernameFromKeychainFor:accountID];
//                [self deletePasswordFromKeychainFor:accountID];
//            } @catch (NSException *e) {
//                NSLog(@"failed to delete username or password: %@", e);
//            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:newAccountIDs forKey:kCRTwitterAccountIDsKey];
    self.accountIDs = newAccountIDs;
}


- (NSArray *)usernames {
    NSMutableArray *usernames = [NSMutableArray arrayWithCapacity:[accountIDs count]];
    for (NSString *accountID in accountIDs) {
        NSString *username = [self usernameFromKeychainFor:accountID];
        if ([username length]) {
            [usernames addObject:username];
        }
    }
    return usernames;
}


- (NSString *)passwordFor:(NSString *)username {
    NSInteger i = 0;
    for (NSDictionary *account in self.accounts) {
        if ([username isEqualToString:[account objectForKey:@"username"]]) {
            NSString *accountID = [self.accountIDs objectAtIndex:i];
            return [self passwordFromKeychainFor:accountID];
        }
        i++;
    }
    return nil;
}


- (NSString *)usernameFromKeychainFor:(NSString *)accountID {
    NSString *username = [AGKeychain getPasswordFromKeychainItem:[self keychainName] withItemKind:KEYCHAIN_ITEM_KIND_USERNAME forUsername:[NSString stringWithFormat:KEYCHAIN_USERNAME_FORMAT, accountID]];
    return username;
}


- (NSString *)passwordFromKeychainFor:(NSString *)accountID {
    NSString *password = [AGKeychain getPasswordFromKeychainItem:[self keychainName] withItemKind:KEYCHAIN_ITEM_KIND_PASSWORD forUsername:[NSString stringWithFormat:KEYCHAIN_PASSWORD_FORMAT, accountID]];
    return password;
}


- (BOOL)deleteUsernameFromKeychainFor:(NSString *)accountID {
    return [AGKeychain deleteKeychainItem:[self keychainName] withItemKind:KEYCHAIN_ITEM_KIND_USERNAME forUsername:[NSString stringWithFormat:KEYCHAIN_USERNAME_FORMAT, accountID]];
}


- (BOOL)deletePasswordFromKeychainFor:(NSString *)accountID {
    return [AGKeychain deleteKeychainItem:[self keychainName] withItemKind:KEYCHAIN_ITEM_KIND_PASSWORD forUsername:[NSString stringWithFormat:KEYCHAIN_PASSWORD_FORMAT, accountID]];
}


- (void)insertObject:(NSMutableDictionary *)dict inAccountsAtIndex:(NSInteger)i {
    NSUndoManager *undoManager = [[[self view] window] undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeObjectFromAccountsAtIndex:i];
    
    [self startObservingRule:dict];

    [self.accounts insertObject:dict atIndex:i];
    [self.accountIDs insertObject:[[self newUniqueID] autorelease] atIndex:i];
    
    [self storeUserAccounts];
}


- (void)removeObjectFromAccountsAtIndex:(NSInteger)i {
    NSMutableDictionary *rule = [self.accounts objectAtIndex:i];
    
    NSUndoManager *undoManager = [[[self view] window] undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertObject:rule inAccountsAtIndex:i];
    
    [self stopObservingRule:rule];

    NSString *accountID = [self.accountIDs objectAtIndex:i];
    @try {
        [self deleteUsernameFromKeychainFor:accountID];
        [self deletePasswordFromKeychainFor:accountID];
    } @catch (NSException *e) {
        NSLog(@"failed to delete username or password: %@", e);
    }
    
    [self.accounts removeObjectAtIndex:i];
    [self.accountIDs removeObjectAtIndex:i];
    
    [self storeUserAccounts];
}


- (void)storeUserAccounts {
    [[NSUserDefaults standardUserDefaults] setObject:self.accountIDs forKey:kCRTwitterAccountIDsKey];
    
    [self storeAccountsInKeychain];
}


- (void)storeAccountsInKeychain {

    NSInteger i = 0;
    for (NSString *accountID in self.accountIDs) {
        NSString *username = [[accounts objectAtIndex:i] objectForKey:@"username"];
        NSString *password = [[accounts objectAtIndex:i] objectForKey:@"password"];
        
        if ([username length] && [password length]) {
            [AGKeychain addKeychainItem:[self keychainName] withItemKind:KEYCHAIN_ITEM_KIND_USERNAME forUsername:[NSString stringWithFormat:KEYCHAIN_USERNAME_FORMAT, accountID] withPassword:username];
            [AGKeychain addKeychainItem:[self keychainName] withItemKind:KEYCHAIN_ITEM_KIND_PASSWORD forUsername:[NSString stringWithFormat:KEYCHAIN_PASSWORD_FORMAT, accountID] withPassword:password];
        }

        i++;
    }
}


- (NSString *)newUniqueID {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *s = (id)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return s;
}


- (void)startObservingRule:(NSMutableDictionary *)rule {
    [rule addObserver:self
           forKeyPath:@"username"
              options:NSKeyValueObservingOptionOld
              context:NULL];
    [rule addObserver:self
           forKeyPath:@"password"
              options:NSKeyValueObservingOptionOld
              context:NULL];
}


- (void)stopObservingRule:(NSMutableDictionary *)rule {
    @try {
        [rule removeObserver:self forKeyPath:@"username"];
        [rule removeObserver:self forKeyPath:@"password"];
    }
    @catch (NSException * e) {

    }
}


- (void)changeKeyPath:(NSString *)path ofObject:(id)obj toValue:(id)v {
    [obj setValue:v forKeyPath:path];
    [self storeUserAccounts];
}


- (void)observeValueForKeyPath:(NSString *)path ofObject:(id)obj change:(NSDictionary *)change context:(void *)context {
    NSUndoManager *undoManager = [[[self view] window] undoManager];
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    [[undoManager prepareWithInvocationTarget:self] changeKeyPath:path ofObject:obj toValue:oldValue];
    [self storeUserAccounts];
}


- (void)controlTextDidEndEditing:(NSNotification *)notification {
    [self storeUserAccounts];
}


- (void)setAccounts:(NSMutableArray *)inArray {
    if (accounts != inArray) {
        for (id rule in accounts) {
            [self stopObservingRule:rule];
        }
        
        [accounts autorelease];
        accounts = [inArray retain];
        
        for (id rule in accounts) {
            [self startObservingRule:rule];
        }
    }
}

@synthesize arrayController;
@synthesize accounts;
@synthesize accountIDs;
@synthesize keychainName;
@end
