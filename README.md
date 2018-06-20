# FLLivePhotoDemo
## FLLivePhotoDemo使用简介
LivePhotoMaker文件中提供了LivePhoto的多种合成方法，可以通过导图+视频，也可以仅仅使用视频来生产LivePhoto。
```

/*
 * You can create a LivePhoto by MOV file with this function!
 */
+ (void)makeLivePhotoByLibrary:(NSURL *)movUrl completed:(void (^)(NSDictionary * resultDic))didCreateLivePhoto;

/*
 * For LivePhoto saving.
 */
+ (void)saveLivePhotoToAlbumWithMovPath:(NSURL *)movPath ImagePath:(NSURL *)jpgPath completed:(void (^)(BOOL isSuccess))didSaveLivePhoto;
```
Demo代码示例：
```
    NSURL * videoUrl=  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mov"]];
    [LivePhotoMaker makeLivePhotoByLibrary:videoUrl completed:^(NSDictionary * resultDic) {
        if(resultDic) {
            NSURL * videoUrl = resultDic[@"MOVPath"];
            NSURL * imageUrl = resultDic[@"JPGPath"];
            [LivePhotoMaker saveLivePhotoToAlbumWithMovPath:videoUrl ImagePath:imageUrl completed:^(BOOL isSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isSaving = NO;
                    if(isSuccess) {
                        self.resLab.text = @"保存成功，请打开相册查看。";
                    } else {
                        self.resLab.text = @"保存失败，可能是权限问题，请开启权限后重试。";
                    }
                });
            }];
        }
    }];
```

## Live Photo开发原理
#### LivePhoto简介
Live Photo是由一段3秒的视频+一张图片构成的。

原生LivePhoto视频采集的时间区间是由按键后1.5s+按键前1.5s构成的。
```
[-1.5s ~ 0s, 拍摄瞬间,0s ~ 1.5s]。
```
最后合成Livephoto展示的照片，取得是相机采集后3s片段中的中央那一帧。

#### 合成须知
##### 物料：
1.视频；
2.被处理过的图片；
长话短说就是，假如你有一段视频，一张图，很简单就能产出一个LivePhoto。
接下来，在我们已经拥有图片和视频的前提之下，我们开始对他们进行处理。所谓处理就是，其实iOS的LivePhoto图片和视频之间，要有一个简单的联系，以确保他们两者可以被iOS识别为Livephoto。
#### 1.处理图片
我们所需要处理图片的MetaData，其中重要的Key值就是：
```
NSString *const kFigAppleMakerNote_AssetIdentifier = @"17";
```
以下是对这个“17” 的MetaData的写入方法，在之后保存的finalJPGPath，就可以用来存储LivePhoto了。
```
NSString *const kKeySpaceQuickTimeMetadata = @"mdta";
+ (AVAssetWriterInputMetadataAdaptor *)metadataSetAdapter {
    NSString *identifier = [kKeySpaceQuickTimeMetadata stringByAppendingFormat:@"/%@",kKeyStillImageTime];
    const NSDictionary *spec = @{(__bridge_transfer  NSString*)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier :
                                     identifier,
                                 (__bridge_transfer  NSString*)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType :
                                     @"com.apple.metadata.datatype.int8"
                                 };
    CMFormatDescriptionRef desc;
    CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, (__bridge CFArrayRef)@[spec], &desc);
    AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata outputSettings:nil sourceFormatHint:desc];
    CFRelease(desc);
    return [AVAssetWriterInputMetadataAdaptor assetWriterInputMetadataAdaptorWithAssetWriterInput:input];

}
```
```
- (void)writeToFileWithOriginJPGPath:(NSURL *)originJPGPath
                 TargetWriteFilePath:(NSURL *)finalJPGPath
                     AssetIdentifier:(NSString *)assetIdentifier {
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)finalJPGPath, kUTTypeJPEG, 1, nil);
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)[NSData dataWithContentsOfFile:originJPGPath.path], nil);
    NSMutableDictionary *metaData = [(__bridge_transfer  NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil) mutableCopy];
    
    NSMutableDictionary *makerNote = [NSMutableDictionary dictionary];
    [makerNote setValue:assetIdentifier forKey:kFigAppleMakerNote_AssetIdentifier];
    [metaData setValue:makerNote forKey:(__bridge_transfer  NSString*)kCGImagePropertyMakerAppleDictionary];
    CGImageDestinationAddImageFromSource(dest, imageSourceRef, 0, (CFDictionaryRef)metaData);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
}
```
以上操作之后，我们获取到了图片。

