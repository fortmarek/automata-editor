#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>

@interface NFA_objc: NSObject

- (instancetype)init: (NSArray *) states inputAlphabet:(NSArray *) inputAlphabet initialState:(NSString *) initialState finalStates:(NSArray *) finalStates transitions: (NSArray *) transitions;
- (NSString *) getInitialState;
- (NSArray *) getFinalStates;
- (NSArray *) getStates;
- (NSArray *) getInputAlphabet;

@end

#endif /* Header_h */
