//
//  DemoImageEditorViewController.m
//  ImageEditor
//
//  Created by Heitor Ferreira on 03/11/12.
//  Copyright (c) 2012 Heitor Ferreira. All rights reserved.
//

#import "DemoImageEditor.h"

@interface DemoImageEditor ()

@end

@implementation DemoImageEditor

@synthesize  saveButton = _saveButton;

- (void)dealloc
{
    [_saveButton release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.saveButton = nil;
}

- (IBAction)setSquare:(id)sender
{
    self.cropSize = CGSizeMake(320, 320);
}

- (IBAction)setLandscape:(id)sender
{
    self.cropSize = CGSizeMake(320, 240);
}


- (IBAction)setLPortrait:(id)sender
{
    self.cropSize = CGSizeMake(240, 320);
}

#pragma mark Hooks
- (void)startTransformHook
{
    self.saveButton.tintColor = [UIColor colorWithRed:0 green:49/255.0f blue:98/255.0f alpha:1];
}

- (void)endTransformHook
{
    self.saveButton.tintColor = [UIColor colorWithRed:0 green:128/255.0f blue:1 alpha:1];
}


@end
