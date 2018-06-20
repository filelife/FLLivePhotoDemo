//
//  ViewController.m
//  FLLivePhotoMaker
//
//  Created by mac-vincent on 2017/8/14.
//  Copyright © 2017年 Filelife. All rights reserved.
//

#import "ViewController.h"
#import "LivePhotoMaker.h"
@interface ViewController ()
@property (nonatomic, weak) IBOutlet UILabel * resLab;
@property (nonatomic, assign) BOOL isSaving;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isSaving = NO;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveLivePhoto:(id)sender {
    if(self.isSaving == YES) {
        return;
    }
    self.isSaving = YES;
    NSURL * videoUrl=  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mov"]];
    self.resLab.text = @"保存中...";
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
}

@end
