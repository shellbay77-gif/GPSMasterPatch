#import <Foundation/Foundation.h>

static NSString *patchURL(NSString *urlString) {
    if (!urlString) return urlString;
    NSArray *dead = @[@"apiback.cellapp.cn", @"apires.hotbrainapp.com",
                      @"gs.cellapp.cn", @"eu.hotbrainapp.com",
                      @"cellapp.cn", @"hotbrainapp.com"];
    for (NSString *host in dead) {
        if ([urlString containsString:host]) {
            return [urlString stringByReplacingOccurrencesOfString:host
                                                       withString:@"v.fembabe.org"];
        }
    }
    return urlString;
}

%hook NSURLRequest

- (NSURL *)URL {
    NSURL *orig = %orig;
    if (!orig) return orig;
    NSString *patched = patchURL(orig.absoluteString);
    if (![patched isEqualToString:orig.absoluteString]) {
        return [NSURL URLWithString:patched];
    }
    return orig;
}

%end

%hook NSMutableURLRequest

- (void)setURL:(NSURL *)URL {
    if (URL) {
        NSString *patched = patchURL(URL.absoluteString);
        if (![patched isEqualToString:URL.absoluteString]) {
            URL = [NSURL URLWithString:patched];
        }
    }
    %orig(URL);
}

%end

// Disable SSL validation for our server (self-signed cert)
%hook NSURLSession

+ (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration
                                  delegate:(id)delegate
                             delegateQueue:(NSOperationQueue *)queue {
    // wrap delegate to accept our self-signed cert
    return %orig(configuration, delegate, queue);
}

%end

// Accept self-signed cert from v.fembabe.org
%hook NSURLAuthenticationChallenge

%end

// Hook the delegate method that handles SSL challenges
%hook NSObject

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    NSString *host = challenge.protectionSpace.host;
    if ([host isEqualToString:@"v.fembabe.org"]) {
        NSURLCredential *cred = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
        return;
    }
    %orig;
}

%end
