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


@end
