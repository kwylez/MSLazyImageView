## MSLazyImageView

Simple UIImageView subclass that utilizes `NSURLSession` and `NSProgress` class to asychronously fetch a remote image, while displaying a circular progress.

### Requirements

* iOS7+

### Installation

Copy `MSLazyImageView.h/.m` classes to your project

### Usage

```objectivec

- (void)viewDidLoad {

  [super viewDidLoad];
  
  NSString *urlString = @"http://emmamidori.files.wordpress.com/2012/06/montreal-view-pierre-dupuy-morning-darina-velkova-2012-s.jpg";
  
  self.imageView = [[MSLazyImageView alloc] initWithFrame:CGRectMake(20, 100, 200, 200)];
  
  [self.view addSubview:self.imageView];
  
  self.imageView.imageURL = urlString;
}

```

![alt text](https://github.com/kwylez/MSLazyImageView/raw/master/Assets/example.gif "MSLazyImageView Example")

### Customizations

You can set the `progressViewStrokeColor`, `progressViewTintColor` and `progressViewFillColor` colors via [UIAppearance](https://developer.apple.com/library/ios/documentation/uikit/reference/UIAppearance_Protocol/Reference/Reference.html)