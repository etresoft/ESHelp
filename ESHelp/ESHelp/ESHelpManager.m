/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "ESHelpManager.h"
#import "ESHelpWebView.h"

#import <Cocoa/Cocoa.h>

// Toolbar items.
#define kNavigationToolbarItemID @"navigationtoolbaritem"
#define kHomeToolbarItemID @"hometoolbaritem"

// Share is not implemented.
#define kShareToolbarItemID @"sharetoolbaritem"
#define kSearchToolbarItemID @"searchtoolbaritem"

// Singleton.
ESHelpManager * ourHelp = nil;

@implementation ESHelpManager

@synthesize window = myWindow;

@synthesize toolbar = myToolbar;

// The navigation toolbar item view.
@synthesize navigationToolbarItemView = myNavigationToolbarItemView;

// The go back button.
@synthesize goBackButton = myGoBackButton;

// The go forward button.
@synthesize goForwardButton = myGoForwardButton;

// The Share toolbar item view.
@synthesize shareToolbarItemView = myShareToolbarItemView;

// The share button.
@synthesize shareButton = myShareButton;

// The Home toolbar item view.
@synthesize homeToolbarItemView = myHomeToolbarItemView;

// The home button.
@synthesize homeButton = myHomeButton;

// The search toolbar item view.
@synthesize searchToolbarItemView = mySearchToolbarItemView;

// The search control.
@synthesize searchField = mySearchField;

// Search results template.
@synthesize searchResultsTemplate = mySearchResultsTemplate;

// The current search.
@synthesize currentSearch = myCurrentSearch;

// Can I go back?
@synthesize canGoBack = myCanGoBack;

// Can I go forward?
@synthesize canGoForward = myCanGoForward;

// The navigation history.
@synthesize history = myHistory;

// The navigation index in the history.
@synthesize historyIndex = myHistoryIndex;

// Should I show the share button at all?
@synthesize showShareButton = myShowShareButton;

// Can I share?
@dynamic canShare;

// The web view for display.
@synthesize webview = myWebView;

// The base path of all localized help files.
@synthesize basePath = myBasePath;

// Extra files that have been added to the help bundle due to a
// non-functional hiutil tool in 10.14+.
@synthesize helpIndex = myHelpIndex;
@synthesize helpFiles = myHelpFiles;

// A little hack for my own needs.
@synthesize delegate = myDelegate;

// Update canShare when history index changes.
+ (NSSet *) keyPathsForValuesAffectingCanShare
  {
  return [NSSet setWithObject: @"historyIndex"];
  }

// Enable the share button.
- (BOOL) canShare
  {
  if(self.historyIndex < 1)
    return NO;
    
  NSURL * url = [self.history objectAtIndex: self.historyIndex - 1];

  return ![self isSearchURL: url];
  }

// Return the singleton.
+ (ESHelpManager *) sharedHelpManager
  {
  return ourHelp;
  }

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    ourHelp = self;
    
    // Connect this class to the help menu search functionality.
    [[NSApplication sharedApplication]
      registerUserInterfaceItemSearchHandler: ourHelp];
      
    // Get the localized path to the help bundle.
    NSString * helpPath =
      [[NSBundle mainBundle]
        objectForInfoDictionaryKey: @"CFBundleHelpBookFolder"];
      
    NSString * helpBundlePath =
      [[NSBundle mainBundle] pathForResource: helpPath ofType: nil];

    NSString * helpBasePath =
      [helpBundlePath
        stringByAppendingPathComponent: @"Contents/Resources"];
      
    NSString * localizedHelpBasePath =
      [helpBasePath
        stringByAppendingPathComponent:
          NSLocalizedStringFromTableInBundle(
            @"en.lproj",
            @"Localizable",
            [NSBundle bundleForClass: [ESHelpManager class]],
            NULL)];
      
    self.basePath = localizedHelpBasePath;
    
    // I have to maintain my own history.
    myHistory = [NSMutableArray new];
    myHistoryIndex = 0;
    
    // Read additional data from the help bundle.
    [self readAnchorIndex];
    [self readFileIndex];
    }
    
  return self;
  }

// Read the help anchor index. The help anchor index must be generated with
// a 10.13 version of hiutil. The 10.14+ version no longer works.
- (void) readAnchorIndex
  {
  NSString * anchorIndexKey =
    [self helpBundleDictionaryValue: @"ESHelpHelpIndex"];
  
  NSString * helpIndexPath =
    [self.basePath stringByAppendingPathComponent: anchorIndexKey];
    
  NSData * data = [[NSData alloc] initWithContentsOfFile: helpIndexPath];

  NSDictionary * helpIndex = nil;
  
  if(data.length > 0)
    {
    NSError * error;
    NSPropertyListFormat format;
    
    helpIndex =
      [NSPropertyListSerialization
        propertyListWithData: data
        options: NSPropertyListImmutable
        format: & format
        error: & error];
    }
  
  self.helpIndex = helpIndex;

#if !__has_feature(objc_arc)
  [data release];
#endif
  }

