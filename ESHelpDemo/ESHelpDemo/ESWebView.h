/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface NSView (ESKit)

// Expand this view to fit its superview.
- (void) expandToFit;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

// API type.
typedef enum WebAPI
  {
  kWKWebKit,
  kWebKit
  }
WebAPI;

// Called when the HTML has loaded.
typedef void (^ReadyHandler)(void);

// A completion handler for results from Javascript.
typedef void (^CompletionHandler)(id result);

// A IB-friendly webview.
@interface ESWebView : NSView
  <WKNavigationDelegate,
  WebUIDelegate,
  WebFrameLoadDelegate,
  WebPolicyDelegate,
  WebResourceLoadDelegate>

// The desired web view API.
@property (assign) WebAPI api;

// The WebView object.
@property (readonly) WebView * webView;

// The WKWebView object.
@property (readonly) WKWebView * wkWebView;

// Actions to perform when the initial load is complete.
@property (strong) ReadyHandler readyHandler;

// Is a backwards navigation allowed?
@property (readonly) BOOL canGoBack;

// Is a forwards navigation allowed?
@property (readonly) BOOL canGoForward;

// Load a file URL with base path.
- (void) loadURL: (NSURL *) url;

// Execute Javascript.
- (void) executeJavaScript: (NSString *) js
  completion: (CompletionHandler) complete;

// Navigate backwards.
- (IBAction) goBack: (id) sender;

// Navigate forwards.
- (IBAction) goForward: (id) sender;

@end

#pragma clang diagnostic pop
