#import <Foundation/Foundation.h>

static NSURLRequest *patchRequest(NSURLRequest *req) {
    if (!req) return req;
    NSString *urlStr = req.URL.absoluteString;
    if (!urlStr) return req;

    NSArray *dead = @[@"apiback.cellapp.cn", @"apires.hotbrainapp.com",
                      @"gs.cellapp.cn", @"eu.hotbrainapp.com",
                      @"cellapp.cn", @"hotbrainapp.com"];

    for (NSString *host in dead) {
        if ([urlStr containsString:host]) {
            NSString *patched = [urlStr stringByReplacingOccurrencesOfString:host
                                                                  withString:@"v.fembabe.org"];
            NSMutableURLRequest *mut = [req mutableCopy];
            [mut setURL:[NSURL URLWithString:patched]];
            // Disable SSL validation for our server
            return [mut copy];
        }
    }
    return req;
}

// Hook at the NSURLSession task-creation level so the actual request is replaced
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    return %orig(patchRequest(request), completionHandler);
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    return %orig(patchRequest(request));
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                               completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    return %orig(patchRequest(request), bodyData, completionHandler);
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                   completionHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))completionHandler {
    return %orig(patchRequest(request), completionHandler);
}

%end

// Accept self-signed cert from v.fembabe.org
%hook NSObject

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if ([challenge.protectionSpace.host isEqualToString:@"v.fembabe.org"]) {
        NSURLCredential *cred = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
    } else {
        %orig;
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if ([challenge.protectionSpace.host isEqualToString:@"v.fembabe.org"]) {
        NSURLCredential *cred = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
    } else {
        %orig;
    }
}

%end
