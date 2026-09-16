#import <Foundation/Foundation.h>

// Hook NSDictionary to intercept memberExTime when reading from plist
%hook NSDictionary

- (id)objectForKey:(id)key {
    id result = %orig;
    
    // If reading memberExTime, return a far-future date (year 2099)
    if ([key isKindOfClass:[NSString class]] && [key isEqualToString:@"memberExTime"]) {
        // Return timestamp for Jan 1, 2099
        return @(4070908800.0);
    }
    
    return result;
}

%end

// Also hook NSUserDefaults in case they use that
%hook NSUserDefaults

- (id)objectForKey:(NSString *)key {
    if ([key isEqualToString:@"memberExTime"]) {
        return @(4070908800.0);
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
    // This makes the check think current date is NOT later than expiration
    if ([anotherDate timeIntervalSince1970] > 4000000000) {
        return anotherDate; // Return the far-future date, meaning "not expired"
    }
    
    return result;
}

%end
