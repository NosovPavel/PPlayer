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

#import "PPLibrarySectionListViewController.h"

@class PPLibraryArtistModel;
@class PPLibraryAlbumModel;
@class PPLibraryGenreModel;

@interface PPLibraryAlbumsWithTracksHeaderView : UITableViewHeaderFooterView
@end

@interface PPLibraryAlbumsWithTracksCell : UITableViewCell
@end

@interface PPLibraryAlbumsWithTracksListViewController : PPLibrarySectionListViewController
@property(atomic, strong) PPLibraryArtistModel *artistModel;
@property(atomic, strong) PPLibraryAlbumModel *albumModel;
@property(atomic, strong) PPLibraryGenreModel *genreModel;

- (instancetype)initWithArtistModel:(PPLibraryArtistModel *)artistModel;

- (instancetype)initWithAlbumModel:(PPLibraryAlbumModel *)albumModel;

- (instancetype)initWithGenreModel:(PPLibraryGenreModel *)genreModel;

+ (instancetype)controllerWithGenreModel:(PPLibraryGenreModel *)genreModel;

+ (instancetype)controllerWithAlbumModel:(PPLibraryAlbumModel *)albumModel;

+ (instancetype)controllerWithArtistModel:(PPLibraryArtistModel *)artistModel;

@end