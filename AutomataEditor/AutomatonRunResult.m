//
//  AutomatonRunResult.m
//  AutomataEditor
//
//  Created by Marek Fořt on 05.03.2021.
//

#import <Foundation/Foundation.h>
#include "AutomatonRunResult.h"

@implementation AutomatonRunResult

- (instancetype)initWithSucceeded: (bool)succeeded endStates:(NSArray *)endStates {
    self = [super init];
    self->_succeeded = succeeded;
    self->_endStates = endStates;
    return self;
}
@end
