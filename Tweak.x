#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Hook NSDictionary to intercept memberExTime when reading from plist
%hook NSDictionary

- (id)objectForKey:(id)key {
    id result = %orig;
    
    // If reading memberExTime, return a far-future date (year 2099)
    if ([key isKindOfClass:[NSString class]] && [(NSString *)key isEqualToString:@"memberExTime"]) {
        return [NSNumber numberWithDouble:4070908800.0];
    }
    
    return result;
}

%end

// Also hook NSUserDefaults in case they use that
%hook NSUserDefaults

- (id)objectForKey:(NSString *)key {
    if ([key isEqualToString:@"memberExTime"]) {
        return [NSNumber numberWithDouble:4070908800.0];
    }
    return %orig;
}

- (double)doubleForKey:(NSString *)key {
    if ([key isEqualToString:@"memberExTime"]) {
        return 4070908800.0;
    }
    return %orig;
}

%end

// Hook NSDate laterDate: comparison to always return the expiration date (not expired)
%hook NSDate

- (NSDate *)laterDate:(NSDate *)anotherDate {
    NSDate *result = %orig;
    
    // If comparing with a date far in future (membership check), return self
    if ([anotherDate timeIntervalSince1970] > 4000000000) {
        return anotherDate;
    }
    
    return result;
}

%end