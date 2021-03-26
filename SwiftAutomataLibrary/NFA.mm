#import <Foundation/Foundation.h>
#import "Transition.h"
#import "NFA.h"
#import "AutomatonRunResult.h"

#include "automaton/FSM/EpsilonNFA.h"
#include "automaton/run/Accept.h"

@implementation NFA_objc {
    automaton::EpsilonNFA<std::string, std::string>* automaton;
}
- (instancetype)init: (NSArray*) states inputAlphabet:(NSArray *) inputAlphabet initialState:(NSString*) initialState finalStates:(NSArray*) finalStates transitions: (NSArray *) transitions {
    self = [super init];
    auto statesSet = [self set: states];
    auto inputAlphabetSet = [self set: inputAlphabet];
    auto finalStatesSet = [self set: finalStates];
    automaton = new automaton::EpsilonNFA(statesSet, inputAlphabetSet, [self stdString: initialState], finalStatesSet);

    [self setTransitions: transitions];

    return self;
}

- (void)dealloc {
    delete automaton;
}

- (std::string)stdString: (NSString *) string {
    return std::string([string UTF8String]);
}

- (bool)simulate: (NSArray *) input {
    ext::vector<std::string> inputVector = [self vector: input];
    auto linearString = string::LinearString(automaton->getInputAlphabet(), inputVector);
    
    std::cout << *automaton << std::endl;
    
    return automaton::run::Accept::accept(*automaton, linearString);
}

- (void)setTransitions: (NSArray *) transitions {
    for (Transition_objc * transition in transitions) {
        for (NSString * symbolString in transition.symbols) {
            automaton->addTransition([self stdString: transition.fromState], [self stdString: symbolString], [self stdString: transition.toState]);
        }
        
        if (transition.isEpsilonIncluded) {
            automaton->addTransition([self stdString: transition.fromState], common::symbol_or_epsilon<std::string>(), [self stdString: transition.toState]);
        }
    }
}

- (ext::set<std::string>)set: (NSArray*) array {
    std::vector<std::string> vector = {};
    for (NSString * str in array) {
       vector.push_back([self stdString: str]);
    }
    return ext::set<std::string>(ext::make_iterator_range(vector.begin(), vector.end()));
}

- (ext::vector<std::string>)vector: (NSArray*) array {
    ext::vector<std::string> vector = {};
    for (NSString * str in array) {
       vector.push_back([self stdString: str]);
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
