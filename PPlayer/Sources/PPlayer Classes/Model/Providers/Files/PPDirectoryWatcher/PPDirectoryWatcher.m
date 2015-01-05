//
//  Copyright © 2014 Alexander Orlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "PPDirectoryWatcher.h"
#include <sys/event.h>

@interface PPDirectoryWatcher (DirectoryWatcherPrivate)
- (BOOL)startMonitoringDirectory:(NSString *)dirPath;

- (void)kqueueFired;
@end

#pragma mark -

@implementation PPDirectoryWatcher

@synthesize delegate;

- (instancetype)init {
    self = [super init];
    delegate = NULL;

    dirFD = -1;
    kq = -1;
    dirKQRef = NULL;

    return self;
}

- (void)dealloc {
    [self invalidate];
}

+ (PPDirectoryWatcher *)watchFolderWithPath:(NSString *)watchPath delegate:(id)watchDelegate {
    PPDirectoryWatcher *retVal = NULL;
    if ((watchDelegate != NULL) && (watchPath != NULL)) {
        PPDirectoryWatcher *tempManager = [[PPDirectoryWatcher alloc] init];
        tempManager.delegate = watchDelegate;
        if ([tempManager startMonitoringDirectory:watchPath]) {
            // Everything appears to be in order, so return the PPDirectoryWatcher.
            // Otherwise we'll fall through and return NULL.
            retVal = tempManager;
        }
    }
    return retVal;
}

- (void)invalidate {
    if (dirKQRef != NULL) {
        CFFileDescriptorInvalidate(dirKQRef);
        CFRelease(dirKQRef);
        dirKQRef = NULL;
        // We don't need to close the kq, CFFileDescriptorInvalidate closed it instead.
        // Change the value so no one thinks it's still live.
        kq = -1;
    }

    if (dirFD != -1) {
        close(dirFD);
        dirFD = -1;
    }
}

@end

#pragma mark -

@implementation PPDirectoryWatcher (DirectoryWatcherPrivate)

- (void)kqueueFired {
    assert(kq >= 0);

    struct kevent event;
    struct timespec timeout = {0, 0};
    int eventCount;

    eventCount = kevent(kq, NULL, 0, &event, 1, &timeout);
    assert((eventCount >= 0) && (eventCount < 2));

    // call our delegate of the directory change
    [delegate directoryDidChange:self];

    CFFileDescriptorEnableCallBacks(dirKQRef, kCFFileDescriptorReadCallBack);
}

static void KQCallback(CFFileDescriptorRef kqRef, CFOptionFlags callBackTypes, void *info) {
    PPDirectoryWatcher *obj;

    obj = (__bridge PPDirectoryWatcher *) info;
    assert([obj isKindOfClass:[PPDirectoryWatcher class]]);
    assert(kqRef == obj->dirKQRef);
    assert(callBackTypes == kCFFileDescriptorReadCallBack);

    [obj kqueueFired];
}

- (BOOL)startMonitoringDirectory:(NSString *)dirPath {
    // Double initializing is not going to work...
    if ((dirKQRef == NULL) && (dirFD == -1) && (kq == -1)) {
        // Open the directory we're going to watch
        dirFD = open([dirPath fileSystemRepresentation], O_EVTONLY);
        if (dirFD >= 0) {
            // Create a kqueue for our event messages...
            kq = kqueue();
            if (kq >= 0) {
                struct kevent eventToAdd;
                eventToAdd.ident = dirFD;
                eventToAdd.filter = EVFILT_VNODE;
                eventToAdd.flags = EV_ADD | EV_CLEAR;
                eventToAdd.fflags = NOTE_WRITE;
                eventToAdd.data = 0;
                eventToAdd.udata = NULL;

                int errNum = kevent(kq, &eventToAdd, 1, NULL, 0, NULL);
                if (errNum == 0) {
                    CFFileDescriptorContext context = {0, (__bridge void *) (self), NULL, NULL, NULL};
                    CFRunLoopSourceRef rls;

                    // Passing true in the third argument so CFFileDescriptorInvalidate will close kq.
                    dirKQRef = CFFileDescriptorCreate(NULL, kq, true, KQCallback, &context);
                    if (dirKQRef != NULL) {
                        rls = CFFileDescriptorCreateRunLoopSource(NULL, dirKQRef, 0);
                        if (rls != NULL) {
                            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
                            CFRelease(rls);
                            CFFileDescriptorEnableCallBacks(dirKQRef, kCFFileDescriptorReadCallBack);

                            // If everything worked, return early and bypass shutting things down
                            return YES;
                        }
                        // Couldn't create a runloop source, invalidate and release the CFFileDescriptorRef
                        CFFileDescriptorInvalidate(dirKQRef);
                        CFRelease(dirKQRef);
                        dirKQRef = NULL;
                    }
                }
                // kq is active, but something failed, close the handle...
                close(kq);
                kq = -1;
            }
            // file handle is open, but something failed, close the handle...
            close(dirFD);
            dirFD = -1;
        }
    }
    return NO;
}

@end
