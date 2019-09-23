/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

// Just a little extension for my own needs.
@protocol ESHelpDelegate <NSObject>

// ESHelpProtocol.
- (void) openExternalURL: (NSURL *) url;

@end
