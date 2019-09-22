/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "ESHelp.h"
#import "ESHelpWebView.h"

#import <Cocoa/Cocoa.h>

// Toolbar items.
#define kNavigationToolbarItemID @"navigationtoolbaritem"
#define kShareToolbarItemID @"sharetoolbaritem"
#define kSearchToolbarItemID @"searchtoolbaritem"

ESHelp * ourHelp = nil;

@implementation ESHelp

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

// Can I share?
@dynamic canShare;

@synthesize webview = myWebView;

@synthesize basePath = myBasePath;

@synthesize helpIndex = myHelpIndex;
@synthesize helpFiles = myHelpFiles;

- (BOOL) canShare
  {
  return YES;
  }

+ (ESHelp *) shared
  {
  if(ourHelp == nil)
    ourHelp = [ESHelp new];
    
  return ourHelp;
  }

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    ourHelp = self;
    
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
          NSLocalizedString(@"en.lproj", NULL)];
      
    self.basePath = localizedHelpBasePath;
    
    myHistory = [NSMutableArray new];
    myHistoryIndex = 0;
    
    [self readAnchorIndex];
    [self readFileIndex];
    
    [[NSApplication sharedApplication]
      addObserver: self
      forKeyPath: @"effectiveAppearance"
      options: 0
      context: NULL];
    }
    
  return self;
  }

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

- (void) readFileIndex
  {
  NSString * fileIndexKey =
    [self helpBundleDictionaryValue: @"ESHelpHelpFiles"];
  
  NSString * helpFilesPath =
    [self.basePath stringByAppendingPathComponent: fileIndexKey];

  NSString * text =
    [[NSString alloc]
      initWithContentsOfFile: helpFilesPath
      encoding: NSUTF8StringEncoding
      error: NULL];

  NSArray * lines = [text componentsSeparatedByString: @"\n"];
  
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
        [data release];
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
  [lines release];
#endif
  }

- (NSString *) readSearchText: (NSString *) path
  {
  NSData * data = [[NSData alloc] initWithContentsOfFile: path];

  NSURL * baseURL =
    [NSURL fileURLWithPath: [path stringByDeletingLastPathComponent]];
  
  NSAttributedString * attributedString =
    [[NSAttributedString alloc]
      initWithHTML: data baseURL: baseURL documentAttributes: NULL];

  if(attributedString == nil)
    return nil;
    
  NSString * text = attributedString.string;
  
#if !__has_feature(objc_arc)
  [attributedString release];
#endif

  return text;
  }

// Destructor.
- (void) dealloc
  {
  [[NSApplication sharedApplication]
    removeObserver: self forKeyPath: @"effectiveAppearance"];

  self.window = nil;
  self.toolbar = nil;
  self.navigationToolbarItemView = nil;
  self.goBackButton = nil;
  self.goForwardButton = nil;
  self.history = nil;
  self.shareToolbarItemView = nil;
  self.shareButton = nil;
  self.searchToolbarItemView = nil;
  self.searchField = nil;
  self.searchResultsTemplate = nil;
  self.webview = nil;
  self.basePath = nil;
  self.helpIndex = nil;
  self.helpFiles = nil;
  
#if !__has_feature(objc_arc)
  [super dealloc];
#endif
  }

- (void) showHelp
  {
  [self setup];
  
  [self showHelpFile: @"index.html"];
  }

- (void) setup
  {
  [self createHelpWindow];
  
  __weak ESHelp * weakSelf = self;

  self.webview.readyHandler =
    ^{
      weakSelf.canGoBack = weakSelf.webview.canGoBack;
      weakSelf.canGoForward = weakSelf.webview.canGoForward;
      
      [weakSelf setAppearance: [weakSelf appearanceName]];
    };

  [self.webview
    addScriptHandler:
      ^NSString * (NSObject * object)
        {
        [weakSelf performWebSearch];
          
        return @"OK";
        }
    forKey: @"help"];
  }

