//
//  Copyright © 2015 Alexander Orlov
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

#import "PPProvider.h"
#import "PPFilesProvider.h"

#import "PPLibraryTrackModel.h"

@interface PPLibraryModule : PPProvider
@end

@interface PPLibraryEditor : PPLibraryModule

#pragma mark - Import

- (void)importFiles:(NSArray *)files
  withProgressBlock:(void (^)(float progress))progressBlock
 andCompletionBlock:(void (^)())block;

#pragma mark - Creation

#pragma mark - Editing

#pragma mark - Deleting

@end

@interface PPLibraryFetcher : PPLibraryModule

#pragma mark - Tracks

- (void)tracksListWithCompletionBlock:(void (^)(NSArray *tracksList))block;

#pragma mark - Artists

- (void)artistsListWithCompletionBlock:(void (^)(NSArray *artistsList))block;

#pragma mark - Albums

- (void)albumsListWithCompletionBlock:(void (^)(NSArray *albumsList))block;

#pragma mark - Genres

- (void)genresListWithCompletionBlock:(void (^)(NSArray *genresList))block;

@end

@interface PPLibraryProvider : PPProvider
@property(atomic, strong, readonly) PPLibraryEditor *editor;
@property(atomic, strong, readonly) PPLibraryFetcher *fetcher;

#pragma mark - System

+ (NSURL *)trackURLForID:(int64_t)trackID;

#pragma mark - Singleton

+ (PPLibraryProvider *)sharedLibrary;

@end