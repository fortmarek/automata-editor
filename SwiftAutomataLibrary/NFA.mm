#import <Foundation/Foundation.h>
#import "Transition.h"
#import "NFA.h"
#import "AutomatonRunResult.h"

#include "automaton/FSM/NFA.h"
#include "automaton/run/Accept.h"

@implementation NFA_objc {
    automaton::NFA<NSString*, NSString*>* automaton;
}
- (instancetype)init: (NSArray*) states inputAlphabet:(NSArray *) inputAlphabet initialState:(NSString*) initialState finalStates:(NSArray*) finalStates transitions: (NSArray *) transitions {
    self = [super init];
    auto statesSet = [self set: states];
    auto inputAlphabetSet = [self set: inputAlphabet];
    auto finalStatesSet = [self set: finalStates];
    automaton = new automaton::NFA(statesSet, inputAlphabetSet, initialState, finalStatesSet);

    [self setTransitions: transitions];

    return self;
}

- (void)dealloc {
    delete automaton;
}

- (bool)simulate: (NSArray *) input {
    ext::vector<NSString*> inputVector = [self vector: input];
    auto linearString = string::LinearString(automaton->getInputAlphabet(), inputVector);
    return automaton::run::Accept::accept(*automaton, linearString);
}

- (void)setTransitions: (NSArray *) transitions {
    for (Transition_objc * transition in transitions) {
        for (NSString * symbolString in transition.symbols) {
            automaton->addTransition(transition.fromState, symbolString, transition.toState);
        }
    }
}

- (ext::set<NSString *>)set: (NSArray*) array {
    std::vector<NSString*> vector = {};
    for (NSString * str in array) {
       vector.push_back(str);
    }
    return ext::set<NSString *>(ext::make_iterator_range(vector.begin(), vector.end()));
}

- (ext::vector<NSString *>)vector: (NSArray*) array {
    ext::vector<NSString*> vector = {};
    for (NSString * str in array) {
       vector.push_back(str);
    }
    return vector;
}

- (NSArray *) array: (ext::set<NSString *>) set {
    NSMutableArray * array = [NSMutableArray array];
    auto iterator = set.begin();
    while (iterator != set.end()) {
        [array addObject: *iterator];
        iterator++;
    }
    return array;
}

- (NSArray *) getFinalStates {
    return [self array: automaton->getFinalStates()];
}

- (NSArray *) getInputAlphabet {
    return [self array: automaton->getInputAlphabet()];
}

- (NSArray *) getStates {
    return [self array: automaton->getStates()];
}

- (NSString *)getInitialState {
    return automaton->getInitialState();
}

@end

template < >
struct ext::compare < NSString * > {

    /**
     * \brief
     * Implementation of the three-way comparison
     *
     * \param first the left operand of the comparison
     * \param second the right operand of the comparison
     *
     * \return negative value of left < right, positive value if left > right, zero if left == right
     */
    int operator ( ) ( NSString * first, NSString * second ) const {
        return [first intValue] - [second intValue];
    }
};
