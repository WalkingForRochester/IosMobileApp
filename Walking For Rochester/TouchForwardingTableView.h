//
//  TouchForwardingTableView.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/25/26.
//

#import <UIKit/UIKit.h>

@protocol TouchForwardingTableViewDelegate;

@interface TouchForwardingTableView : UITableView

@property (weak, nonatomic) IBOutlet id<TouchForwardingTableViewDelegate> touchForwardingDelegate;

@end

@protocol TouchForwardingTableViewDelegate

- (BOOL)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view;

- (void)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;

- (void)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;

- (void)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;

- (void)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;

@end
