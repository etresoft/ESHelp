/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "AppDelegate.h"
#import <ESHelpKit/ESHelpKit.h>

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
  ESHelp * help = [ESHelp shared];
  
  [help showHelpAnchor: @"feature1"];
  }

- (IBAction) helpUse: (id) sender
  {
  ESHelp * help = [ESHelp shared];
  
  [help showHelpAnchor: @"usemyapp"];
  }

- (IBAction) helpFeature3: (id) sender
  {
  ESHelp * help = [ESHelp shared];
  
  [help showHelpAnchor: @"feature3"];
  }

- (IBAction) showHelp: (id) sender
  {
  ESHelp * help = [ESHelp shared];
  
  [help showHelp];
  }

@end
