/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2019. All rights reserved.
 **********************************************************************/

#import "ESWebView.h"

@class ESHelp;

// Just in case you want any custom behaviour.
@interface ESHelpWebView : ESWebView

@property (strong) ESHelp * delegate;

@end
