#import <Foundation/Foundation.h>

static NSString *const kHandledKey = @"GPSURLHandled";
static NSString *const kNewHost    = @"v.fembabe.org";

static BOOL isDeadHost(NSString *host) {
    return [host hasSuffix:@"cellapp.cn"] || [host hasSuffix:@"hotbrainapp.com"];
}

@interface GPSURLRedirectProtocol : NSURLProtocol <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
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
    self.session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:nil];
    [[self.session dataTaskWithRequest:req] resume];
}

- (void)stopLoading {
    [self.session invalidateAndCancel];
}

// Forward data/response/finish/error to the client
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

// Accept self-signed cert from v.fembabe.org
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
     completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if ([challenge.protectionSpace.host isEqualToString:kNewHost]) {
        NSURLCredential *cred = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end

%ctor {
    [NSURLProtocol registerClass:[GPSURLRedirectProtocol class]];
}
