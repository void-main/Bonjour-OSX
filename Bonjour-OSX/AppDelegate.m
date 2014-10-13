//
//  AppDelegate.m
//  Bonjour-OSX
//
//  Created by Sun Peng on 14-10-11.
//  Copyright (c) 2014年 Peng Sun. All rights reserved.
//

#import "AppDelegate.h"

#import <BonjourSDK/BSBonjourManager.h>

#import "BJPublishActionButtonTransformer.h"
#import "BJPublishActionButtonEnableTransformer.h"

#define kServiceName     @"share_editor"
#define kServiceProtocol @"tcp"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *mainTextField;

@property (nonatomic, strong) BSBonjourManager *bonjourManager;

@property (nonatomic, assign) ServiceStartStatus status;
@property (nonatomic, strong) NSString *         statusText;

@property (nonatomic, strong, readwrite) NSNetService *     netService;
@property (nonatomic, assign, readwrite) CFSocketRef        listeningSocket;

@end

@implementation AppDelegate

+ (void)initialize
{
    if (self == [AppDelegate class]) {
        BJPublishActionButtonTransformer *transformer = [[BJPublishActionButtonTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer
                                        forName:@"BJPublishActionButtonTransformer"];

        BJPublishActionButtonEnableTransformer *enableTransformer = [[BJPublishActionButtonEnableTransformer alloc] init];
        [NSValueTransformer setValueTransformer:enableTransformer forName:@"BJPublishActionButtonEnableTransformer"];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.bonjourManager = [BSBonjourManager sharedManager];

    self.status = Stopped;
    self.statusText = @"Not Published";
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if (self.status == Started) {
        [self stopServer];
    }
}

- (IBAction)toggleAction:(id)sender {
    if (self.status == Started) {
        self.status = Stopping;
        [self stopServer];
    } else if (self.status == Stopped) {
        self.status = Starting;
        [self startServer];
    }
}

- (void)startServer
{
    [self.bonjourManager publish:kServiceName
               transportProtocol:kServiceProtocol
                            port:0
                        delegate:self];
}

- (void)stopServer
{
    [self.bonjourManager reclaim:kServiceName
               transportProtocol:kServiceProtocol];
}

#pragma mark -
#pragma mark BSBonjourPublishDelegate
- (void)published:(NSString *)name {
    self.status = Started;
    self.statusText = [NSString stringWithFormat:@"Service published with name: %@", name];
}

- (void)registerFailed:(NSError *)error
{
    self.status = Stopped;
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)publishFailed:(NSError *)error {
    self.status = Stopped;
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)serviceStopped:(NSString *)name {
    self.statusText = @"Service Stopped";
    self.status = Stopped;
}

@end
