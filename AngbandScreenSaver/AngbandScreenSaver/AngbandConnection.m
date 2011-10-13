//
//  AngbandConnection.m
//  AngbandScreenSaver
//
//  Created by Peter Ammon on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AngbandConnection.h"
#import <ScreenSaver/ScreenSaver.h>
#include <sys/mman.h>

#define kBitmapMaxWidth 1920
#define kBitmapMaxHeight 1080

@protocol AngbandRemoteView <NSObject>

- (void)setAngbandContext:(id)context;
- (size_t)angbandSharedBufferSize;
- (int)angbandShmemFile;

- (void)setNeedsDisplayAtNextRefreshInBaseRect:(NSRect)rect withBaseSize:(NSSize)baseSize;
- (void)setNeedsDisplayAtNextRefresh;
- (void)angbandImageRefreshed;

- (void)setPreferences:(NSDictionary *)preferences;

@end

@interface AngbandConnection (PrivateStuff) <AngbandRemoteView>
- (void)launchRemote;
- (void)dispose;
- (void)updateBitmapContext;
@end

/* Messages we can send to the AngbandContext */
@protocol AngbandContext <NSObject>
- (void)angbandViewDidScale:(id)view;
- (oneway void)clientIsShuttingDown;
@end

@implementation AngbandConnection

+ (AngbandConnection *)connection {
    static AngbandConnection *sConnection;
    if (! sConnection) sConnection = [[self alloc] init];
    return sConnection;
}

- (id)init {
    [super init];
    views = [[NSMutableArray alloc] init];
    return self;
}

- (void)setAngbandContext:(id)context {
    if (context != angbandContext) {
        [angbandContext release];
        angbandContext = [context retain];
        [angbandContext setProtocolForProxy:@protocol(AngbandContext)];
    }
}

/* The "active" view is the widest one */
- (NSView *)activeView {
    NSView *widestView = nil;
    CGFloat largestWidth = 0;
    for (NSView *view in views) {
        CGFloat width = [view frame].size.width;
        if (width >= largestWidth) {
            largestWidth = width;
            widestView = view;
        }
    }
    return widestView;
}


- (void)addView:(AngbandScreenSaverView *)view {
    NSParameterAssert(! [views containsObject:view]);
    [views addObject:view];
    if (! connection) {
        /* First view, so launch remote */
        [self launchRemote];
    } else {
        /* We got a new view, so change our size */
        [angbandContext angbandViewDidScale:self];
        [self updateBitmapContext];
    }
}

- (void)removeView:(AngbandScreenSaverView *)view {
    NSParameterAssert([views containsObject:view]);
    [views removeObject:view];
    if (! [views count]) [self dispose];
}

- (NSSize)angbandViewportSize {
    return [[self activeView] bounds].size;
}

- (void)dispose {
    [angbandContext clientIsShuttingDown];
    
    if (sharedBuffer) munmap((void *)sharedBuffer, sharedBufferSize);
    sharedBuffer = NULL;
    CGContextRelease(bitmapContext);
    bitmapContext = NULL;
    if (shmemFD && ! closedFD) {
        close(shmemFD);
        closedFD = YES;
    }
    [[connection sendPort] invalidate];
    [[connection receivePort] invalidate];
    [connection invalidate];
    [connection release];
    connection = nil;
    
    [angbandContext release];
    angbandContext = nil;
    
    rectIndex = 0;
    /* Could clean up childPID here */
    childPID = 0;
}

- (void)dealloc {
    free(rectsToDisplay);
    [self dispose];
    [super dealloc];
}

- (void)finalize {
    [self dispose];
    [super dealloc];
}

