//
//  MSLazyImageView.h
//  MSLazyImageView
//
//  Created by Cory D. Wiles on 3/25/14.
//  Copyright (c) 2014 Cory Wiles. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const MSProgressViewCurrentProgressKeyPath;
extern NSString * const NSProgressFractionCompletedKeyPath;

/**
 * Simple UIImageView subclass that utilizes NSURLSession class to asychronously
 * fetch a remote image, while displaying a circular progress.
 */

@interface MSLazyImageView : UIImageView

/**
 * Remote image url
 */

@property (nonatomic, copy) NSString *imageURL;

@end