// Extract a dictionary value from the help bundle.
- (id) helpBundleDictionaryValue: (NSString *) key
  {
  NSString * helpPath =
    [[NSBundle mainBundle]
      objectForInfoDictionaryKey: @"CFBundleHelpBookFolder"];
  
  NSString * helpBundlePath =
    [[NSBundle mainBundle] pathForResource: helpPath ofType: nil];

  NSBundle * helpBundle = [NSBundle bundleWithPath: helpBundlePath];
  
  return [helpBundle objectForInfoDictionaryKey: key];
  }

// Read the help file index. The help file index must be generated with
// a 10.13 version of hiutil. The 10.14+ version no longer works.
- (void) readFileIndex
  {
  NSString * fileIndexKey =
    [self helpBundleDictionaryValue: @"ESHelpHelpFiles"];
  
  NSString * helpFilesPath =
    [self.basePath stringByAppendingPathComponent: fileIndexKey];

  // Alas, the help file index is just text.
  NSString * text =
    [[NSString alloc]
      initWithContentsOfFile: helpFilesPath
      encoding: NSUTF8StringEncoding
      error: NULL];

  NSArray * lines = [text componentsSeparatedByString: @"\n"];
  
#if !__has_feature(objc_arc)
  [text release];
#endif

  NSMutableDictionary * helpFiles = [NSMutableDictionary new];
  
  NSString * foundPath = nil;
  NSString * title = nil;
  NSString * description = nil;
  
  for(NSString * line in lines)
    // Process what we have so far.
    if((line.length == 0) && (foundPath != nil))
      {
      NSString * searchText = [self readSearchText: foundPath];
      
      if((searchText != nil) && (title != nil) && (description != nil))
        {
        NSURL * url = [NSURL fileURLWithPath: foundPath];
        
        NSDictionary * dict =
          [[NSDictionary alloc]
            initWithObjectsAndKeys:
              foundPath, @"path",
              url, @"url",
              title, @"title",
              description, @"description",
              searchText, @"text",
              nil];
          
        [helpFiles setObject: dict forKey: foundPath];

#if !__has_feature(objc_arc)
        [dict release];
#endif
        }
        
      foundPath = nil;
      title = nil;
      description = nil;
      }
    else
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];
      
      if([trimmedLine hasPrefix: @"Title: "])
        title = [trimmedLine substringFromIndex: 7];
      else if([trimmedLine hasPrefix: @"Descr: "])
        description = [trimmedLine substringFromIndex: 7];
      else
        {
        NSArray * parts = [line componentsSeparatedByString: @"#"];
        
        NSString * path = parts.firstObject;
        
        NSString * filePath =
          [self.basePath stringByAppendingPathComponent: path];
          
        BOOL exists = NO;
        BOOL isDirectory = NO;
        
        exists =
          [[NSFileManager defaultManager]
            fileExistsAtPath: filePath isDirectory: & isDirectory];
          
        if(exists && !isDirectory)
          foundPath = filePath;
        }
      }
  
  self.helpFiles = helpFiles;

#if !__has_feature(objc_arc)
  [helpFiles release];
#endif
  }

// Read the content of a help bundle html file.
- (NSString *) readSearchText: (NSString *) path
  {
  NSData * data = [[NSData alloc] initWithContentsOfFile: path];

  NSURL * baseURL =
    [NSURL fileURLWithPath: [path stringByDeletingLastPathComponent]];
  
  // We don't want to just read in the text. Read in the HTML, then convert
  // it to an attributed string and then get the plain text from that.
  // Otherwise, we would match on HTML tags.
  NSAttributedString * attributedString =
    [[NSAttributedString alloc]
      initWithHTML: data baseURL: baseURL documentAttributes: NULL];

  NSString * text = [attributedString.string copy];
  
#if !__has_feature(objc_arc)
  [text autorelease];
  [attributedString release];
  [data release];
#endif

  return text;
  }

// Destructor.
- (void) dealloc
  {
  self.window = nil;
  self.toolbar = nil;
  self.navigationToolbarItemView = nil;
  self.goBackButton = nil;
  self.goForwardButton = nil;
  self.history = nil;
  self.homeToolbarItemView = nil;
  self.homeButton = nil;
  self.shareToolbarItemView = nil;
  self.shareButton = nil;
  self.searchToolbarItemView = nil;
  self.searchField = nil;
  self.searchResultsTemplate = nil;
  self.currentSearch = nil;
  self.webview = nil;
  self.basePath = nil;
  self.helpIndex = nil;
  self.helpFiles = nil;
  self.delegate = nil;
  
#if !__has_feature(objc_arc)
  [super dealloc];
#endif
  }

// Display the help index file.
- (void) showHelp
  {
  [self setup];
  
  [self showHelpFile: @"index.html"];
  }

