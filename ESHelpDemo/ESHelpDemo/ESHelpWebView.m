/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "ESHelpWebView.h"
#import "ESHelp.h"

// Just in case you want any custom behaviour.
@implementation ESHelpWebView

@synthesize delegate = myDelegate;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (void) dealloc
  {
  self.delegate = nil;
  
#if !__has_feature(objc_arc)
  [super dealloc];
#endif
  }
  
#pragma mark - WKNavigationDelegate conformance

- (void) webView: (WKWebView *) webView
  decidePolicyForNavigationAction: (WKNavigationAction *) navigationAction
  decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler
  {
  NSURL * url = navigationAction.request.URL;
  
  if(![url isFileURL])
    {
    [[NSWorkspace sharedWorkspace] openURL: url];

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
    [[NSWorkspace sharedWorkspace] openURL: url];

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
    [[NSWorkspace sharedWorkspace] openURL: url];

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

@end
