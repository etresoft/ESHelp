/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>

@class ESHelpWebView;

@interface ESHelp : NSObject
  <NSToolbarDelegate,
  NSSharingServiceDelegate,
  NSSharingServicePickerDelegate,
  NSSharingServicePickerTouchBarItemDelegate>

@property (strong) IBOutlet NSPanel * window;

// The toolbar.
@property (strong) IBOutlet NSToolbar * toolbar;

// The navigation toolbar item view.
@property (strong) IBOutlet NSView * navigationToolbarItemView;

// The go back button.
@property (strong) IBOutlet NSButton * goBackButton;

// The go forward button.
@property (strong) IBOutlet NSButton * goForwardButton;

// The Share toolbar item view.
@property (strong) IBOutlet NSView * shareToolbarItemView;

// The share button.
@property (strong) IBOutlet NSButton * shareButton;

// The search toolbar item view.
@property (strong) IBOutlet NSView * searchToolbarItemView;

// The search control.
@property (strong) IBOutlet NSSearchField * searchField;

// Search results template.
@property (strong) NSString * searchResultsTemplate;

// Current search text.
@property (strong) NSString * currentSearch;

// Can I go back?
@property (assign) BOOL canGoBack;

// Can I go forward?
@property (assign) BOOL canGoForward;

// The navigation history.
@property (strong) NSMutableArray * history;

// The navigation index in the history.
@property (assign) NSUInteger historyIndex;

// Can I share?
@property (readonly) BOOL canShare;

@property (strong) IBOutlet ESHelpWebView * webview;

@property (strong) NSString * basePath;

@property (strong) NSDictionary * helpIndex;
@property (strong) NSDictionary * helpFiles;

+ (ESHelp *) shared;

- (void) showHelp;

- (void) showHelpAnchor: (NSString *) anchor;

- (IBAction) showHelp: (id) sender;

- (void) search: (NSString *) search;

- (void) addURLToHistory: (NSURL *) url;
- (BOOL) isSearchURL: (NSURL *) url;

@end