- (void)updateBitmapContext {
    if (bitmapContext) CGContextRelease(bitmapContext);
    NSSize boundsSize = [self angbandViewportSize];
    size_t width = fmin(ceil(boundsSize.width), kBitmapMaxWidth);
    size_t height = fmin(ceil(boundsSize.height), kBitmapMaxHeight);    
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    bitmapContext = CGBitmapContextCreate((void *)sharedBuffer, width, height, 8, width * 4, cs, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(cs);
}

- (void)setNeedsDisplayAtNextRefreshInRect:(NSRect)rect {
    if (rectIndex == rectCapacity) {
        /* Add 64 more rects */
        rectCapacity += 64;
        rectsToDisplay = NSReallocateCollectable(rectsToDisplay, rectCapacity * sizeof *rectsToDisplay, 0 /* unscanned, collectable */);
    }
    rectsToDisplay[rectIndex++] = rect;
}

- (oneway void)setNeedsDisplayAtNextRefreshInBaseRect:(NSRect)rect withBaseSize:(NSSize)baseSize {
    /* Transform rect to our coordinate space */
    NSSize ourSize = [self angbandViewportSize];
    
    double dx = ourSize.width / baseSize.width;
    double dy = ourSize.height / baseSize.height;
    
    rect.size.width *= dx;
    rect.origin.x *= dx;
    rect.size.height *= dy;
    rect.origin.y *= dy;
    
    [self setNeedsDisplayAtNextRefreshInRect:rect];
}

- (oneway void)setNeedsDisplayAtNextRefresh {
    [self setNeedsDisplayAtNextRefreshInRect:(NSRect){NSZeroPoint, [self angbandViewportSize]}];
}

- (oneway void)angbandImageRefreshed {
    size_t i = rectIndex;
    while (i--) {
        /* This isn't remotely right except for the active view */
        for (NSView *view in views) {
            [view setNeedsDisplayInRect:rectsToDisplay[i]];
        }
    }
    rectIndex = 0;
}

- (void)drawInRect:(NSRect)bounds {
    if (! bitmapContext) {
        [[NSColor blackColor] set];
        NSRectFill(bounds);
        return;
    };
    CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
    CGContextDrawImage([[NSGraphicsContext currentContext] graphicsPort], NSRectToCGRect(bounds), image);
    CGImageRelease(image);
}

- (void)setPreferences:(NSDictionary *)preferences {
    NSUserDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.ridiculousfish.AngbandScreenSaver"];
    if (angbandContext) {
        [angbandContext setPreferences:preferences];
    } else {
        for (NSString *key in preferences) {
            [defaults setObject:[preferences objectForKey:key] forKey:key];
        }
    }
    [defaults synchronize];
}

- (size_t)angbandSharedBufferSize {
    return sharedBufferSize;
}

- (int)angbandShmemFile {
    return shmemFD;
}

- (void)launchRemote {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Angband" ofType:@"app"];
    if (! path) {
        NSLog(@"Unable to find Angband.app");
        return;
    }
    
    NSBundle *angband = [NSBundle bundleWithPath:path];
    NSString *executable = [angband executablePath];
    const char *executablePath = [executable fileSystemRepresentation];
    if (! executablePath) {
        NSLog(@"Unable to find Angband executable");
        return;
    }
    
    /* Set up connection */
    char connectionName[PATH_MAX];
    snprintf(connectionName, sizeof connectionName, "com.ridiculousfish.AngbandRemote.%ld_%ld", (long)getpid(), (long)time(0));
    NSString *connectionNameObj = [NSString stringWithUTF8String:connectionName];
    connection = [[NSConnection serviceConnectionWithName:connectionNameObj rootObject:self] retain];
    if (! connection) {
        NSLog(@"Failed to service connection with name %@", connectionNameObj);
        return;
    }
    
    /* Size our buffer */
    sharedBufferSize = kBitmapMaxWidth * kBitmapMaxHeight * 4 /* bytesPerComponent */; 
    
    /* Name our shmem */
    char shmemName[PATH_MAX];
    snprintf(shmemName, sizeof shmemName, "/AngbandRemote.%ld", (long)getpid());
    
    /* Make our shared region */
    shmemFD =  shm_open(shmemName, O_CREAT | O_EXCL | O_RDWR, 0600);
    if (shmemFD < 0) {
        perror("shm_open() failed");
        return;
    }
    
    if (ftruncate(shmemFD, sharedBufferSize) < 0) {
        perror("ftruncate() failed");
    }
    
    /* We don't need it any more */
    if (0 > shm_unlink(shmemName)) {
        perror("shm_unlink() failed");
    }
    
    /* Don't close it on exec */
    int oldflags = fcntl(shmemFD, F_GETFD, 0);
    if (oldflags < 0) {
        perror("first fcntl() failed");
        return;
    }
    if (0 > fcntl(shmemFD, F_SETFD, oldflags & ~FD_CLOEXEC)) {
        perror("second fcntl() failed");
        return;
    }
    
    /* Map our buffer */
    sharedBuffer = mmap(0, sharedBufferSize, PROT_READ | PROT_WRITE, MAP_FILE | MAP_SHARED, shmemFD, 0);
    if (sharedBuffer == MAP_FAILED) {
        perror("server mmap() failed");
        return;
    }
    
    [self updateBitmapContext];
    
    pid_t child;
    switch ((child = vfork())) {
        case -1:
            perror("vfork() failed");
            return;
        
        case 0:;
            /* Child process */
            const char * const argv[] = {executablePath, "-remote", connectionName, NULL};
            char ***_NSGetEnviron(void);
            execve(executablePath, (char * const*)argv, *_NSGetEnviron());
            perror("execve() failed");
            return;

        default:
            /* Parent process. Get notified when the child dies so we can reap it. */
            childPID = child;
            dispatch_source_t waiter = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, childPID, DISPATCH_PROC_EXIT, dispatch_get_global_queue(0, 0));
            dispatch_source_set_event_handler(waiter, ^{
                waitpid(child, NULL, 0);
                dispatch_source_cancel(waiter);
                dispatch_release(waiter);
            });
            dispatch_resume(waiter);
            break;

    }
    
    /* Done with this (but keep its value around so child can know it) */
    close(shmemFD);
    closedFD = YES;
}

@end
