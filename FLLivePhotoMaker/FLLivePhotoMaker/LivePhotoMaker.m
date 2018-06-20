//
//  LivePhotoMaker.m
//  BeautyFace
//
//  Created by mac-vincent on 2017/4/13.
//  Copyright © 2017年 VincentJac. All rights reserved.
//

#import "LivePhotoMaker.h"
#import "MovModel.h"
#import "JPGModel.h"
#import "FilePathManager.h"

@import MobileCoreServices;
@import ImageIO;
@import Photos;


@implementation LivePhotoMaker


+ (void)makeLivePhotoByLibrary:(NSURL *)movUrl completed:(void (^)(NSDictionary * resultDic))didCreateLivePhoto {
    AVURLAsset *asset = [AVURLAsset assetWithURL:movUrl];

    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];

    generator.appliesPreferredTrackTransform = YES;
    [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2.f, asset.duration.timescale)]]
                                    completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                                        NSData * firstFrameData = UIImageJPEGRepresentation([UIImage imageWithCGImage:image],0.7);
                                        //save photo
                                        
                                        [firstFrameData writeToURL:[FilePathManager originJPGPath] atomically:YES];
                                        NSString *assetIdentifier = [[NSUUID UUID] UUIDString];
                                        [[NSFileManager defaultManager] createDirectoryAtPath:[FilePathManager getDocumentPath].path
                                                                  withIntermediateDirectories:YES
                                                                                   attributes:nil
                                                                                        error:&error];
                                        if (!error) {
                                            [[NSFileManager defaultManager] removeItemAtPath:[FilePathManager getJPGFinalPath].path
                                                                                       error:&error];
                                            
                                            [[NSFileManager defaultManager] removeItemAtPath:[FilePathManager getMovFinalPath].path
                                                                                       error:&error];   
                                        }
                                        
                                        [JPGModel writeToFileWithOriginJPGPath:[FilePathManager originJPGPath] TargetWriteFilePath:[FilePathManager getJPGFinalPath] AssetIdentifier:assetIdentifier];
                                       
                                        [MovModel writeToFileWithOriginMovPath:movUrl TargetWriteFilePath:[FilePathManager getMovFinalPath] AssetIdentifier:assetIdentifier];
                                        NSDictionary * dic = @{
                                                               @"MOVPath":[FilePathManager getMovFinalPath],
                                                               @"JPGPath":[FilePathManager getJPGFinalPath]
                                                               };
                                        didCreateLivePhoto(dic);
                                        
                               }];

                                        
                                       

}

+ (void)saveLivePhotoToAlbumWithMovPath:(NSURL *)movPath ImagePath:(NSURL *)jpgPath completed:(void (^)(BOOL isSuccess))didSaveLivePhoto {
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

+ (PHLivePhoto *)getLivePhotoFromMOVURL:(NSURL *)MOVURL {
    UIImage * image = [LivePhotoMaker firstFrame:MOVURL];
    
//    UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    NSURL *photoURL = [LivePhotoMaker grabFileURL:@"tempPhoto"];
    NSData *data = UIImagePNGRepresentation(image);
    [data writeToURL:photoURL atomically:YES];
    
    return [self convertLivePhotoFromVideoURL:MOVURL photoURL:photoURL];
}

+ (PHLivePhoto *)convertLivePhotoFromVideoURL:(NSURL *)videoURL photoURL:(NSURL *)photoURL {
    
    CGSize targetSize = CGSizeZero;
    PHImageContentMode contentMode = PHImageContentModeDefault;
    
    PHLivePhoto *livePhoto = [[PHLivePhoto alloc] init];
    SEL initWithImageURLvideoURL = NSSelectorFromString(@"_initWithImageURL:videoURL:targetSize:contentMode:");
    
    if ([livePhoto respondsToSelector:initWithImageURLvideoURL]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[livePhoto methodSignatureForSelector:initWithImageURLvideoURL]];
        [invocation setSelector:initWithImageURLvideoURL];
        [invocation setTarget:livePhoto];
        [invocation setArgument:&(photoURL) atIndex:2];
        [invocation setArgument:&(videoURL) atIndex:3];
        [invocation setArgument:&(targetSize) atIndex:4];
        [invocation setArgument:&(contentMode) atIndex:5];
        [invocation invoke];
    }
    
    [LivePhotoMaker saveLivePhotoAssetWithVideoURL:videoURL imageURL:photoURL];

    NSArray *resources = @[videoURL, photoURL];

    [PHLivePhoto requestLivePhotoWithResourceFileURLs:resources placeholderImage:nil targetSize:CGSizeZero contentMode:PHImageContentModeAspectFit resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nonnull info) {
        
        
    }];
    return livePhoto;
    
}

+ (void)saveLivePhotoAssetWithVideoURL:(NSURL *)videoURL imageURL:(NSURL *)imageURL {
    
    PHPhotoLibrary *library = [PHPhotoLibrary sharedPhotoLibrary];
    [library performChanges:^{
        // create the change request
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:videoURL options:nil];
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:nil];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        // did this work?
        if (!success) {
            NSLog(@"保存失败。%@\n",error);
            return;
        } else {
            NSLog(@"保存成功\n");
        }
        
        
    }];
}

+ (UIImage *)firstFrame:(NSURL *)videoURL {
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetImageGenerator* generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    UIImage* image = [UIImage imageWithCGImage:[generator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
    return image;
}

+ (NSURL*)grabFileURL:(NSString *)fileName {
    
    // find Documents directory
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    // append a file name to it
    documentsURL = [documentsURL URLByAppendingPathComponent:fileName];
    
    return documentsURL;
}

@end
