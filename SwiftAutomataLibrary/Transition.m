#import <Foundation/Foundation.h>

#include "Transition.h"

@implementation Transition_objc

-(instancetype)init: (NSString *) fromState toState:(NSString *) toState symbols:(NSArray *) symbols isEpsilonIncluded:(bool) isEpsilonIncluded {
    self = [super init];
    self->_fromState = fromState;
    self->_toState = toState;
    self->_symbols = symbols;
    self->_isEpsilonIncluded = isEpsilonIncluded;
    return self;
}

@end
