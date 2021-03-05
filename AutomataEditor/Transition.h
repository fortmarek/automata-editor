#ifndef Transition_h
#define Transition_h

#import <Foundation/Foundation.h>

@interface Transition_objc: NSObject

-(instancetype)init: (NSString *) fromState toState:(NSString *) toState symbols:(NSArray *) symbols;
@property (nonatomic, retain, readonly) NSString* fromState;
@property (nonatomic, retain, readonly) NSString* toState;
@property (nonatomic, retain, readonly) NSArray* symbols;

@end

#endif /* Transition_h */
