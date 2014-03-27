//
//  MSLazyImageView.m
//  MSLazyImageView
//
//  Created by Cory D. Wiles on 3/25/14.
//  Copyright (c) 2014 Cory Wiles. All rights reserved.
//

#import "MSLazyImageView.h"
#import <CommonCrypto/CommonDigest.h>

static void *imageDownloadProgressContext = &imageDownloadProgressContext;
static void *progressViewContext          = &progressViewContext;

NSString * const MSProgressViewCurrentProgressKeyPath = @"currentProgress";
NSString * const NSProgressFractionCompletedKeyPath   = @"fractionCompleted";

/**
 * Overlay on the UIImageView which will animate as the image is downloaded.
 */

@interface MSProgressView : UIView

/**
 * Current progress of the download
 */

@property (nonatomic, assign) CGFloat currentProgress;

/**
 * Stroke color of the animated view. Supports UIAppearance
 *
 * Defaults to white
 */

@property (nonatomic, strong) UIColor *progressViewStrokeColor UI_APPEARANCE_SELECTOR;

/**
 * Tint color of the animated view. Supports UIAppearance
 *
 * Defaults to black
 */

@property (nonatomic, strong) UIColor *progressViewTintColor UI_APPEARANCE_SELECTOR;

/**
 * FIll color of the animated view. Supports UIAppearance
 *
 * Defaults to white
 */

@property (nonatomic, strong) UIColor *progressViewFillColor UI_APPEARANCE_SELECTOR;

@end

@implementation MSProgressView

- (void)dealloc {

  [self removeObserver:self
            forKeyPath:MSProgressViewCurrentProgressKeyPath
               context:progressViewContext];
}

- (id)initWithFrame:(CGRect)frame {

  self = [super initWithFrame:frame];
  
  if (self) {
    
    self.backgroundColor = [UIColor clearColor];
		self.opaque          = NO;

    _currentProgress         = 0.0f;
    _progressViewFillColor   = [UIColor whiteColor];
    _progressViewTintColor   = [UIColor blackColor];
    _progressViewStrokeColor = [UIColor whiteColor];
    
    [self addObserver:self
           forKeyPath:MSProgressViewCurrentProgressKeyPath
              options:NSKeyValueObservingOptionNew
              context:progressViewContext];
  }
  
  return self;
}

- (void)drawRect:(CGRect)rect {

  CGColorRef backgroundTintColor = self.progressViewTintColor.CGColor;
  CGColorRef progressTintColor   = self.progressViewFillColor.CGColor;
  CGColorRef strokeTintColor     = self.progressViewStrokeColor.CGColor;
  
  CGRect frame = self.bounds;
	CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGColorRef colorBackAlpha     = CGColorCreateCopyWithAlpha(backgroundTintColor, 0.05f);
  CGColorRef colorProgressAlpha = CGColorCreateCopyWithAlpha(progressTintColor, 0.2f);

  CGRect circleRect = CGRectMake(frame.origin.x + 2, frame.origin.y + 2, frame.size.width - 4, frame.size.height - 4);
  CGFloat x         = frame.origin.x + (frame.size.width / 2);
  CGFloat y         = frame.origin.y + (frame.size.height / 2);
  CGFloat angle     = (self.currentProgress) * 360.0f;
  
  CGContextSaveGState(context);
  CGContextSetStrokeColorWithColor(context, colorProgressAlpha);
  CGContextSetFillColorWithColor(context, colorBackAlpha);
  CGContextSetLineWidth(context, 2.0);
  CGContextFillEllipseInRect(context, circleRect);
  CGContextStrokeEllipseInRect(context, circleRect);
  
  CGContextSetRGBFillColor(context, 1.0, 0.0, 1.0, 1.0);
  CGContextMoveToPoint(context, x, y);
  CGContextAddArc(context, x, y, (frame.size.width + 4) / 2, -M_PI / 2, (angle * M_PI) / 180.0f - M_PI / 2, 0);
  CGContextClip(context);
  
  CGContextSetStrokeColorWithColor(context, strokeTintColor);
  CGContextSetFillColorWithColor(context, progressTintColor);
  CGContextSetLineWidth(context, 2.0);
  CGContextFillEllipseInRect(context, circleRect);
  CGContextStrokeEllipseInRect(context, circleRect);
  CGContextRestoreGState(context);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  
  if (context == progressViewContext) {
    
    [self setNeedsDisplay];
    
  } else {
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

@end

@interface MSLazyImageView ()<NSURLSessionDownloadDelegate>

/**
 * NSURLSession for managing the download
 */

@property (nonatomic, strong) NSURLSession *session;

/**
 * Manages the progress state of the image downlad
 */

@property (nonatomic, strong) NSProgress *progress;

/**
 * Progress view instance
 */

@property (nonatomic, strong) MSProgressView *progressView;

/**
 * The operation queue where the NSURLSession delegate methods are called on
 */

@property (nonatomic, strong) NSOperationQueue *backgroundImageProcessingQueue;

- (UIImage *)processImageData:(NSData *)originalImageData;
- (void)commonSetup;

@end

@implementation MSLazyImageView

@synthesize imageURL = _imageURL;
@synthesize session  = _session;

- (id)initWithFrame:(CGRect)frame {

  self = [super initWithFrame:frame];
  
  if (self) {
    
    [self commonSetup];
  }
  
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{

  self = [super initWithCoder:aDecoder];
  
  if (self) {
    [self commonSetup];
  }
  
  return self;
}

- (id)initWithImage:(UIImage *)image{

  self = [super initWithImage:image];
  
  if (self) {
    [self commonSetup];
  }
  
  return self;
}

- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage{

  self = [super initWithImage:image highlightedImage:image];
  
  if (self) {
    [self commonSetup];
  }
  
  return self;
}

- (void)layoutSubviews {

  [super layoutSubviews];

  CGRect frame = self.bounds;
  
  self.progressView.frame = (CGRect){CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame)};
}

#pragma mark - Accessors

- (void)setImageURL:(NSString *)imageURL {
  
  _imageURL = [imageURL copy];
  
  NSURL *imageDownloadURL = [NSURL URLWithString:imageURL];
  
  NSURLSessionDownloadTask *getImageTask = [self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:imageDownloadURL]];
  
  [getImageTask resume];
}

- (NSURLSession *)session {

  if (!_session) {

    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    sessionConfig.timeoutIntervalForRequest     = 10.0;
    sessionConfig.timeoutIntervalForResource    = 30.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    _session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:self.backgroundImageProcessingQueue];
  }

  return _session;
}