// Setup the help system.
- (void) setup
  {
  // Only do this once.
  if(self.window != nil)
    return;
    
  // Try to mimic the default help beahviour.
  NSScreen * screen = [NSScreen mainScreen];
  NSRect visibleFrame = screen.visibleFrame;
  NSSize size = NSMakeSize(780/2, 1140/2);
  
  if(size.width > visibleFrame.size.width)
    size.width = visibleFrame.size.width;
    
  if(size.height > visibleFrame.size.height)
    size.height = visibleFrame.size.height;

  NSRect frame =
    NSMakeRect(
      visibleFrame.origin.x + (visibleFrame.size.width - size.width),
      visibleFrame.origin.y,
      size.width,
      size.height);
  
  NSUInteger styleMask =
    NSTitledWindowMask
      | NSResizableWindowMask
      | NSClosableWindowMask
      | NSMiniaturizableWindowMask
      | NSWindowStyleMaskUtilityWindow;
  
  NSRect rect =
    [NSWindow contentRectForFrameRect: frame styleMask: styleMask];
  
  myWindow =
    [[NSPanel alloc]
      initWithContentRect: rect
      styleMask: styleMask
      backing: NSBackingStoreBuffered
      defer: false];
    
  self.window.hidesOnDeactivate = NO;
  self.window.contentMinSize = size;
  
  // Create the web view.
  myWebView = [[ESHelpWebView alloc] initWithFrame: frame];
  
  // Create the toolbar.
  myToolbar =
    [[NSToolbar alloc] initWithIdentifier: @"eshelptoolbar"];
    
  self.toolbar.delegate = self;
  self.toolbar.allowsUserCustomization = NO;
  self.toolbar.autosavesConfiguration = NO;
  self.toolbar.displayMode = NSToolbarDisplayModeIconOnly;
  self.toolbar.sizeMode = NSToolbarSizeModeSmall;
  
  self.window.toolbar = self.toolbar;
  
  self.webview.autoresizingMask =
    NSViewMinXMargin
      | NSViewWidthSizable
      | NSViewMaxXMargin
      | NSViewMinYMargin
      | NSViewHeightSizable
      | NSViewMaxYMargin;
    
  self.webview.translatesAutoresizingMaskIntoConstraints = NO;
  
  self.webview.delegate = self;
  
  __weak ESHelpManager * weakSelf = self;

  // Connect a web callback for opening a result from a search.
  [self.webview
    addScriptHandler:
      ^NSString * (NSObject * object)
        {
        [weakSelf performWebSearch];
          
        return @"OK";
        }
    forKey: @"help"];

  [self.window setContentView: self.webview];
  
  // Connect window autosave.
  NSString * helpName =
    [[NSBundle mainBundle]
      objectForInfoDictionaryKey: @"CFBundleHelpBookName"];

  NSString * autosaveName =
    [[NSString alloc] initWithFormat: @"%@ Help Window", helpName];
  
  [self.window setFrameAutosaveName: autosaveName];

#if !__has_feature(objc_arc)
  [autosaveName release];
#endif
  }

// Show the help at a given anchor point.
- (void) showHelpAnchor: (NSString *) anchor
  {
  [self setup];

  if(anchor.length > 0)
    {
    NSArray * paths = [self.helpIndex objectForKey: anchor];
    
    NSString * path = paths.firstObject;
    
    if(path.length > 0)
      {
      NSString * filePath =
        [self.basePath stringByAppendingPathComponent: path];
     
      NSURL * url = [[NSURL alloc] initFileURLWithPath: filePath];
      
      NSURL * anchorURL =
        [[NSURL alloc]
          initWithString:
            [url.absoluteString stringByAppendingFormat: @"#%@", anchor]];

      [self.window makeKeyAndOrderFront: self];

      [self showHelpURL: anchorURL];

#if !__has_feature(objc_arc)
      [url release];
      [anchorURL release];
#endif
      
      return;
      }
    }
  
  [self showHelp];
  }

// Show a help file.
- (void) showHelpFile: (NSString *) fileName
  {
  NSString * filePath =
    [self.basePath stringByAppendingPathComponent: fileName];

  NSURL * url = [[NSURL alloc] initFileURLWithPath: filePath];
  
  [self.window makeKeyAndOrderFront: self];

  [self showHelpURL: url];

#if !__has_feature(objc_arc)
  [url release];
#endif
  }

// Show a help URL.
- (void) showHelpURL: (NSURL *) url
  {
  __weak ESHelpManager * weakSelf = self;
  
  self.webview.readyHandler =
    ^{
      weakSelf.canGoBack = (weakSelf.historyIndex > 1);
      
      weakSelf.canGoForward =
        (weakSelf.historyIndex < weakSelf.history.count);
    };

  [self.webview loadURL: url];
  }

#pragma mark - NSToolbarDelegate conformance

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  willBeInsertedIntoToolbar: (BOOL) flag
  {
  if([itemIdentifier isEqualToString: kNavigationToolbarItemID])
    return
      [self
        createNavigationToolbar: toolbar
        itemForItemIdentifier: itemIdentifier];
    
  else if([itemIdentifier isEqualToString: kHomeToolbarItemID])
    return
      [self
        createHomeToolbar: toolbar
        itemForItemIdentifier: itemIdentifier];

  else if([itemIdentifier isEqualToString: kShareToolbarItemID])
    return
      [self
        createShareToolbar: toolbar itemForItemIdentifier: itemIdentifier];
    
  else if([itemIdentifier isEqualToString: kSearchToolbarItemID])
    return
      [self
        createSearchToolbar: toolbar itemForItemIdentifier: itemIdentifier];

  return nil;
  }

