//
//  Setup.h
//  PlaylistExtender
//
//  Created by Lauren Brown on 28/05/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

#ifndef PlaylistExtender_Setup_h
#define PlaylistExtender_Setup_h

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

@interface Setup : NSObject

@property(nonatomic, strong) SPTSession *session;
@property(nonatomic, strong) SPTAudioStreamingController *player;

@end

#endif
