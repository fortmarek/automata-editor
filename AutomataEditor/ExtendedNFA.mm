#import <Foundation/Foundation.h>
#import "ExtendedNFA.h"

#include "automaton/FSM/ExtendedNFA.h"

@implementation ExtendedNFA_objc {
    automaton::ExtendedNFA<NSString*, NSString*>* automaton;
}
- (instancetype)init: (NSArray*) states initialState:(NSString*) initialState finalStates:(NSArray*) finalStates {
    self = [super init];
    auto inputAlphabet = ext::set<NSString *>({@"A"});

    auto statesSet = [self set: states];
    auto finalStatesSet = [self set: finalStates];
    automaton = new automaton::ExtendedNFA(statesSet, inputAlphabet, initialState, finalStatesSet);
    return self;
}

- (void)dealloc {
    delete automaton;
}

- (ext::set<NSString *>)set: (NSArray*) array {
    std::vector<NSString*> vector = {};
    for (NSString * str in array) {
       vector.push_back(str);
    }
    return ext::set<NSString *>(ext::make_iterator_range(vector.begin(), vector.end()));
}

- (NSArray *) array: (ext::set<NSString *>) set {
    NSMutableArray * array = [NSMutableArray array];
    auto iterator = set.begin();
    while (iterator != automaton-set.end()) {
        [array addObject: *iterator];
        iterator++;
    }
    return array;
}

- (NSArray *) getStates {
    return [self array: automaton->getStates()];
}

- (NSString *)getInitialState {
    return automaton->getInitialState();
}

@end
