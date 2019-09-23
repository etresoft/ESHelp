/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "AppDelegate.h"
#import <ESHelp/ESHelp.h>

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
  ESHelpManager * help = [ESHelpManager sharedHelpManager];
  
  [help showHelpAnchor: @"feature1"];
  }

- (IBAction) helpUse: (id) sender
  {
  ESHelpManager * help = [ESHelpManager sharedHelpManager];
  
  [help showHelpAnchor: @"usemyapp"];
  }

- (IBAction) helpFeature3: (id) sender
  {
  ESHelpManager * help = [ESHelpManager sharedHelpManager];
  
  [help showHelpAnchor: @"feature3"];
  }

- (IBAction) showHelp: (id) sender
  {
  ESHelpManager * help = [ESHelpManager sharedHelpManager];
  
  [help showHelp];
  }

@end
