#import <Foundation/Foundation.h>
#import "ExtendedNFA.h"

#include "automaton/FSM/ExtendedNFA.h"

@implementation ExtendedNFA_objc {
    automaton::ExtendedNFA<NSString*, NSString*>* automaton;
}
- (instancetype)init {
    auto states = ext::set<NSString *>({@"1"});
    auto inputAlphabet = ext::set<NSString *>({@"A"});
    NSString * initialState = @"1";
    auto finalStates = ext::set<NSString *>({@"1"});
    automaton = new automaton::ExtendedNFA(states, inputAlphabet, initialState, finalStates);
    self = [super init];
    return self;
}

- (void)dealloc {
    NSLog(@"dealloc!");
    delete automaton;
}

- (NSString *)getInitialState {
    return automaton->getInitialState();
}

@end
