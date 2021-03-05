//
//  AutomatonRunResult.h
//  AutomataEditor
//
//  Created by Marek Fořt on 05.03.2021.
//

#ifndef AutomatonRunResult_h
#define AutomatonRunResult_h

@interface AutomatonRunResult: NSObject

- (instancetype)initWithSucceeded: (bool)succeeded endStates:(NSArray *)endStates;
@property (nonatomic, assign, readonly) bool succeeded;
@property (nonatomic, retain, readonly) NSArray* endStates;

@end

#endif /* AutomatonRunResult_h */