// Setup all these toolbars from scratch, with no nib required.
- (NSToolbarItem *) createNavigationToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  myNavigationToolbarItemView =
    [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 54, 25)];
  
  myGoBackButton =
    [[NSButton alloc] initWithFrame: NSMakeRect(0, -2, 27, 27)];
  
  self.goBackButton.bezelStyle = NSBezelStyleTexturedRounded;
  self.goBackButton.image = [NSImage imageNamed: NSImageNameGoLeftTemplate];
  self.goBackButton.target = self;
  self.goBackButton.action = @selector(goBack:);
  [self.goBackButton
    bind: @"enabled" toObject: self withKeyPath: @"canGoBack" options: nil];
  
  myGoForwardButton =
    [[NSButton alloc] initWithFrame: NSMakeRect(26, -2, 27, 27)];

  self.goForwardButton.bezelStyle = NSBezelStyleTexturedRounded;

  self.goForwardButton.image =
    [NSImage imageNamed: NSImageNameGoRightTemplate];

  self.goForwardButton.target = self;
  self.goForwardButton.action = @selector(goForward:);
  [self.goForwardButton
    bind: @"enabled"
    toObject: self
    withKeyPath: @"canGoForward"
    options: nil];

  [self.navigationToolbarItemView addSubview: self.goBackButton];
  [self.navigationToolbarItemView addSubview: self.goForwardButton];
  
  // Create the NSToolbarItem and setup its attributes.
  NSToolbarItem * item =
    [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  
  [item
    setLabel:
      NSLocalizedStringFromTableInBundle(
      @"Back/Forward",
      @"Localizable",
      [NSBundle bundleForClass: [ESHelpManager class]],
      NULL)];

  [item
    setPaletteLabel:
      NSLocalizedStringFromTableInBundle(
      @"Back/Forward",
      @"Localizable",
      [NSBundle bundleForClass: [ESHelpManager class]],
      NULL)];

  [item setView: self.navigationToolbarItemView];
    
  [item setTarget: self];
  [item setAction: nil];
  
#if !__has_feature(objc_arc)
  [item autorelease];
#endif

  return item;
  }

// Home button to display help index.
- (NSToolbarItem *) createHomeToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  myHomeToolbarItemView =
    [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 39, 25)];
  
  myHomeButton =
    [[NSButton alloc] initWithFrame: NSMakeRect(0, -2, 39, 27)];
  
  self.homeButton.bezelStyle = NSBezelStyleTexturedRounded;
  self.homeButton.image = [NSImage imageNamed: NSImageNameHomeTemplate];
  self.homeButton.target = self;
  self.homeButton.action = @selector(goHome:);

  // It seems the only way to control the size of buttons in a toolbar
  // is to have more than one. Odd.
  NSButton * dummy =
    [[NSButton alloc] initWithFrame: NSMakeRect(38, -2, 27, 27)];

  dummy.bezelStyle = NSBezelStyleRegularSquare;

  [self.homeToolbarItemView addSubview: self.homeButton];
  [self.homeToolbarItemView addSubview: dummy];

  // Create the NSToolbarItem and setup its attributes.
  NSToolbarItem * item =
    [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  
  [item
    setLabel:
      NSLocalizedStringFromTableInBundle(
      @"Home",
      @"Localizable",
      [NSBundle bundleForClass: [ESHelpManager class]],
      NULL)];

  [item
    setPaletteLabel:
      NSLocalizedStringFromTableInBundle(
      @"Home",
      @"Localizable",
      [NSBundle bundleForClass: [ESHelpManager class]],
      NULL)];

  [item setView: self.homeToolbarItemView];
    
  [item setTarget: self];
  [item setAction: nil];

#if !__has_feature(objc_arc)
  [item autorelease];
  [dummy release];
#endif

  return item;
  }

// Sharing is not yet supported.
- (NSToolbarItem *) createShareToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  // Create the NSToolbarItem and setup its attributes.
  NSToolbarItem * item =
    [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  
  [item
    setLabel:
      NSLocalizedStringFromTableInBundle(
      @"Share page",
      @"Localizable",
      [NSBundle bundleForClass: [ESHelpManager class]],
      NULL)];

  [item
    setPaletteLabel:
      NSLocalizedStringFromTableInBundle(
      @"Share page",
      @"Localizable",
      [NSBundle bundleForClass: [ESHelpManager class]],
      NULL)];

  myShareToolbarItemView =
    [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 39, 25)];
  
  myShareButton =
    [[NSButton alloc] initWithFrame: NSMakeRect(0, -2, 39, 27)];
  
  self.shareButton.bezelStyle = NSBezelStyleTexturedRounded;
  self.shareButton.image = [NSImage imageNamed: NSImageNameShareTemplate];
  self.shareButton.target = self;
  self.shareButton.action = @selector(shareHelp:);
  [self.shareButton
    bind: @"enabled" toObject: self withKeyPath: @"canShare" options: nil];

  // It seems the only way to control the size of buttons in a toolbar
  // is to have more than one. Odd.
  NSButton * dummy =
    [[NSButton alloc] initWithFrame: NSMakeRect(38, -2, 27, 27)];

  dummy.bezelStyle = NSBezelStyleRegularSquare;

  [self.shareToolbarItemView addSubview: self.shareButton];
  [self.shareToolbarItemView addSubview: dummy];

  [item setView: self.shareToolbarItemView];
    
  [item setTarget: self];
  [item setAction: nil];
  [self.shareButton sendActionOn: NSLeftMouseDownMask];

