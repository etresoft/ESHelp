/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow * window;

@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
  {
  // Insert code here to initialize your application
  }

- (void) applicationWillTerminate: (NSNotification *) aNotification
  {
  // Insert code here to tear down your application
  }

- (IBAction) helpFeature1: (id) sender
  {
  NSString * locBookName =
    [[NSBundle mainBundle]
      objectForInfoDictionaryKey: @"CFBundleHelpBookName"];

  [[NSHelpManager sharedHelpManager]
    openHelpAnchor: @"feature1" inBook: locBookName];
  }

- (IBAction) helpUse: (id) sender
  {
  NSString * locBookName =
    [[NSBundle mainBundle]
      objectForInfoDictionaryKey: @"CFBundleHelpBookName"];

  [[NSHelpManager sharedHelpManager]
    openHelpAnchor: @"usemyapp" inBook: locBookName];
  }

- (IBAction) helpFeature3: (id) sender
  {
  NSString * locBookName =
    [[NSBundle mainBundle]
      objectForInfoDictionaryKey: @"CFBundleHelpBookName"];

  [[NSHelpManager sharedHelpManager]
    openHelpAnchor: @"feature3" inBook: locBookName];
  }

@end
