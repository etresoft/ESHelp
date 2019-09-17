/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "ESWebView.h"

#import <WebKit/WebKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

@implementation NSView (ESKit)

// Expand this view to fit its superview.
- (void) expandToFit
  {
  NSLayoutConstraint * leading =
    [NSLayoutConstraint
      constraintWithItem: self
      attribute: NSLayoutAttributeLeading
      relatedBy: NSLayoutRelationEqual
      toItem: self.superview
      attribute: NSLayoutAttributeLeading
      multiplier: 1.0
      constant: 0.0];
    
  NSLayoutConstraint * trailing =
    [NSLayoutConstraint
      constraintWithItem: self
      attribute: NSLayoutAttributeTrailing
      relatedBy: NSLayoutRelationEqual
      toItem: self.superview
      attribute: NSLayoutAttributeTrailing
      multiplier: 1.0
      constant: 0.0];
    
  NSLayoutConstraint * top =
    [NSLayoutConstraint
      constraintWithItem: self
      attribute: NSLayoutAttributeTop
      relatedBy: NSLayoutRelationEqual
      toItem: self.superview
      attribute: NSLayoutAttributeTop
      multiplier: 1.0
      constant: 0.0];

  NSLayoutConstraint * bottom =
    [NSLayoutConstraint
      constraintWithItem: self
      attribute: NSLayoutAttributeBottom
      relatedBy: NSLayoutRelationEqual
      toItem: self.superview
      attribute: NSLayoutAttributeBottom
      multiplier: 1.0
      constant: 0.0];
    
  [self.superview addConstraint: leading];
  [self.superview addConstraint: trailing];
  [self.superview addConstraint: top];
  [self.superview addConstraint: bottom];
  }

@end

@implementation ESWebView

// The desired web view API.
@synthesize api = myAPI;

// The WebView object.
@synthesize webView = myWebView;

// The WKWebView object.
@synthesize wkWebView = myWkWebView;

// Actions to perform when the initial load is complete.
@synthesize readyHandler = myReadyHandler;

// Is a backwards navigation allowed?
@dynamic canGoBack;

// Is a forwards navigation allowed?
@dynamic canGoForward;

- (BOOL) canGoBack
  {
  if(self.wkWebView != nil)
    return self.wkWebView.canGoBack;
  
  return self.webView.canGoBack;
  }

- (BOOL) canGoForward
  {
  if(self.wkWebView != nil)
    return self.wkWebView.canGoForward;
    
  return self.webView.canGoForward;
  }

// Destructor.
- (void) dealloc
  {
  BOOL removeObserver = (self.wkWebView != nil);

  if(!removeObserver)
    removeObserver = (self.webView != nil);
    
  if(removeObserver)
    [[NSApplication sharedApplication]
      removeObserver: self forKeyPath: @"effectiveAppearance"];

#if !__has_feature(objc_arc)
  [myWkWebView release];
  [myWebView release];

  self.readyHandler = nil;
  
  [super dealloc];
#endif
  }

// Load a URL (for compatibility testing).
- (void) loadURL: (NSURL *) url
  {
  NSURLRequest * request = [[NSURLRequest alloc] initWithURL: url];
  
  [self.wkWebView loadRequest: request];
  [self.webView.mainFrame loadRequest: request];
    
#if !__has_feature(objc_arc)
  [request release];
#endif
  }

#pragma mark - Script handling

// Execute Javascript.
- (void) executeJavaScript: (NSString *) js
  completion: (CompletionHandler) complete
  {
  if(self.wkWebView != nil)
    {
    [self.wkWebView
      evaluateJavaScript: js
      completionHandler:
        ^(id _Nullable result, NSError * _Nullable error)
          {
          if(complete != nil)
            complete(result);
          }];
      
    return;
    }
    
  if(self.webView != nil)
    {
    NSString * result =
      [self.webView stringByEvaluatingJavaScriptFromString: js];
      
    if(complete != nil)
      complete(result);
    }
  }

#pragma mark - Generate views

- (void) layout
  {
  [super layout];
  
  if(self.wkWebView != nil)
    return;
    
  if(self.webView != nil)
    return;
    
  [self createWebView];
  
  BOOL addObserver = (self.wkWebView == nil);
    
  if(!addObserver)
    addObserver = (self.webView != nil);
    
  [[NSApplication sharedApplication]
    addObserver: self
    forKeyPath: @"effectiveAppearance"
    options: 0
    context: NULL];
  }

- (void) createWebView
  {
  self.api = kWebKit;
  
  if(self.api == kWKWebKit)
    if([WKWebView class] != nil)
      {
      [self createWKWebView: self.bounds];
  
      return;
      }
    
  [self createWebView: self.bounds];
  }
  
// Create the actual web view.
- (void) createWKWebView: (NSRect) bounds
  {
  WKWebView * webView = [[WKWebView alloc] initWithFrame: bounds];
    
  [webView setValue: @NO forKey: @"drawsBackground"];

  webView.navigationDelegate = self;
  
  webView.autoresizingMask =
    NSViewMinXMargin
      | NSViewWidthSizable
      | NSViewMaxXMargin
      | NSViewMinYMargin
      | NSViewHeightSizable
      | NSViewMaxYMargin;
    
  webView.wantsLayer = YES;
  
  myWkWebView = webView;
  
#if !__has_feature(objc_arc)
  [myWkWebView retain];
  [webView release];
#endif

  self.wkWebView.translatesAutoresizingMaskIntoConstraints = NO;
  
  [self addSubview: self.wkWebView];

  [self.wkWebView expandToFit];
  }

// Create the actual web view.
- (void) createWebView: (NSRect) bounds
  {
  WebView * webView = [[WebView alloc] initWithFrame: bounds];
  
  webView.drawsBackground = NO;

  webView.frameLoadDelegate = self;
  webView.UIDelegate = self;
  webView.policyDelegate = self;
  webView.resourceLoadDelegate = self;

  webView.autoresizingMask =
    NSViewMinXMargin
      | NSViewWidthSizable
      | NSViewMaxXMargin
      | NSViewMinYMargin
      | NSViewHeightSizable
      | NSViewMaxYMargin;
    
  webView.wantsLayer = YES;
  
  myWebView = webView;
  
#if !__has_feature(objc_arc)
  [myWebView retain];
  [webView release];
#endif

  self.webView.translatesAutoresizingMaskIntoConstraints = NO;
  
  [self addSubview: self.webView];

  [self.webView expandToFit];
  }

#pragma mark - WKNavigationDelegate conformance

- (void) webView: (WKWebView *) webView
  didFinishNavigation: (WKNavigation *) navigation
  {
  if(self.readyHandler != nil)
    self.readyHandler();
  }

#pragma mark - WebFrameLoadDelegate conformance

- (void) webView: (WebView *) sender
  didFinishLoadForFrame: (WebFrame *) frame
  {
  if(self.readyHandler != nil)
    self.readyHandler();
  }

#pragma mark - Navigation

// Go back.
- (IBAction) goBack: (id) sender
  {
  [self.wkWebView goBack: sender];
  [self.webView goBack: sender];
  }

// Go back.
- (IBAction) goForward: (id) sender
  {
  [self.wkWebView goForward: sender];
  [self.webView goForward: sender];
  }

#pragma mark - Appearance changes

- (void) observeValueForKeyPath: (NSString *) keyPath
  ofObject: (id) object
  change: (NSDictionary *) change
  context: (void *) context
  {
  if([keyPath isEqualToString: @"effectiveAppearance"])
    {
    }
  }

@end

#pragma clang diagnostic pop
