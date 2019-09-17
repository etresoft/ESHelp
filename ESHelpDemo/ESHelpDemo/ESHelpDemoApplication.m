/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "ESHelpDemoApplication.h"
#import "AppDelegate.h"

@implementation ESHelpDemoApplication

- (IBAction) showHelp: (id) sender
  {
  AppDelegate * delegate = self.delegate;
  
  [delegate showHelp: sender];
  }

@end
