//
//  FilePathManager.h
//  BeautyFace
//
//  Created by mac-vincent on 2017/4/19.
//  Copyright © 2017年 VincentJac. All rights reserved.
//

@import Foundation;

@interface FilePathManager : NSObject
+ (NSURL *)getDocumentPath;
+ (NSURL *)originJPGPath;
+ (NSURL *)originMovPath;
+ (NSURL *)getJPGFinalPath;
+ (NSURL *)getMovFinalPath;
+ (NSURL *)getCropMovPath;
+ (NSString *)sizeOfDataFromUrl:(NSURL *)url;

@end
