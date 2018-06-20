//
//  MovModel.h
//  BeautyFace
//
//  Created by mac-vincent on 2017/4/19.
//  Copyright © 2017年 VincentJac. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface MovModel : NSObject
+ (void)writeToFileWithOriginMovPath:(NSURL *)originMovPath
                 TargetWriteFilePath:(NSURL *)finalMovPath
                     AssetIdentifier:(NSString *)assetIdentifier;
+ (void)cutVideo:(NSURL * )assetUrl toSavePath:(NSURL *)savePath WithFinished:(void (^)(NSURL *))finished;
+ (void)saveMovFilerToAlbum:(NSURL *)movUrl saveVideo:(void (^)(BOOL isSuccess))didSaveVideo;
+ (void)getVideoPath:(NSURL *)videoPath andTotalPath:(NSURL *)totalPath success:(void (^)(id responseObject))success fail:(void (^)())fail;
@end
