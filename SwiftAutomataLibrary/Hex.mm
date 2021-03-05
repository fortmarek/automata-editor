#import "Hex.h"

#import <extensions/hexavigesimal.h>

@implementation Hex
- (NSString *)toBase26:(unsigned int)n {
    ext::toBase26(n);
    return @"1";
}
@end
