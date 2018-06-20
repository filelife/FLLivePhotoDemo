//
//  LivePhotoMaker.h
//  BeautyFace
//
//  Created by mac-vincent on 2017/4/13.
//  Copyright © 2017年 VincentJac. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Photos;
@import PhotosUI;

/*
 *  With this class, you can have all you need to Create LivePhoto.
 */
@interface LivePhotoMaker : NSObject
/*
 * !!!!Action : This function use Apple's private method,so the Appstore won't pass it.
 */
+ (PHLivePhoto *)getLivePhotoFromMOVURL:(NSURL *)MOVURL;

/*
 * !!!!Action : This function use Apple's private method,so the Appstore won't pass it.
 */
+ (PHLivePhoto *)convertLivePhotoFromVideoURL:(NSURL *)videoURL photoURL:(NSURL *)photoURL;

/*
 * You can create a LivePhoto by MOV file with this function!
 */
+ (void)makeLivePhotoByLibrary:(NSURL *)movUrl completed:(void (^)(NSDictionary * resultDic))didCreateLivePhoto;

/*
 * For LivePhoto saving.
 */
+ (void)saveLivePhotoToAlbumWithMovPath:(NSURL *)movPath ImagePath:(NSURL *)jpgPath completed:(void (^)(BOOL isSuccess))didSaveLivePhoto;
@end
