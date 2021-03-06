#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>
#import "AutomatonRunResult.h"

@interface NFA_objc: NSObject

- (instancetype)init: (NSArray *) states
       inputAlphabet:(NSArray *) inputAlphabet
        initialState:(NSString *) initialState
         finalStates:(NSArray *) finalStates
         transitions: (NSArray *) transitions;
- (bool)simulate: (NSArray *) input;

@end

#endif /* Header_h */
