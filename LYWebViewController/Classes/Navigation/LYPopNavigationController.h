
#import <UIKit/UIKit.h>

typedef BOOL(^LYNavigationItemPopHandler)(UINavigationBar *navigationBar, UINavigationItem *navigationItem);

@protocol LYNavigationBackItemProtocol <NSObject>

@optional

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item;
@end

@interface UINavigationController (Injection)

@property(copy, nonatomic) LYNavigationItemPopHandler popHandler;

@end
