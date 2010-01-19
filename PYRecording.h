//
//  PYRecording.h
//  WFDBKit
//
//  Created by Richard Penwell on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PYRecording : NSObject {
	WFDB_Siginfo* _signalInfo;
	NSMutableDictionary* _signals;
}

- (id)initWithFile:(NSURL*)file;

+ (PYRecording*)recordingWithFile:(NSURL*)file;

@end