#if !__has_feature(objc_arc)
  [item autorelease];
#endif

  return item;
  }

// Allow searching.
- (NSToolbarItem *) createSearchToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  mySearchToolbarItemView =
    [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 206, 25)];

  mySearchField =
    [[NSSearchField alloc] initWithFrame: NSMakeRect(1, 2, 205, 22)];
  
  [self.searchToolbarItemView addSubview: self.searchField];
  
  // Create the NSToolbarItem and setup its attributes.
  NSToolbarItem * item =
    [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  
  [item
    setLabel:
      NSLocalizedStringFromTableInBundle(
        @"Search",
        @"Localizable",
        [NSBundle bundleForClass: [ESHelpManager class]],
        NULL)];

  [item
    setPaletteLabel:
      NSLocalizedStringFromTableInBundle(
        @"Search",
        @"Localizable",
        [NSBundle bundleForClass: [ESHelpManager class]],
        NULL)];

  [item setView: self.searchToolbarItemView];
  
  NSRect frame = self.searchField.frame;
  
  frame.origin.y = 0;
  frame.size.height = 25;
  self.searchField.frame = frame;
  self.searchField.font = [NSFont systemFontOfSize: 13.0];
  
  SEL setSendsWholeSearchString = @selector(setSendsWholeSearchString:);
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  if([self.searchField respondsToSelector: setSendsWholeSearchString])
    [self.searchField
      performSelector: setSendsWholeSearchString withObject: @YES];
#pragma clang diagnostic pop

  [item setTarget: self];
  [item setAction: nil];
  
  self.searchField.target = self;
  self.searchField.action = @selector(performSearch:);
  
#if !__has_feature(objc_arc)
  [item autorelease];
#endif

  return item;
  }

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
  {
  NSMutableArray * items = [NSMutableArray array];
  
  [items addObject: kNavigationToolbarItemID];
  [items addObject: kHomeToolbarItemID];
  
  if(self.showShareButton)
    [items addObject: kShareToolbarItemID];
  
  [items addObject: NSToolbarFlexibleSpaceItemIdentifier];
  [items addObject: kSearchToolbarItemID];
  
  return items;
  }

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
  {
  NSMutableArray * items = [NSMutableArray array];
  
  [items addObject: kNavigationToolbarItemID];
  [items addObject: kHomeToolbarItemID];
  
  if(self.showShareButton)
    [items addObject: kShareToolbarItemID];
  
  [items addObject: NSToolbarFlexibleSpaceItemIdentifier];
  [items addObject: kSearchToolbarItemID];
  
  return items;

  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "allowed" list of items.
  }

#pragma mark - Navigation

// Go back.
- (IBAction) goBack: (id) sender
  {
  NSURL * url = [self.history objectAtIndex: self.historyIndex - 2];
    
  [self showHelpURL: url];
  }

// Go forward.
- (IBAction) goForward: (id) sender
  {
  NSURL * url = [self.history objectAtIndex: self.historyIndex];
    
  [self showHelpURL: url];
  }

// Go home.
- (IBAction) goHome: (id) sender
  {
  ESHelpManager * helpManager = [ESHelpManager sharedHelpManager];
  
  [helpManager showHelp];
  }

// Share help.
- (IBAction) shareHelp: (id) sender
  {
  NSURL * url = [self.history objectAtIndex: self.historyIndex - 1];

  NSSharingServicePicker * sharingServicePicker =
    [[NSSharingServicePicker alloc]
      initWithItems: [NSArray arrayWithObjects: url, nil]];
 
  sharingServicePicker.delegate = self;
 
  [sharingServicePicker
    showRelativeToRect: NSZeroRect
    ofView: sender
    preferredEdge: NSMinYEdge];
 
  //[sharingServicePicker release];
  }

#pragma mark - Searching

// Peform a search from the UI.
- (IBAction) performSearch: (id) sender
  {
  NSSearchField * searchField = sender;

  self.currentSearch = searchField.stringValue;
  
  // Construct a URL that can be saved to history and use that.
  NSString * searchString =
    [NSString stringWithFormat: @"search-%@", self.currentSearch];
  
  NSString * filePath =
    [self.basePath stringByAppendingPathComponent: searchString];
  
  NSURL * url = [[NSURL alloc] initFileURLWithPath: filePath];
  
  [self showHelpURL: url];

#if !__has_feature(objc_arc)
  [url release];
#endif
  }

// Perform a search.
- (void) search: (NSString *) searchString
  {
  NSArray * matches = [self findMatches: searchString];
    
  [self showMatches: matches];
  }

