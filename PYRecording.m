//
//  PYRecording.m
//  WFDBKit
//
//  Created by Richard Penwell on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PYRecording.h"


@implementation PYRecording

- (id)initWithFile:(NSURL*)file
{
	if (self = [super init])
	{
		fileName = file;
	}
	
	return self;
}

+ (PYRecording*)recordingWithFile:(NSURL*)file
{
	return [[PYRecording alloc] initWithFile:file];
}

@end
