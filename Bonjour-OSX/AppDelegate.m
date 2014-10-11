//
//  AppDelegate.m
//  Bonjour-OSX
//
//  Created by Sun Peng on 14-10-11.
//  Copyright (c) 2014年 Peng Sun. All rights reserved.
//

#import "AppDelegate.h"

#include <CFNetwork/CFNetwork.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#define kListeningPort 9999

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, strong) VMBonjourManager *bonjourManager;

@property (nonatomic, assign, readonly ) BOOL               isStarted;
@property (nonatomic, assign, readonly ) BOOL               isReceiving;
@property (nonatomic, strong, readwrite) NSNetService *     netService;
@property (nonatomic, assign, readwrite) CFSocketRef        listeningSocket;
@property (nonatomic, strong, readwrite) NSInputStream *    networkStream;
@property (nonatomic, strong, readwrite) NSOutputStream *   fileStream;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.bonjourManager = [VMBonjourManager sharedManager];

    [self startServer];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self stopServer];
}

static void AcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    NSLog(@"Accept Callback!");
}

- (void)startServer
{
    BOOL                success;
    int                 err;
    int                 fd;
    int                 junk;
    struct sockaddr_in  addr;
    NSUInteger          port;

    // Create a listening socket and use CFSocket to integrate it into our
    // runloop.  We bind to port 0, which causes the kernel to give us
    // any free port, then use getsockname to find out what port number we
    // actually got.

    port = 0;

    fd = socket(AF_INET, SOCK_STREAM, 0);
    success = (fd != -1);

    if (success) {
        memset(&addr, 0, sizeof(addr));
        addr.sin_len    = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_port   = 0;
        addr.sin_addr.s_addr = INADDR_ANY;
        err = bind(fd, (const struct sockaddr *) &addr, sizeof(addr));
        success = (err == 0);
    }
    if (success) {
        err = listen(fd, 5);
        success = (err == 0);
    }
    if (success) {
        socklen_t   addrLen;

        addrLen = sizeof(addr);
        err = getsockname(fd, (struct sockaddr *) &addr, &addrLen);
        success = (err == 0);

        if (success) {
            assert(addrLen == sizeof(addr));
            port = ntohs(addr.sin_port);
        }
    }
    if (success) {
        CFSocketContext context = { 0, (__bridge void *) self, NULL, NULL, NULL };

        assert(_listeningSocket == NULL);
        _listeningSocket = CFSocketCreateWithNative(
                                                    NULL,
                                                    fd,
                                                    kCFSocketAcceptCallBack,
                                                    AcceptCallback,
                                                    &context
                                                    );
        success = (_listeningSocket != NULL);

        if (success) {
            CFRunLoopSourceRef  rls;

            fd = -1;        // listeningSocket is now responsible for closing fd

            rls = CFSocketCreateRunLoopSource(NULL, self.listeningSocket, 0);
            assert(rls != NULL);

            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);

            CFRelease(rls);
        }
    }

    // Now register our service with Bonjour.  See the comments in -netService:didNotPublish:
    // for more info about this simplifying assumption.

    if (success) {
        [self.bonjourManager publish:@"share_screen" transportProtocol:@"tcp" port:port delegate:self];
        success = (self.netService != nil);
    }

    // Clean up after failure.

    if ( success ) {
        assert(port != 0);
    } else {
        if (fd != -1) {
            junk = close(fd);
            assert(junk == 0);
        }
    }
}

- (void)stopServer
{
    [self.bonjourManager reclaim:@"share_screen" transportProtocol:@"tcp"];

    if (_listeningSocket != NULL) {
        CFSocketInvalidate(_listeningSocket);
        CFRelease(_listeningSocket);
        _listeningSocket = NULL;
    }
}

#pragma mark -
#pragma mark VMBonjourPublishDelegate
- (void)published:(NSString *)name {
    NSLog(@"Service Published with Name: %@", name);
}

- (void)registerFailed:(NSError *)error
{
    NSLog(@"Register Failed!");
}

- (void)publishFailed:(NSError *)error {
    NSLog(@"Publish Failed!");
}

- (void)serviceStopped:(NSString *)name {
    NSLog(@"Service Stopped: %@", name);
}

@end