#### 2.处理视频
使用以下方法处理视频，让他和图片能够绑定
```
+ (void)writeToFileWithOriginMovPath:(NSURL *)originMovPath
                 TargetWriteFilePath:(NSURL *)finalMovPath
                     AssetIdentifier:(NSString *)assetIdentifier {
    
    AVURLAsset* asset = [AVURLAsset assetWithURL:originMovPath];
    
    
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    
    if (!videoTrack) {
        return;
    }
    
    AVAssetReaderOutput *videoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:@{(__bridge_transfer  NSString*)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]}];

    NSDictionary *audioDic = @{AVFormatIDKey :@(kAudioFormatLinearPCM),
                               AVLinearPCMIsBigEndianKey:@NO,
                               AVLinearPCMIsFloatKey:@NO,
                               AVLinearPCMBitDepthKey :@(16)
                               };
    
    AVAssetReaderTrackOutput *audioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:audioDic];
    NSError *error;
    
    
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if([reader canAddOutput:videoOutput]) {
        [reader addOutput:videoOutput];
    } else {
        NSLog(@"Add video output error\n");
    }
    
    if([reader canAddOutput:audioOutput]) {
        [reader addOutput:audioOutput];
    } else {
        NSLog(@"Add audio output error\n");
    }

    
    NSDictionary * outputSetting = @{AVVideoCodecKey: AVVideoCodecH264,
                                     AVVideoWidthKey: [NSNumber numberWithFloat:videoTrack.naturalSize.width],
                                     AVVideoHeightKey: [NSNumber numberWithFloat:videoTrack.naturalSize.height]
                                     };
    
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSetting];
    videoInput.expectsMediaDataInRealTime = true;
    videoInput.transform = videoTrack.preferredTransform;
    
    NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                   [ NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                   [ NSNumber numberWithFloat: 44100], AVSampleRateKey,
                                   [ NSNumber numberWithInt: 128000], AVEncoderBitRateKey,
                                   nil];
    
    AVAssetWriterInput *audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:[audioTrack mediaType] outputSettings:audioSettings];
    audioInput.expectsMediaDataInRealTime = true;
    audioInput.transform = audioTrack.preferredTransform;
    
    NSError *error_two;
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:finalMovPath fileType:AVFileTypeQuickTimeMovie error:&error_two];
    if(error_two) {
        NSLog(@"CreateWriterError:%@\n",error_two);
    }
    writer.metadata = @[ [self metaDataSet:assetIdentifier]];
    [writer addInput:videoInput];
    [writer addInput:audioInput];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
                                                           kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    AVAssetWriterInputMetadataAdaptor *adapter = [self metadataSetAdapter];
    [writer addInput:adapter.assetWriterInput];
    [writer startWriting];
    [reader startReading];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    
    CMTimeRange dummyTimeRange = CMTimeRangeMake(CMTimeMake(0, 1000), CMTimeMake(200, 3000));
    //Meta data reset:
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.key = kKeyStillImageTime;
    item.keySpace = kKeySpaceQuickTimeMetadata;
    item.value = [NSNumber numberWithInt:0];
    item.dataType = @"com.apple.metadata.datatype.int8";
    [adapter appendTimedMetadataGroup:[[AVTimedMetadataGroup alloc] initWithItems:[NSArray arrayWithObject:item] timeRange:dummyTimeRange]];
    
    
    dispatch_queue_t createMovQueue = dispatch_queue_create("createMovQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(createMovQueue, ^{
        while (reader.status == AVAssetReaderStatusReading) {
            CMSampleBufferRef videoBuffer = [videoOutput copyNextSampleBuffer];
            CMSampleBufferRef audioBuffer = [audioOutput copyNextSampleBuffer];
            if (videoBuffer) {
                while (!videoInput.isReadyForMoreMediaData || !audioInput.isReadyForMoreMediaData) {
                    usleep(1);
                }
                if (audioBuffer) {
                    [audioInput appendSampleBuffer:audioBuffer];
                    CFRelease(audioBuffer);
                }
//                //裁剪后：
//                CMTime startTime = CMSampleBufferGetPresentationTimeStamp(videoBuffer);
//                CVPixelBufferRef pixBufferRef = [self cropSampleBuffer:videoBuffer inRect:CGRectMake(0, 0, 720, 720)];
//                [adaptor appendPixelBuffer:pixBufferRef withPresentationTime:startTime];
//                
//                CVPixelBufferRelease(pixBufferRef);
//                CMSampleBufferInvalidate(videoBuffer);
//
//                videoBuffer = nil;
                
                //不剪切：
                [adaptor.assetWriterInput appendSampleBuffer:videoBuffer];
                CMSampleBufferInvalidate(videoBuffer);
                CFRelease(videoBuffer);
                videoBuffer = nil;

            } else {
                continue;
            }
            // NULL?
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [writer finishWritingWithCompletionHandler:^{
                NSLog(@"Finish \n");
                
            }];
        });
    });
    
    
    while (writer.status == AVAssetWriterStatusWriting) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }

}

+ (AVMetadataItem *)metaDataSet:(NSString *)assetIdentifier {
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.key = kKeyContentIdentifier;
    item.keySpace = kKeySpaceQuickTimeMetadata;
    item.value = assetIdentifier;
    item.dataType = @"com.apple.metadata.datatype.UTF-8";
    return item;
}

```


#### 3.合成
通过以上方法，我们处理好了视频以及封面图片，接下来，我们使用PHPhotoLibrary即可直接保存写入一张LivePhoto。
我提供以下方法来存储LivePhoto，并且可以获取保存到相册后的回调。
```
- (void)saveLivePhotoToAlbumWithMovPath:(NSURL *)movPath ImagePath:(NSURL *)jpgPath completed:(void (^)(BOOL isSuccess))didSaveLivePhoto {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
        [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:movPath options:options];
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:jpgPath options:options];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if(success) {
            NSLog(@"Save success\n");
            didSaveLivePhoto(YES);
        } else {
            didSaveLivePhoto(NO);
        }
    }];

}
```
希望看了觉得有用的，可以点个赞哈。因为我懒，其实我有写了一个Demo的，但是和一个完整项目代码还放一起还没来得及合理封装，等我弄好了再传到Github╮(╯▽╰)╭  
![](http://upload-images.jianshu.io/upload_images/1647887-e32ce5e05661e4f4.gif?imageMogr2/auto-orient/strip)

补充：
好吧，其实你如果已经录制好一段视频了，那么我再补一个方法帮助你获得视频其中一帧的图片吧。
```
- (UIImage *)firstFrame:(NSURL *)videoURL {
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetImageGenerator* generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    UIImage* image = [UIImage imageWithCGImage:[generator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
    return image;
}
```
