//
//  AppDelegate.h
//  BandLab Splitter
//
//  Created by Three MediaTech Co Pvt Ltd
//  Copyright (c) 2014 Three MediaTech Co Pvt Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

-(IBAction)open:(id)sender;

@property (weak) IBOutlet NSProgressIndicator *progressBar;

@property (weak) IBOutlet NSView *progressView;


@end
