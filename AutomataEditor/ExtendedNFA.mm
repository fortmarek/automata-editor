#import <Foundation/Foundation.h>
#import "ExtendedNFA.h"

#include "automaton/FSM/ExtendedNFA.h"

@implementation ExtendedNFA_objc {
    automaton::ExtendedNFA<NSString*, NSString*>* automaton;
}
- (instancetype)init: (NSArray*) states inputAlphabet:(NSArray *) inputAlphabet initialState:(NSString*) initialState finalStates:(NSArray*) finalStates {
    self = [super init];
    auto statesSet = [self set: states];
    auto inputAlphabetSet = [self set: inputAlphabet];
    auto finalStatesSet = [self set: finalStates];
    automaton = new automaton::ExtendedNFA(statesSet, inputAlphabetSet, initialState, finalStatesSet);
    
    NSString * symbolString = inputAlphabet[0];
    auto symbol = regexp::FormalRegExpStructure<NSString*>(regexp::FormalRegExpSymbol(symbolString));
    regexp::UnboundedRegExpStructure<NSString*> structure = regexp::UnboundedRegExpStructure<NSString*>(symbol);
    automaton->addTransition(initialState, structure, (NSString *)finalStates[0]);
    
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
