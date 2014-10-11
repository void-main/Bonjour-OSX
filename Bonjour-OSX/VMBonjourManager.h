//
//  VMBonjourManager.h
//  Bonjour-OSX
//
//  Created by Sun Peng on 14-10-11.
//  Copyright (c) 2014年 Peng Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kVMBonjourPublishDomain @"VMBonjourPublish"
#define kVMBonjourPublishErrorRegisterFailed -1
#define kVMBonjourPublishErrorPublishFailed  -2

#define kVMBonjourBrowseDomain @"VMBonjourBrowse"
#define kVMBonjourBrowseErrorBrowseFailed -1

#define kVMBonjourConnectDomain @"VMBonjourConnect"
#define kVMBonjourConnectErrorConnectFailed  -1

@protocol VMBonjourPublishDelegate <NSObject>

- (void)published:(NSString *)name;
- (void)serviceStopped:(NSString *)name;
- (void)registerFailed:(NSError *)error;
- (void)publishFailed:(NSError *)error;

@end

@protocol VMBonjourBrowseDelegate <NSObject>

- (void)didFindService:(NSNetService *)service moreComing:(BOOL)moreComing;
- (void)didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing;

- (void)searchStarted;
- (void)searchFailed:(NSError *)error;
- (void)searchStopped;

@end

@interface VMBonjourManager : NSObject <NSNetServiceDelegate, NSNetServiceBrowserDelegate>

@property (nonatomic, strong) NSMutableDictionary *publishedServices;
@property (nonatomic, strong) NSMutableDictionary *publishDelegates;

@property (nonatomic, strong) NSNetServiceBrowser        *serviceBrowser;
@property (nonatomic, strong) id<VMBonjourBrowseDelegate> serviceBrowserDelegate;

// Singleton Method
+ (id)sharedManager;

// Bonjour Publish
- (void)publish:(NSString *)serviceType transportProtocol:(NSString *)transportProtocol port:(uint16_t)port delegate:(id<VMBonjourPublishDelegate>)delegate;
- (void)reclaim:(NSString *)serviceType transportProtocol:(NSString *)transportProtocol;

// Bonjour Search
- (void)search:(NSString *)serviceType transportProtocol:(NSString *)transportProtocol delegate:(id<VMBonjourBrowseDelegate>)delegate;
- (void)stopSearch:(NSString *)serviceType transportProtocol:(NSString *)transportProtocol;

// Resolve
- (void)connectToService:(NSNetService *)service delegate:(id<NSStreamDelegate>)delegate error:(NSError **)error;

@end
