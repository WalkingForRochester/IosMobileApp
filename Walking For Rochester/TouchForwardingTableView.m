//
//  TouchForwardingTableView.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/25/26.
//

#import "TouchForwardingTableView.h"

@implementation TouchForwardingTableView

- (BOOL)touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    // This could be better -- if the user wants the events and the tabel view doesn't, then keep track until the events end or are canceled and only forward them but don't call super. Will have to use introspection to determine if table view handles this or not.
    return [_touchForwardingDelegate touchForwardingTableView:self forwardedTouchesShouldBegin:touches withEvent:event inContentView:view];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [_touchForwardingDelegate touchForwardingTableView:self forwardedTouchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    [_touchForwardingDelegate touchForwardingTableView:self forwardedTouchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [_touchForwardingDelegate touchForwardingTableView:self forwardedTouchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [_touchForwardingDelegate touchForwardingTableView:self forwardedTouchesCancelled:touches withEvent:event];
}

@end
