#import <Foundation/Foundation.h>

// CAProMemberHandler is the cellmember pod singleton that tracks membership
@interface CAProMemberHandler : NSObject
+ (instancetype)sharedHandler;
+ (instancetype)sharedManager;
- (BOOL)isMember;
- (long long)memberExTime;
- (long long)memberExpireTime;
- (long long)expireTime;
- (NSString *)memberType;
- (NSInteger)status;
- (NSInteger)memberStatus;
- (NSInteger)isPro;
- (NSInteger)isVip;
- (NSInteger)featureFlag;
@end

// Hook the membership handler to always return active
%hook CAProMemberHandler
- (BOOL)isMember       { return YES; }
- (long long)memberExTime    { return 4070908800LL; }
- (long long)memberExpireTime { return 4070908800LL; }
- (long long)expireTime      { return 4070908800LL; }
- (NSString *)memberType     { return @"lifetime"; }
- (NSInteger)status          { return 1; }
- (NSInteger)memberStatus    { return 1; }
- (NSInteger)isPro           { return 1; }
- (NSInteger)isVip           { return 1; }
- (NSInteger)featureFlag     { return 255; }
%end
