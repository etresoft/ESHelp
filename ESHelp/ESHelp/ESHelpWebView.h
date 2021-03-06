/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

// Category to expand an NSView to fit its container.
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

// A script handler for DOM events.
typedef NSString * (^ScriptHandler)(NSObject * object);

// Shim to get ScriptHandler working with legacy webview.
@interface ESHelpScriptRunner : NSObject

@property (strong) ScriptHandler handler;

- (NSString *) postMessage: (NSObject *) object;

@end

@class ESHelpManager;

// A IB-friendly webview. This class works with both the new WK webviews and
// the legacy webviews. Note that WK is NOT fully functional even in the
// current version of macOS. It works for this use case back to 10.10. For
// some use cases, WK only works back to 10.13.
@interface ESHelpWebView : NSView
  <WKNavigationDelegate,
  WKScriptMessageHandler,
  WebUIDelegate,
  WebFrameLoadDelegate,
  WebPolicyDelegate,
  WebResourceLoadDelegate>

// A delegate object.
@property (strong) ESHelpManager * delegate;

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

// Load raw HTML with base path.
- (void) loadHTML: (NSString *) html baseURL: (NSURL *) url;

// Load a file URL.
- (void) loadURL: (NSURL *) url;

// Execute Javascript.
- (void) executeJavaScript: (NSString *) js
  completion: (CompletionHandler) complete;

// Navigate backwards.
- (IBAction) goBack: (id) sender;

// Navigate forwards.
- (IBAction) goForward: (id) sender;

// Add a script handler for DOM events.
- (void) addScriptHandler: (ScriptHandler) handler forKey: (NSString *) key;

// Remove a script handler.
- (void) removeScriptHandlerForKey: (NSString *) key;

@end

#pragma clang diagnostic pop
