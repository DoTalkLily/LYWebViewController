
#import <UIKit/UIKit.h>

typedef BOOL(^AWENavigationItemPopHandler)(UINavigationBar *navigationBar, UINavigationItem *navigationItem);

@protocol AWENavigationBackItemProtocol <NSObject>

@optional

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item;
@end

@interface UINavigationController (Injection)

@property(copy, nonatomic) AWENavigationItemPopHandler popHandler;

@end
