//
//  SampleHandler.m
//  SampleBroadcastUpload
//
//  Created by Sopl’Wang on 2016/10/10.
//  Copyright © 2016年 videocore. All rights reserved.
//


#import "SampleHandler.h"

#import <videocore/api/iOS/VCReplaySession.h>

@interface VCReplaySessionCallback : NSObject <VCReplaySessionDelegate>
@end
@implementation VCReplaySessionCallback
- (void) connectionStatusChanged: (VCSessionState) sessionState {
    NSLog(@"VCReplaySession status: %ld", sessionState);
}
@end

//  To handle samples with a subclass of RPBroadcastSampleHandler set the following in the extension's Info.plist file:
//  - RPBroadcastProcessMode should be set to RPBroadcastProcessModeSampleBuffer
//  - NSExtensionPrincipalClass should be set to this class

@implementation SampleHandler

+ (id) sharedSession
{
    static VCReplaySession *sharedSession = nil;
    static VCReplaySessionCallback *callback = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedSession = [[VCReplaySession alloc] initWithVideoSize:CGSizeMake(368, 640) frameRate:20 bitrate:650000];
        sharedSession.delegate = callback = [[VCReplaySessionCallback alloc] init];
    });
    return sharedSession;
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension will be supplied.
    NSLog(@"broadcastStartedWithSetupInfo");

    NSLog(@"Starting RTMP session");
    VCReplaySession *session = [SampleHandler sharedSession];

    if (session.rtmpSessionState == VCSessionStateNone) {
        [session startRtmpSessionWithURL:@"rtmp://192.168.1.1" andStreamKey:@"test"];
    }
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    NSLog(@"broadcastPaused");
    
    NSLog(@"Pause RTMP session");
    [[SampleHandler sharedSession] broadcastPaused];
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    NSLog(@"broadcastResumed");

    NSLog(@"Resume RTMP session");
    [[SampleHandler sharedSession] broadcastResumed];
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    NSLog(@"broadcastFinished");

    NSLog(@"Ending RTMP session");
    [[SampleHandler sharedSession] endRtmpSession];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {

    NSLog(@"processSampleBuffer:withType: %ld", (long)sampleBufferType);

    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            if (sampleBuffer && CMSampleBufferDataIsReady(sampleBuffer)) {
                CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                if (!imageBuffer) return;
                size_t width  = CVPixelBufferGetWidth(imageBuffer);
                size_t height = CVPixelBufferGetHeight(imageBuffer);

                if (width > height) {
                    [[SampleHandler sharedSession] pushVideoSample:sampleBuffer orientation:VCReplayOrientationCW90Degrees];
                } else {
                    [[SampleHandler sharedSession] pushVideoSample:sampleBuffer orientation:VCReplayOrientationCW0Degrees];
                }
            }
            break;
        case RPSampleBufferTypeAudioApp:
            [[SampleHandler sharedSession] pushAudioSample:sampleBuffer Mic:NO];
            break;
        case RPSampleBufferTypeAudioMic:
            [[SampleHandler sharedSession] pushAudioSample:sampleBuffer Mic:YES];
            break;
        default:
            break;
    }
}

@end
