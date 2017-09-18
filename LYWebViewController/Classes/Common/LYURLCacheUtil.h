//
//  LYURLCache.h
//  Pods
//
//  Created by 01 on 17/9/12.
//
//

#import <Foundation/Foundation.h>

@interface LYURLCacheUtil : NSObject

+ (instancetype)sharedInstance;

- (CGFloat)getYPositionForURL:(NSString *)url;

- (void)insertURL:(NSString *)url yPosition:(CGFloat)yPosition;

@end
