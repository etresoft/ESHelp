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
  
  if([self isSearchURL: url])
    {
    decisionHandler(WKNavigationActionPolicyCancel);

    return;
    }

  if(![url isFileURL])
    {
    [[NSWorkspace sharedWorkspace] openURL: url];

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
  
  if([self isSearchURL: url])
    {
    [listener ignore];

    return;
    }

  if(![url isFileURL])
    {
    [[NSWorkspace sharedWorkspace] openURL: url];

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
  
  if([self isSearchURL: url])
    {
    [listener ignore];

    return;
    }

  if(![url isFileURL])
    {
    [[NSWorkspace sharedWorkspace] openURL: url];

    [listener ignore];

    return;
    }
    
  [listener use];
  }

- (BOOL) isSearchURL: (NSURL *) url
  {
  if(self.delegate.basePath != nil)
    if([url.path hasPrefix: self.delegate.basePath])
      {
      NSString * file = [url.path lastPathComponent];
      
      if([file hasPrefix: @"search-"])
        {
        NSString * search = [file substringFromIndex: 7];
        
        [self.delegate search: search];

        return YES;
        }
      }
    
  return NO;
  }

@end
