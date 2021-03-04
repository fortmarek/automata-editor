#import <Foundation/Foundation.h>
#import "ExtendedNFA.h"

#include "automaton/FSM/ExtendedNFA.h"

@implementation ExtendedNFA_objc {
    automaton::ExtendedNFA<NSString*, NSString*>* automaton;
}
- (instancetype)init:(NSString*)initialState {
    self = [super init];
    auto states = ext::set<NSString *>({@"1", initialState});
    auto inputAlphabet = ext::set<NSString *>({@"A"});
    auto finalStates = ext::set<NSString *>({@"1"});
    automaton = new automaton::ExtendedNFA(states, inputAlphabet, initialState, finalStates);
    return self;
}

- (void)dealloc {
    delete automaton;
}

- (NSString *)getInitialState {
    return automaton->getInitialState();
}

@end
