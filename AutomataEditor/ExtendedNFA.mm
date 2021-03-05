#import <Foundation/Foundation.h>
#import "ExtendedNFA.h"

#include "automaton/FSM/ExtendedNFA.h"

@implementation ExtendedNFA_objc {
    automaton::ExtendedNFA<NSString*, NSString*>* automaton;
}
- (instancetype)init: (NSArray*) states initialState:(NSString*) initialState {
    self = [super init];
    auto inputAlphabet = ext::set<NSString *>({@"A"});
    auto finalStates = ext::set<NSString *>({});
//    std::initializer_list<NSString*>(states);
//    int count = [states count];
//
//    for(int i=0; i<count; i++) {
//        array[i] = [[states objectAtIndex:i] stringValue];
//    }
//
    std::vector<NSString*> a = {};
    for (NSString * str in states) {
       a.push_back(str);
    }
    auto hello = ext::set<NSString *>(ext::make_iterator_range(a.begin(), a.end()));
    automaton = new automaton::ExtendedNFA(hello, inputAlphabet, initialState, finalStates);
    return self;
}

- (void)dealloc {
    delete automaton;
}

- (NSArray *) getStates {
    NSMutableArray * states = [NSMutableArray array];
    auto iterator = automaton->getStates().begin();
    while(iterator != automaton->getStates().end()) {
        [states addObject: *iterator];
        iterator++;
    }
    return states;
}

- (NSString *)getInitialState {
    return automaton->getInitialState();
}

@end
