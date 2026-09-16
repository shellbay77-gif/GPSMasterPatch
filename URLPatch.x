#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

static NSString *const kHandledKey = @"GPSURLHandled";
static NSString *const kNewHost    = @"v.fembabe.org";

// All known membership UserDefaults keys from CAResponseData / cellmember pod
static NSArray *memberIntKeys(void) {
    return @[@"isMember", @"isPro", @"isVip", @"status", @"memberStatus",
             @"ca_isMember", @"ca_isPro", @"ca_memberStatus",
             @"kIsMember", @"kMemberStatus", @"GGisMember", @"GGmemberStatus"];
}
static NSArray *memberTimeKeys(void) {
    return @[@"memberExTime", @"memberExpireTime", @"expireTime",
             @"ca_memberExTime", @"ca_expireTime", @"kMemberExpireTime",
             @"GGmemberExTime", @"GGexpireTime"];
}
static NSArray *memberStringKeys(void) {
    return @[@"memberType", @"type", @"ca_memberType", @"kMemberType", @"GGmemberType"];
}

static void injectMembershipDefaults(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSInteger exTime = 4070908800LL; // 2099-01-01
    for (NSString *k in memberIntKeys())    [ud setInteger:1        forKey:k];
    for (NSString *k in memberTimeKeys())   [ud setInteger:exTime   forKey:k];
    for (NSString *k in memberStringKeys()) [ud setObject:@"lifetime" forKey:k];
    [ud synchronize];
}

static BOOL isDeadHost(NSString *host) {
    return [host hasSuffix:@"cellapp.cn"] || [host hasSuffix:@"hotbrainapp.com"];
}

@interface GPSURLRedirectProtocol : NSURLProtocol <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *innerSession;
@end

@implementation GPSURLRedirectProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:kHandledKey inRequest:request]) return NO;
    return isDeadHost(request.URL.host);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *req = [self.request mutableCopy];
    NSURLComponents *comp = [NSURLComponents componentsWithURL:req.URL resolvingAgainstBaseURL:NO];
    comp.host = kNewHost;
    req.URL = comp.URL;
    [NSURLProtocol setProperty:@YES forKey:kHandledKey inRequest:req];

    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    // Don't include custom protocols to avoid recursion
    cfg.protocolClasses = @[];
    self.innerSession = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:nil];
    [[self.innerSession dataTaskWithRequest:req] resume];
}

- (void)stopLoading {
    [self.innerSession invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) [self.client URLProtocol:self didFailWithError:error];
    else [self.client URLProtocolDidFinishLoading:self];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
     completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if ([challenge.protectionSpace.host isEqualToString:kNewHost]) {
        completionHandler(NSURLSessionAuthChallengeUseCredential,
                         [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end

// Inject our protocol into EVERY session configuration the app creates
%hook NSURLSessionConfiguration

+ (NSURLSessionConfiguration *)defaultSessionConfiguration {
    NSURLSessionConfiguration *cfg = %orig;
    NSMutableArray *protos = [NSMutableArray arrayWithArray:cfg.protocolClasses ?: @[]];
    if (![protos containsObject:[GPSURLRedirectProtocol class]])
        [protos insertObject:[GPSURLRedirectProtocol class] atIndex:0];
    cfg.protocolClasses = protos;
    return cfg;
}

+ (NSURLSessionConfiguration *)ephemeralSessionConfiguration {
    NSURLSessionConfiguration *cfg = %orig;
    NSMutableArray *protos = [NSMutableArray arrayWithArray:cfg.protocolClasses ?: @[]];
    if (![protos containsObject:[GPSURLRedirectProtocol class]])
        [protos insertObject:[GPSURLRedirectProtocol class] atIndex:0];
    cfg.protocolClasses = protos;
    return cfg;
}

%end

// ── UserDefaults intercept: always return active for membership keys ──────────
%hook NSUserDefaults

- (NSInteger)integerForKey:(NSString *)key {
    for (NSString *k in memberIntKeys()) {
        if ([key isEqualToString:k]) return 1;
    }
    for (NSString *k in memberTimeKeys()) {
        if ([key isEqualToString:k]) return 4070908800LL;
    }
    return %orig;
}

- (BOOL)boolForKey:(NSString *)key {
    for (NSString *k in memberIntKeys()) {
        if ([key isEqualToString:k]) return YES;
    }
    return %orig;
}

- (id)objectForKey:(NSString *)key {
    for (NSString *k in memberStringKeys()) {
        if ([key isEqualToString:k]) return @"lifetime";
    }
    for (NSString *k in memberTimeKeys()) {
        if ([key isEqualToString:k]) return @(4070908800LL);
    }
    for (NSString *k in memberIntKeys()) {
        if ([key isEqualToString:k]) return @(1);
    }
    return %orig;
}

%end

// ── Suppress StoreKit errors so the 500 dialog stops appearing ────────────────
%hook SKProductsRequest

- (void)start {
    // Swallow the request entirely — no SIM means it always 500s anyway
    // The delegate won't receive an error, so no dialog will appear
}

%end

%ctor {
    [NSURLProtocol registerClass:[GPSURLRedirectProtocol class]];
    injectMembershipDefaults();
}
