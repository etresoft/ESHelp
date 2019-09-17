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

// Can I go back?
@synthesize canGoBack = myCanGoBack;

// Can I go forward?
@synthesize canGoForward = myCanGoForward;

// Can I share?
@dynamic canShare;

@synthesize webview = myWebView;

@synthesize basePath = myBasePath;

@synthesize helpIndex = myHelpIndex;

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
    
    NSString * helpIndexPath =
      [self.basePath stringByAppendingPathComponent: @"helpindex.plist"];
      
    NSData * data = [NSData dataWithContentsOfFile: helpIndexPath];
  
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
    
    [[NSApplication sharedApplication]
      addObserver: self
      forKeyPath: @"effectiveAppearance"
      options: 0
      context: NULL];
    }
    
  return self;
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
  self.shareToolbarItemView = nil;
  self.shareButton = nil;
  self.searchToolbarItemView = nil;
  self.searchField = nil;
  self.webview = nil;
  self.basePath = nil;
  self.helpIndex = nil;
  
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

  //if(self.basePath == nil)
  //  [self.window setFrameAutosaveName: @"EtreCheck Help Window"];
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
  
  [self.window setContentView: self.webview];
  }

- (void) showHelpAnchor: (NSString *) anchor
  {
  [self setup];

  if(anchor.length > 0)
    {
    NSArray * filePaths = [self.helpIndex objectForKey: anchor];
    
    NSString * filePath = filePaths.firstObject;
    
    if(filePath.length > 0)
      {
      __weak ESHelp * weakSelf = self;
      
      self.webview.readyHandler =
        ^{
          weakSelf.canGoBack = weakSelf.webview.canGoBack;
          weakSelf.canGoForward = weakSelf.webview.canGoForward;
          
          NSString * js =
            [[NSString alloc]
              initWithFormat: @"window.location.href = '#%@';", anchor];
          
          [weakSelf.webview
            executeJavaScript: js
            completion:
              ^(id result)
                {
                  [weakSelf setAppearance: [weakSelf appearanceName]];
                }];
          
#if !__has_feature(objc_arc)
          [js release];
#endif
        };

      [self showHelpFile: filePath];
      
      return;
      }
    }
  
  [self showHelp];
  }

- (void) showHelpFile: (NSString *) fileName
  {
  NSString * filePath =
    [self.basePath stringByAppendingPathComponent: fileName];
  
  [self.window makeKeyAndOrderFront: self];

  [self.webview loadURL: [NSURL fileURLWithPath: filePath]];
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
    [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 51, 25)];
  
  myGoBackButton =
    [[NSButton alloc] initWithFrame: NSMakeRect(-1, -2, 28, 27)];
  
  self.goBackButton.bezelStyle = NSTexturedSquareBezelStyle;
  self.goBackButton.image = [NSImage imageNamed: NSImageNameGoLeftTemplate];
  self.goBackButton.target = self;
  self.goBackButton.action = @selector(goBack:);
  [self.goBackButton
    bind: @"enabled" toObject: self withKeyPath: @"canGoBack" options: nil];
  
  myGoForwardButton =
    [[NSButton alloc] initWithFrame: NSMakeRect(24, -2, 28, 27)];

  self.goForwardButton.bezelStyle = NSTexturedSquareBezelStyle;

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
    
  [item setTarget: self];
  [item setAction: nil];
  
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
  //[items addObject: kSearchToolbarItemID];
  
  return items;
  }

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
  {
  return
    @[
      kNavigationToolbarItemID,
      //kShareToolbarItemID,
      NSToolbarFlexibleSpaceItemIdentifier,
      //kSearchToolbarItemID,
    ];

  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "allowed" list of items.
  }

#pragma mark - Sharing

// Go back.
- (IBAction) goBack: (id) sender
  {
  [self.webview goBack: sender];
  }

// Go forward.
- (IBAction) goForward: (id) sender
  {
  [self.webview goForward: sender];
  }

// Share the EtreCheck help.
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
  
  if(searchField.stringValue.length > 0)
    NSLog(@"perform search for: %@", searchField.stringValue);
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
