#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>

@interface ExtendedNFA_objc: NSObject

- (instancetype)init: (NSArray*) states initialState:(NSString*) initialState;
- (NSString*)getInitialState;
- (NSArray *) getStates;

@end

#endif /* Header_h */
