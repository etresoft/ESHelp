/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "ESHelpWebView.h"
#import "ESHelpManager.h"

#import <WebKit/WebKit.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

@implementation ESHelpScriptRunner

@synthesize handler = myHandler;

+ (NSString *) webScriptNameForSelector: (SEL) sel
  {
  if(sel == @selector(postMessage:))
    return @"postMessage";
 
  return NSStringFromSelector(sel);
  }

+ (BOOL) isSelectorExcludedFromWebScript: (SEL) sel
  {
  if(sel == @selector(postMessage:))
    return NO;
    
  return YES;
  }

- (void) dealloc
  {
  self.handler = nil;
  
#if !__has_feature(objc_arc)
  [super dealloc];
#endif
  }

- (NSString *) postMessage: (NSObject *) object
  {
  if(self.handler != nil)
    return self.handler(object);
    
  return nil;
  }

@end

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

@interface ESHelpWebView ()

// Script handlers can't be installed until after loading.
@property (readonly) NSMutableDictionary * scriptHandlers;
@property (readonly) NSMutableDictionary * installedScriptHandlers;

@end

@implementation ESHelpWebView

// A delegate object.
@synthesize delegate = myDelegate;

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

// Script handlers can't be installed until after loading.
@synthesize scriptHandlers = myScriptHandlers;
@synthesize installedScriptHandlers = myInstalledScriptHandlers;

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

// Script handlers.
- (NSMutableDictionary *) scriptHandlers
  {
  if(myScriptHandlers == nil)
    myScriptHandlers = [NSMutableDictionary new];
    
  return myScriptHandlers;
  }

// Installed script handlers.
- (NSMutableDictionary *) installedScriptHandlers
  {
  if(myInstalledScriptHandlers == nil)
    myInstalledScriptHandlers = [NSMutableDictionary new];
    
  return myInstalledScriptHandlers;
  }

// Destructor.
- (void) dealloc
  {
  self.delegate = nil;
  self.readyHandler = nil;
  
#if !__has_feature(objc_arc)
  [myScriptHandlers release];
  [myInstalledScriptHandlers release];

  [myWkWebView release];
  [myWebView release];

  [super dealloc];
#endif
  }

// Load raw HTML with base path.
- (void) loadHTML: (NSString *) html baseURL: (NSURL *) url
  {
  [self.wkWebView loadHTMLString: html baseURL: url];
  [self.webView.mainFrame loadHTMLString: html baseURL: url];
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
  }

- (void) createWebView
  {
  // For testing legacy webkit.
  //self.api = kWebKit;
  
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
  decidePolicyForNavigationAction: (WKNavigationAction *) navigationAction
  decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler
  {
  NSURL * url = navigationAction.request.URL;
  
  if(![url isFileURL])
    {
    [self.delegate openExternalURL: url];

    decisionHandler(WKNavigationActionPolicyCancel);

    return;
    }
    
  [self.delegate addURLToHistory: url];
    
  if([self.delegate isSearchURL: url])
    {
    decisionHandler(WKNavigationActionPolicyCancel);

    return;
    }

  decisionHandler(WKNavigationActionPolicyAllow);
  }

- (void) webView: (WKWebView *) webView
  didCommitNavigation: (WKNavigation *) navigation
  {
  for(NSString * key in self.scriptHandlers)
    {
    ScriptHandler handler = [self.scriptHandlers objectForKey: key];
    
    [webView.configuration.userContentController
      addScriptMessageHandler: self name: key];
    
    [self.installedScriptHandlers setObject: handler forKey: key];
    }

  [self.scriptHandlers removeAllObjects];
  }

- (void) webView: (WKWebView *) webView
  didFinishNavigation: (WKNavigation *) navigation
  {
  if(self.readyHandler != nil)
    self.readyHandler();
  }

#pragma mark - WebPolicyDelegate

- (void) webView: (WebView *) webView
  decidePolicyForNavigationAction: (NSDictionary *) actionInformation
  request: (NSURLRequest *) request
  frame: (WebFrame *) frame
  decisionListener: (id<WebPolicyDecisionListener>) listener
  {
  NSURL * url = [actionInformation objectForKey: WebActionOriginalURLKey];
  
  if(![url isFileURL])
    {
    [self.delegate openExternalURL: url];

    [listener ignore];

    return;
    }
    
  [self.delegate addURLToHistory: url];
    
  if([self.delegate isSearchURL: url])
    {
    [listener ignore];

    return;
    }

  [listener use];
  }

#pragma clang diagnostic pop

- (void) webView: (WebView *) sender
  decidePolicyForNewWindowAction: (NSDictionary *) actionInformation
  request: (NSURLRequest *) request
  newFrameName: (NSString *) frameName
  decisionListener: (id<WebPolicyDecisionListener>) listener
  {
  NSURL * url = [actionInformation objectForKey: WebActionOriginalURLKey];
  
  if(![url isFileURL])
    {
    [self.delegate openExternalURL: url];

    [listener ignore];

    return;
    }
    
  [self.delegate addURLToHistory: url];
    
  if([self.delegate isSearchURL: url])
    {
    [listener ignore];

    return;
    }

  [listener use];
  }

#pragma mark - WebFrameLoadDelegate conformance

- (void) webView: (WebView *) sender
  didFinishLoadForFrame: (WebFrame *) frame
  {
  for(NSString * key in self.scriptHandlers)
    {
    ScriptHandler handler = [self.scriptHandlers objectForKey: key];
    
    ESHelpScriptRunner * scriptRunner = [ESHelpScriptRunner new];
    
    scriptRunner.handler = handler;
    
    id win = [self.webView windowScriptObject];
    
    [win setValue: scriptRunner forKey: key];
    
#if !__has_feature(objc_arc)
    [scriptRunner release];
#endif
    }

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

#pragma mark - WKScriptMessageHandler

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (void)
  userContentController: (WKUserContentController *) userContentController
  didReceiveScriptMessage: (WKScriptMessage *) message
  {
  //NSLog(@"receipted scripthandler for %@", message.name);
  ScriptHandler handler =
    [self.installedScriptHandlers objectForKey: message.name];
  
  if(handler != nil)
    handler(message.body);
  }

#pragma clang diagnostic pop

#pragma mark - Script handling

// Add a script handler.
- (void) addScriptHandler: (ScriptHandler) handler forKey: (NSString *) key
  {
  ScriptHandler handlerCopy = [handler copy];
  
  [self.scriptHandlers setObject: handlerCopy forKey: key];
  
#if !__has_feature(objc_arc)
  [handlerCopy release];
#endif
  }

// Remove a script handler.
- (void) removeScriptHandlerForKey: (NSString *) key
  {
  if([self.installedScriptHandlers objectForKey: key] != nil)
    [self.wkWebView.configuration.userContentController
      removeScriptMessageHandlerForName: key];
    
  [self.scriptHandlers removeObjectForKey: key];
  [self.installedScriptHandlers removeObjectForKey: key];
  }

@end

#pragma clang diagnostic pop
