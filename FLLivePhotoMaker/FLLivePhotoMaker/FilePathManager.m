//
//  FilePathManager.m
//  BeautyFace
//
//  Created by mac-vincent on 2017/4/19.
//  Copyright © 2017年 VincentJac. All rights reserved.
//

#import "FilePathManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>
@import Photos;

@implementation FilePathManager

+ (NSURL *)getDocumentPath {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSURL *)originJPGPath {
    NSURL * originJPGPath =[[self getDocumentPath] URLByAppendingPathComponent:@"OriginImage.jpg"];
    return originJPGPath;
}

+ (NSURL *)originMovPath {
    NSURL * originMovPath =[[self getDocumentPath] URLByAppendingPathComponent:@"OriginMov.mov"];
    return originMovPath;
}

+ (NSURL *)getJPGFinalPath {
    NSURL * saveJPGUrl = [[self getDocumentPath] URLByAppendingPathComponent:@"LivePhotoImage.jpg"];
    return saveJPGUrl;
}

+ (NSURL *)getMovFinalPath {
    NSURL * saveMovUrl = [[self getDocumentPath] URLByAppendingPathComponent:@"LivePhotoVideo.mov"];
    return saveMovUrl;
}

+ (NSURL *)getCropMovPath {
    NSURL * saveMovUrl = [[self getDocumentPath] URLByAppendingPathComponent:@"CropVideo.mov"];
    return saveMovUrl;

}

+ (NSString *)sizeOfDataFromUrl:(NSURL *)url {
    NSString * sizeStr = [NSString stringWithFormat:@"%.2lfMB",[NSData dataWithContentsOfURL:url].length/1024.f/1024.f];
    return sizeStr;
}

@end