// Find matches for a search string.
- (NSArray *) findMatches: (NSString *) searchString
  {
  NSMutableArray * matches = [NSMutableArray array];
  
  if(searchString.length > 0)
    {
    for(NSString * path in self.helpFiles)
      {
      NSDictionary * match = self.helpFiles[path];
      
      NSString * text = match[@"text"];
      
      NSRange range =
        [text
          rangeOfString: searchString
          options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
      
      if(range.location != NSNotFound)
        [matches addObject: match];
      }
    }
    
  return matches;
  }

// Add a URL to the history.
- (void) addURLToHistory: (NSURL *) url
  {
  BOOL isDirectory = NO;
  
  BOOL exists =
    [[NSFileManager defaultManager]
      fileExistsAtPath: url.path isDirectory: & isDirectory];
  
  if(exists && isDirectory)
    return;
    
  NSURL * previousURL = nil;
  NSURL * nextURL = nil;

  if(self.historyIndex > 1)
    previousURL = [self.history objectAtIndex: self.historyIndex - 2];
    
  if(self.historyIndex < self.history.count)
    nextURL = [self.history objectAtIndex: self.historyIndex];

  if([previousURL isEqualTo: url])
    self.historyIndex = self.historyIndex - 1;
  else if([nextURL isEqualTo: url])
    self.historyIndex = self.historyIndex + 1;
  else
    {
    [self.history
      removeObjectsInRange:
        NSMakeRange(
          self.historyIndex, self.history.count - self.historyIndex)];
      
    [self.history addObject: url];
    self.historyIndex = self.historyIndex + 1;
    }

  self.canGoBack = (self.historyIndex > 1);
  self.canGoForward = (self.historyIndex < self.history.count);
  }

// Open an external URL, and maybe do something fancy.
- (void) openExternalURL: (NSURL *) url;
  {
  if([self.delegate respondsToSelector: @selector(openExternalURL:)])
    [self.delegate openExternalURL: url];
  else
    [[NSWorkspace sharedWorkspace] openURL: url];
  }

// Hijack a search URL and perform a search.
- (BOOL) isSearchURL: (NSURL *) url
  {
  if(self.basePath != nil)
    if([url.path hasPrefix: self.basePath])
      {
      NSString * file = [url.path lastPathComponent];
      
      if([file hasPrefix: @"search-"])
        {
        self.currentSearch = [file substringFromIndex: 7];
        
        self.searchField.stringValue = self.currentSearch;
        
        [self search: self.currentSearch];

        return YES;
        }
      }
    
  return NO;
  }

// Show matches for a search.
- (void) showMatches: (NSArray *) results
  {
  // Load the result template.
  if(self.searchResultsTemplate == nil)
    [self loadSearchResultsTemplate];
    
  NSString * iconPath = [self loadSearchResultsIconPath];
  
  NSMutableString * ul = [NSMutableString new];
  
  [ul appendString: @"<ul class=\"searchresults\">\n"];
  
  int index = 0;
  int maxSearchResults = 6;
  
  for(NSDictionary * result in results)
    {
    [ul
      appendFormat:
        @"<li%@>\n",
        index >= maxSearchResults
          ? @" class=\"more\""
          : @""];
      
    [ul appendFormat: @"<a href=\"%@\">", result[@"url"]];
    
    [ul
      appendFormat:
        @"<img src=\"%@\" alt=\"Icon\" class=\"applogo\">", iconPath];
      
    [ul appendString: @"<div><p>"];
    [ul appendFormat: @"<strong>%@</strong>", result[@"title"]];
    [ul appendString: @"</p><p>"];
    [ul appendFormat: @"%@", result[@"description"]];
    [ul appendString: @"</p></div>"];

    [ul appendString: @"</a>"];
    [ul appendString: @"</li>"];
    
    ++index;
    }
    
  [ul appendString: @"</ul>"];
  
  NSString * helpBookTitle =
    [self helpBundleDictionaryValue: @"HPDBookTitle"];
    
  // Hack up the human-readable result count.
  NSString * resultsUnits =
      NSLocalizedStringFromTableInBundle(
        @"results",
        @"Localizable",
        [NSBundle bundleForClass: [ESHelpManager class]],
        NULL);

  if(results.count == 1)
    resultsUnits =
      NSLocalizedStringFromTableInBundle(
        @"result",
        @"Localizable",
        [NSBundle bundleForClass: [ESHelpManager class]],
        NULL);

  NSString * resultsCountString =
    [NSString stringWithFormat: @"%lu", (unsigned long)results.count];
  
  NSString * resultsCount =
    [NSString stringWithFormat: @"%@ %@", resultsCountString, resultsUnits];
    
  if(results.count == 0)
    resultsCount =
      NSLocalizedStringFromTableInBundle(
        @"no results",
        @"Localizable",
        [NSBundle bundleForClass: [ESHelpManager class]],
        NULL);

  NSString * header =
    [[NSString alloc]
      initWithFormat:
        @"<h2>%@<span class=\"resultcount\">(%@)</span></h2>",
        helpBookTitle,
        resultsCount];
    
  NSString * searchResultHeader =
    [[NSString alloc]
      initWithFormat:
        @"<div class=\"searchresultsheader\">%@</div>", header];
    
  NSString * linkTemplate =
    @"<p id=\"%@\" onclick=\"%@\">%@<span>%@</span></p>%@";

  // Avoid a crash on Mavericks.
  NSString * showAllIcon = @"";
  NSString * searchWebIcon = @"";
  
  SEL setSendsWholeSearchString = @selector(setSendsWholeSearchString:);
  
  if([self.searchField respondsToSelector: setSendsWholeSearchString])
    {
    showAllIcon =
      NSLocalizedStringFromTableInBundle(
        @"showallicon",
        @"Localizable",
        [NSBundle bundleForClass: [ESHelpManager class]],
        NULL);

    searchWebIcon =
      NSLocalizedStringFromTableInBundle(
        @"searchwebicon",
        @"Localizable",
        [NSBundle bundleForClass: [ESHelpManager class]],
        NULL);
    }
    
  NSString * showAll = @"";
  
  if(results.count > maxSearchResults)
    showAll =
      [[NSString alloc]
        initWithFormat:
          linkTemplate,
          @"showalllink",
          @"showall()",
          NSLocalizedStringFromTableInBundle(
            @"Show all",
            @"Localizable",
            [NSBundle bundleForClass: [ESHelpManager class]],
            NULL),
          showAllIcon,
          @"<hr class=\"searchresults\">"];

  NSString * searchWeb =
    [[NSString alloc]
      initWithFormat:
        linkTemplate,
        @"searchweblink",
        @"searchweb()",
        NSLocalizedStringFromTableInBundle(
          @"Search the web for more results",
          @"Localizable",
          [NSBundle bundleForClass: [ESHelpManager class]],
          NULL),
        searchWebIcon,
        @""];

  NSMutableString * searchResults =
    [self.searchResultsTemplate mutableCopy];
  
  [searchResults
    replaceOccurrencesOfString:
      @"<searchresultsheader></searchresultsheader>"
    withString: searchResultHeader
    options: 0
    range: NSMakeRange(0, searchResults.length)];

  [searchResults
    replaceOccurrencesOfString: @"<searchresults></searchresults>"
    withString: ul
    options: 0
    range: NSMakeRange(0, searchResults.length)];
  
  [searchResults
    replaceOccurrencesOfString: @"<showall></showall>"
    withString: showAll
    options: 0
    range: NSMakeRange(0, searchResults.length)];

  [searchResults
    replaceOccurrencesOfString: @"<searchweb></searchweb>"
    withString: searchWeb
    options: 0
    range: NSMakeRange(0, searchResults.length)];

  NSString * searchResultsKey =
    [self helpBundleDictionaryValue: @"ESHelpSearchResults"];
  
  NSString * searchResultsPath =
    [self.basePath stringByAppendingPathComponent: searchResultsKey];

  NSURL * baseURL =
    [NSURL
      fileURLWithPath:
        [searchResultsPath stringByDeletingLastPathComponent]];
  
  [self.webview loadHTML: searchResults baseURL: baseURL];
  
#if !__has_feature(objc_arc)
  [searchResults release];
  [ul release];
  [header release];
  [searchResultHeader release];
  [showAll release];
  [searchWeb release];
#endif
  }

// Load the search results template from the help bundle.
- (void) loadSearchResultsTemplate
  {
  NSString * searchResultsKey =
    [self helpBundleDictionaryValue: @"ESHelpSearchResults"];
  
  NSString * searchResultsPath =
    [self.basePath stringByAppendingPathComponent: searchResultsKey];

  mySearchResultsTemplate =
    [[NSString alloc]
      initWithContentsOfFile: searchResultsPath
      encoding: NSUTF8StringEncoding
      error: NULL];
  }

// The app icon path is defined in the help bundle info.plist file. Extract
// it for the search results page.
- (NSString *) loadSearchResultsIconPath
  {
  NSString * helpPath =
    [[NSBundle mainBundle]
      objectForInfoDictionaryKey: @"CFBundleHelpBookFolder"];
  
  NSString * helpBundlePath =
    [[NSBundle mainBundle] pathForResource: helpPath ofType: nil];

  NSBundle * helpBundle = [NSBundle bundleWithPath: helpBundlePath];
  
  NSString * appIconPath =
    [helpBundle objectForInfoDictionaryKey: @"HPDBookIconPath"];
    
  return [@"../.." stringByAppendingPathComponent: appIconPath];
  }

// Perform an external search. This uses the "Search With" service in
// Safari. Sorry, not other browsers supported. There is no API for this.
- (void) performWebSearch
  {
  NSString * appName =
    [[NSBundle mainBundle]
      objectForInfoDictionaryKey: @"CFBundleName"];

  NSPasteboard * pboard = [NSPasteboard pasteboardWithUniqueName];

  NSString * restrictedQuery =
    [[NSString alloc]
      initWithFormat: @"\"%@\" %@ mac", self.currentSearch, appName];

  [pboard
    declareTypes: [NSArray arrayWithObject: NSPasteboardTypeString]
    owner: nil];

  [pboard setString: restrictedQuery forType: NSPasteboardTypeString];

#if !__has_feature(objc_arc)
  [restrictedQuery release];
#endif

  // Just try them all until one works.
  if([self performSearch: @"Google" pasteboard: pboard])
    return;

  if([self performSearch: @"DuckDuckGo" pasteboard: pboard])
    return;

  if([self performSearch: @"Bing" pasteboard: pboard])
    return;

  if([self performSearch: @"Yahoo" pasteboard: pboard])
    return;
  }

// Perform a search using a given engine.
- (BOOL) performSearch: (NSString *) engine
  pasteboard: (NSPasteboard *) pboard
  {
  NSString * serviceName =
    [[NSString alloc]
      initWithFormat:
        @"%@ %@",
        NSLocalizedStringFromTableInBundle(
          @"Search With",
          @"Localizable",
          [NSBundle bundleForClass: [ESHelpManager class]],
          NULL),
        engine];
    
  BOOL result = NSPerformService(serviceName, pboard);
  
#if !__has_feature(objc_arc)
  [serviceName release];
#endif

  if(!result)
    {
    serviceName =
      [[NSString alloc] initWithFormat: @"%@ %@", @"Search With", engine];
      
    result = NSPerformService(serviceName, pboard);
  
#if !__has_feature(objc_arc)
    [serviceName release];
#endif
    }
    
  return result;
  }

#pragma mark - NSUserInterfaceItemSearching

- (NSArray<NSString *> *) localizedTitlesForItem: (id) item
  {
  return @[item[@"title"]];
  }

- (void) searchForItemsWithSearchString: (NSString *) searchString
  resultLimit: (NSInteger) resultLimit
  matchedItemHandler: (void (^)(NSArray * items)) handleMatchedItems
  {
  NSArray * matches = [self findMatches: searchString];
  
  if(handleMatchedItems != nil)
    handleMatchedItems(matches);
  }

- (void) performActionForItem: (id) item
  {
  [self setup];

  [self.window makeKeyAndOrderFront: self];

  [self showHelpURL: item[@"url"]];
  }

#pragma mark - NSSharingServicePickerDelegate conformance

- (id <NSSharingServiceDelegate>)
  sharingServicePicker: (NSSharingServicePicker *) sharingServicePicker
  delegateForSharingService: (NSSharingService *) sharingService
  {
  return self;
  }

- (void) sharingServicePicker:
  (NSSharingServicePicker *) sharingServicePicker
  didChooseSharingService: (NSSharingService *) service
  {
  [service setDelegate: self];
  }

- (NSArray *)
  sharingServicePicker: (NSSharingServicePicker *) sharingServicePicker
  sharingServicesForItems: (NSArray *) items
  proposedSharingServices: (NSArray *) proposedServices
  {
  NSMutableArray * sharingServices = [NSMutableArray array];
 
  [sharingServices
    addObject:
      [NSSharingService
        sharingServiceNamed: NSSharingServiceNameComposeEmail]];
 
  [sharingServices
    addObject:
      [NSSharingService
        sharingServiceNamed: NSSharingServiceNameComposeMessage]];

  [sharingServices
    addObject:
      [NSSharingService
        sharingServiceNamed: NSSharingServiceNameAddToSafariReadingList]];
 
  return sharingServices;
  }

#pragma mark - NSSharingServiceDelegate conformance

// Define the window that gets dimmed out during sharing.
- (NSWindow *) sharingService: (NSSharingService *) sharingService
  sourceWindowForShareItems: (NSArray *)items
  sharingContentScope: (NSSharingContentScope *) sharingContentScope
  {
  return self.window;
  }

- (NSRect) sharingService: (NSSharingService *) sharingService
  sourceFrameOnScreenForShareItem: (id<NSPasteboardWriting>) item
  {
  NSRect frame = [self.window.contentView bounds];
  
  frame = [self.window.contentView convertRect: frame toView: nil];
  
  return [[self.window.contentView window] convertRectToScreen: frame];
  }

- (NSImage *) sharingService: (NSSharingService *) sharingService
  transitionImageForShareItem: (id <NSPasteboardWriting>) item
  contentRect: (NSRect *) contentRect
  {
  NSRect rect = [self.window.contentView bounds];
  
  NSBitmapImageRep * imageRep =
    [self.window.contentView bitmapImageRepForCachingDisplayInRect: rect];
  
  [self.window.contentView
    cacheDisplayInRect: rect toBitmapImageRep: imageRep];

  NSImage * image = [[NSImage alloc] initWithSize: rect.size];
  [image addRepresentation: imageRep];
   
#if !__has_feature(objc_arc)
  [image autorelease];
#endif

  return image;
  }

#pragma mark - NSSharingServicePickerTouchBarItemDelegate conformance

- (NSArray *) itemsForSharingServicePickerTouchBarItem:
  (NSSharingServicePickerTouchBarItem *) pickerTouchBarItem
  API_AVAILABLE(macos(10.12.2))
  {
  NSArray * items = [NSArray array];
  
  /* NSURL * url = self.webview.url;
  
  if(url != nil)
    items = [NSArray arrayWithObject: url]; */
    
  return items;
  }

// Handle an action from the UI.
- (IBAction) showHelp: (id) sender
  {
  [self showHelp];
  }

@end
