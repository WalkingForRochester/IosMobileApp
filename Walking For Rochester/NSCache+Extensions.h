//
//  NSCache+Extensions.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/29/26.
//

#import <Foundation/Foundation.h>

@interface NSCache (Extensions)

- (id)objectForKeyedSubscript:(id)key;

- (void)setObject:(id)obj forKeyedSubscript:(id)key;

@end