#pragma mark - Session Delegates

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
  NSLog(@"I'm finished. Did it error? %@", error);
}

/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
 */

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
  
  NSLog(@"location and downloadTask - %@ %@", location, downloadTask);
  
  __weak typeof(self) weakSelf = self;
  
  NSData *imageData          = [NSData dataWithContentsOfURL:location];
  UIImage *decompressedImage = [self processImageData:imageData];
  
  /**
   * Since the delegates are called on custom queue then we must post the 
   * UI updates on the main thread
   */

  dispatch_async(dispatch_get_main_queue(), ^{
  
    weakSelf.image = decompressedImage;
    
    [weakSelf.progress removeObserver:self
                           forKeyPath:NSProgressFractionCompletedKeyPath
                              context:imageDownloadProgressContext];
    
    weakSelf.progress = nil;
  });
}

/* Sent periodically to notify the delegate of download progress. */

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

  NSLog(@"bytesWritten %lld totalBytesWritten %lld totalBytesExpectedToWrite %lld",
        bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
  
  __weak typeof(self) weakSelf = self;
  
  dispatch_async(dispatch_get_main_queue(), ^{
  
    if (!weakSelf.progress) {
      
      weakSelf.progress      = [NSProgress progressWithTotalUnitCount:totalBytesExpectedToWrite];
      weakSelf.progress.kind = NSProgressKindFile;
      
      [weakSelf.progress addObserver:self
                          forKeyPath:NSProgressFractionCompletedKeyPath
                             options:kNilOptions
                             context:imageDownloadProgressContext];
    }
    
    weakSelf.progress.completedUnitCount = totalBytesWritten;
  });
}

/* Sent when a download has been resumed. If a download failed with an
 * error, the -userInfo dictionary of the error will contain an
 * NSURLSessionDownloadTaskResumeData key, whose value is the resume
 * data.
 */

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {

  NSLog(@"required delegate method");
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

  if (context == imageDownloadProgressContext) {

    NSString *currentProgress = [NSString stringWithFormat:@"%lld of %lld completed", [self.progress completedUnitCount], [self.progress totalUnitCount]];
    
    NSLog(@"currentProgress: %@", currentProgress);

    self.progressView.currentProgress = (CGFloat)_progress.fractionCompleted;
    
    if (self.progress.completedUnitCount == self.progress.totalUnitCount) {
      
      [UIView animateWithDuration:0.4f animations:^{
        self.progressView.alpha = 0.0f;
      }];
    }

  } else {
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - Private Methods

- (UIImage *)processImageData:(NSData *)originalImageData {

  UIImage *downloadedImage = [UIImage imageWithData:originalImageData scale:[UIScreen mainScreen].scale];
  
  return downloadedImage;
}

- (void)commonSetup {

  _progressView = [[MSProgressView alloc] initWithFrame:CGRectZero];
  
  [self addSubview:_progressView];
  
  _backgroundImageProcessingQueue = [[NSOperationQueue alloc] init];
  
  _backgroundImageProcessingQueue.name                        = @"com.macspots.lazyimage.queue";
  _backgroundImageProcessingQueue.maxConcurrentOperationCount = 1;
}

@end
