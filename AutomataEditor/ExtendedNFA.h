#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>

@interface ExtendedNFA_objc: NSObject

- (instancetype)init:(NSString*)initialState;
- (NSString*)getInitialState;

@end

#endif /* Header_h */
