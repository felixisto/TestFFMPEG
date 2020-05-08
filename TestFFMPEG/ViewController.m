//
//  ViewController.m
//  TestFFMPEG
//
//  Created by Kristiyan Butev on 5/8/20.
//  Copyright © 2020 Test. All rights reserved.
//

#import "ViewController.h"

#include <libavformat/avformat.h>
#include <libavutil/display.h>
#include <libavutil/eval.h>
#include <libavutil/imgutils.h>
#include <libswresample/swresample.h>
#include <libswscale/swscale.h>



@interface ViewController () {
    AVFormatContext *context;
}

@property (strong, nonatomic) NSThread* readThread;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    BOOL result = [self open:@"http://192.168.1.2:8080/Videos/Test/broken.MOV"];
    
    if (result) {
        NSLog(@"FFMPEGTest: Successfully opened stream");
        [self startReadLoop];
    } else {
        NSLog(@"FFMPEGTest: Failed to open stream");
    }
}

- (BOOL)open:(NSString*)url {
    av_log_set_level(AV_LOG_TRACE);

    context = avformat_alloc_context();
    
    int result = avformat_open_input(&context, [url UTF8String], NULL, NULL);

    if (result != 0) {
        if (context != NULL) {
            avformat_free_context(context);
        }
        
        return false;
    }

    #ifdef DEBUG
        av_dump_format(context, 0, [url UTF8String], 0);
    #endif

    result = avformat_find_stream_info(context, NULL);

    if (result < 0) {
        avformat_close_input(&context);
        return false;
    }
    
    return true;
}

- (void)startReadLoop {
    __weak typeof(self) weakSelf = self;

    BOOL (^readThreadLoop)
    (void) = ^BOOL() {
      if (weakSelf == nil || weakSelf.readThread.isCancelled) {
          return false;
      }

      [weakSelf readNextData];

      return true;
    };
    
    self.readThread = [[NSThread alloc] initWithBlock:^{
      while (readThreadLoop()) {
          [NSThread sleepForTimeInterval:0.01];
      }
    }];
    [self.readThread setThreadPriority:1.0];
    [self.readThread start];
}

- (void)readNextData {
    AVPacket packet;
    
    int result = av_read_frame(context, &packet);
    
    if (result != 0) {
        NSLog(@"FFMPEGTest: error while reading next frame");
    }
}

@end
