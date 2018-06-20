//
//  JPGModel.h
//  BeautyFace
//
//  Created by mac-vincent on 2017/4/19.
//  Copyright © 2017年 VincentJac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface JPGModel : NSObject

+ (void)writeToFileWithOriginJPGPath:(NSURL *)originJPGPath
                 TargetWriteFilePath:(NSURL *)finalJPGPath
                     AssetIdentifier:(NSString *)assetIdentifier;

+ (UIImage *) convertSampleBufferToImageWithBuffer:(CMSampleBufferRef)sampleBuffer;
+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef)bufferRef;
@end