- (void) createHelpWindow
  {
  if(self.window != nil)
    return;
    
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
  
  myWebView = [[ESHelpWebView alloc] initWithFrame: frame];
  
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
  
  [self.window setContentView: self.webview];
  
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

- (void) showHelpURL: (NSURL *) url
  {
  __weak ESHelp * weakSelf = self;
  
  self.webview.readyHandler =
    ^{
      weakSelf.canGoBack = (weakSelf.historyIndex > 1);
      
      weakSelf.canGoForward =
        (weakSelf.historyIndex < weakSelf.history.count);
  
      [weakSelf setAppearance: [weakSelf appearanceName]];
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
  
  [item setLabel: NSLocalizedString(@"Back/Forward", nil)];
  [item setPaletteLabel: NSLocalizedString(@"Back/Forward", nil)];
  [item setView: self.navigationToolbarItemView];
    
  [item setTarget: self];
  [item setAction: nil];
  
#if !__has_feature(objc_arc)
  [item autorelease];
#endif

  return item;
  }

- (NSToolbarItem *) createShareToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  // Create the NSToolbarItem and setup its attributes.
  NSToolbarItem * item =
    [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  
  if([NSSharingServicePicker class])
    {
    [item setLabel: NSLocalizedString(@"Share page", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Share page", nil)];
    [item setView: self.shareToolbarItemView];
    }
    
  [item setTarget: self];
  [item setAction: nil];
  [self.shareButton sendActionOn: NSLeftMouseDownMask];

#if !__has_feature(objc_arc)
  [item autorelease];
#endif

  return item;
  }

- (NSToolbarItem *) createSearchToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  mySearchToolbarItemView =
    [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 236, 25)];

  mySearchField =
    [[NSSearchField alloc] initWithFrame: NSMakeRect(1, 2, 235, 22)];
  
  [self.searchToolbarItemView addSubview: self.searchField];
  
  // Create the NSToolbarItem and setup its attributes.
  NSToolbarItem * item =
    [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
  
  [item setLabel: NSLocalizedString(@"Search", nil)];
  [item setPaletteLabel: NSLocalizedString(@"Search", nil)];
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
  //[items addObject: kShareToolbarItemID];
  [items addObject: NSToolbarFlexibleSpaceItemIdentifier];
  [items addObject: kSearchToolbarItemID];
  
  return items;
  }

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
  {
  return
    @[
      kNavigationToolbarItemID,
      //kShareToolbarItemID,
      NSToolbarFlexibleSpaceItemIdentifier,
      kSearchToolbarItemID,
    ];

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

// Share help.
- (IBAction) shareHelp: (id) sender
  {
  /* NSURL * url = self.webview.url;
  
  if(url != nil)
    {
    NSSharingServicePicker * sharingServicePicker =
      [[NSSharingServicePicker alloc]
        initWithItems: [NSArray arrayWithObject: url]];
   
    sharingServicePicker.delegate = self;
   
    [sharingServicePicker
      showRelativeToRect: NSZeroRect
      ofView: sender
      preferredEdge: NSMinYEdge];
   
    [sharingServicePicker release];
    } */
  }

- (IBAction) performSearch: (id) sender
  {
  NSSearchField * searchField = sender;

  self.currentSearch = searchField.stringValue;
  
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

- (void) search: (NSString *) search
  {
  NSMutableArray * matches = [NSMutableArray array];
  
  if(search.length > 0)
    {
    for(NSString * path in self.helpFiles)
      {
      NSDictionary * dict = self.helpFiles[path];
      
      NSString * text = dict[@"text"];
      
      NSRange range = [text rangeOfString: search];
      
      if(range.location != NSNotFound)
        [matches addObject: dict];
      }
    }
    
  [self showMatches: matches];
  
#if !__has_feature(objc_arc)
  [matches autorelease];
#endif
  }

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

- (void) showMatches: (NSArray *) results
  {
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
    
  NSString * resultsUnits = NSLocalizedString(@"results", NULL);
  
  if(results.count == 1)
    resultsUnits = NSLocalizedString(@"result", NULL);
    
  NSString * resultsCountString =
    [NSString stringWithFormat: @"%lu", (unsigned long)results.count];
  
  NSString * resultsCount =
    [[NSString alloc]
      initWithFormat: @"%@ %@", resultsCountString, resultsUnits];
    
  if(results.count == 0)
    resultsCount = NSLocalizedString(@"no results", NULL);
    
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

  NSString * showAll = @"";
  
  if(results.count > maxSearchResults)
    showAll =
      [[NSString alloc]
        initWithFormat:
          linkTemplate,
          @"showalllink",
          @"showall()",
          NSLocalizedString(@"Show all", NULL),
          NSLocalizedString(@"showallicon", NULL),
          @"<hr class=\"searchresults\">"];

  NSString * searchWeb =
    [[NSString alloc]
      initWithFormat:
        linkTemplate,
        @"searchweblink",
        @"searchweb()",
        NSLocalizedString(@"Search the web for more results", NULL),
        NSLocalizedString(@"searchwebicon", NULL),
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
  [ul release];
  [header release];
  [searchResultsHeader release];
  [resultsCount release];
  [showAll release];
  [searchWeb release];
#endif
  }

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

  if([self performSearch: @"Google" pasteboard: pboard])
    return;

  if([self performSearch: @"DuckDuckGo" pasteboard: pboard])
    return;

  if([self performSearch: @"Bing" pasteboard: pboard])
    return;

  if([self performSearch: @"Yahoo" pasteboard: pboard])
    return;
  }
  
- (BOOL) performSearch: (NSString *) engine
  pasteboard: (NSPasteboard *) pboard
  {
  NSString * serviceName =
    [[NSString alloc]
      initWithFormat:
        @"%@ %@", NSLocalizedString(@"Search With", NULL), engine];
    
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

/*- (NSArray *)
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
 
  return sharingServices;
  } */

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

#pragma - Dark mode

// Set the effective appearance.
- (void) setAppearance: (NSString *) appearanceName
  {
  NSString * js =
    [[NSString alloc]
      initWithFormat: @"setAppearance(\"%@\")", appearanceName];
  
  [self.webview executeJavaScript: js completion: nil];

#if !__has_feature(objc_arc)
  [js release];
#endif
  }

- (void) observeValueForKeyPath: (NSString *) keyPath
  ofObject: (id) object
  change: (NSDictionary *) change
  context: (void *) context
  {
  if([keyPath isEqualToString: @"effectiveAppearance"])
    [self setAppearance: [self appearanceName]];
  }

- (IBAction) showHelp: (id) sender
  {
  [self showHelp];
  }

- (NSString *) appearanceName
  {
  NSString * name = @"Aqua";
  
  SEL effectiveAppearanceSelector =
    NSSelectorFromString(@"effectiveAppearance");
  
  if(NSClassFromString(@"NSAppearance"))
    {
    NSAppearance * appearance = nil;
    
    NSApplication * app = [NSApplication sharedApplication];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if([app respondsToSelector: effectiveAppearanceSelector])
      appearance = [app performSelector: effectiveAppearanceSelector];
#pragma clang diagnostic pop

    NSString * appearanceName = appearance.name;
    
    if(appearanceName.length > 16)
      appearanceName = [appearance.name substringFromIndex: 16];
      
    if(appearanceName.length > 0)
      name = appearanceName;
    }
    
  return name;
  }

@end
