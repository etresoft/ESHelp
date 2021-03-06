/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>

#import <ESHelp/ESHelpDelegate.h>

@class ESHelpWebView;

// A drop-in replacement for Apple's NSHelpManager.
@interface ESHelpManager : NSObject
  <NSToolbarDelegate,
  NSSharingServiceDelegate,
  NSSharingServicePickerDelegate,
  NSSharingServicePickerTouchBarItemDelegate,
  NSUserInterfaceItemSearching>

@property (strong) IBOutlet NSPanel * window;

// The toolbar.
@property (strong) IBOutlet NSToolbar * toolbar;

// The navigation toolbar item view.
@property (strong) IBOutlet NSView * navigationToolbarItemView;

// The go back button.
@property (strong) IBOutlet NSButton * goBackButton;

// The go forward button.
@property (strong) IBOutlet NSButton * goForwardButton;

// The Home toolbar item view.
@property (strong) IBOutlet NSView * homeToolbarItemView;

// The home button.
@property (strong) IBOutlet NSButton * homeButton;

// The font toolbar item view.
@property (strong) IBOutlet NSView * fontSizeToolbarItemView;

// The font button.
@property (strong) IBOutlet NSPopUpButton * fontSizeButton;

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

// Should I show the share button at all?
@property (assign) BOOL showShareButton;

// Can I share?
@property (readonly) BOOL canShare;

// The web view for display.
@property (strong) IBOutlet ESHelpWebView * webview;

// The base path of all localized help files.
@property (strong) NSString * basePath;

// Extra files that have been added to the help bundle due to a
// non-functional hiutil tool in 10.14+.
@property (strong) NSDictionary * helpIndex;
@property (strong) NSDictionary * helpFiles;

// A little hack for my own needs.
@property (strong) id<ESHelpDelegate> delegate;

// The font size.
@property (assign) int fontSize;

// The preview panel.
@property (strong) NSWindow * previewWindow;

// The preview image.
@property (strong) NSImageView * previewImageView;

// This is a singleton.
+ (ESHelpManager *) sharedHelpManager;

// Display the help index page.
- (void) showHelp;

// Show a specific help anchor.
- (void) showHelpAnchor: (NSString *) anchor;

// UI action to show help.
- (IBAction) showHelp: (id) sender;

// Search for help.
- (void) search: (NSString *) search;

// For ESHelpWebView.
- (void) addURLToHistory: (NSURL *) url;
- (void) openExternalURL: (NSURL *) url;
- (BOOL) isSearchURL: (NSURL *) url;

@end
