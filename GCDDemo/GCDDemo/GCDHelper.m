#import "GCDHelper.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <UIKit/UIKit.h>
//Error
#define GCDHelperErrorURLISNULL   [NSError errorWithDomain:@"please setup GCDHelper‘s url or urlString" code:100 userInfo:nil]
#define GCDHelperErrorRequestISNULL  [NSError errorWithDomain:@"request can not be nil!" code:101 userInfo:nil]
#define GCDHelperErrorFileExist    [NSError errorWithDomain:@"File Exist!" code:102 userInfo:nil]
#define GCDHelperErrorCreateFail   [NSError errorWithDomain:@"Create File Fail!" code:103 userInfo:nil]

//下载的临时文件的后缀
#define kTHDownLoadTask_TempSuffix  @".TempDownload"
//计算下载速度的取样时间
#define kTHDownLoadTimerInterval  2.0
//THDispatchQueue默认的并发数
#define kTHDispatchQueueDefaultConcurrentCount 10

#define kDefaultTimeoutInterval  15


static NSString * const BOUNDRY        = @"--------------------------7d71a819230404";


@implementation GCDHelper

- (void) dealloc
{
    [super dealloc];
}

- (id) init
{
    if (self = [super init])
    {
    }
    
    return self;
}

#pragma mark -
#pragma mark 获取队列

+ (dispatch_queue_t) gcdMainQueue
{
    return dispatch_get_main_queue();
}

+ (dispatch_queue_t) gcdGlobalQueue:(GlobalQueuePriority) priority
{
    switch (priority)
    {
        case GlobalQueuePriorityDefault:
            return dispatch_get_global_queue(priority, 0);
            break;
        case GlobalQueuePriorityHigh:
            return dispatch_get_global_queue(priority, 0);
            break;
        case GlobalQueuePriorityLow:
            return dispatch_get_global_queue(priority, 0);
            break;
        case GlobalQueuePriorityBackground:
            return dispatch_get_global_queue(priority, 0);
            break;
            
        default:
            return dispatch_get_global_queue(GlobalQueuePriorityDefault, 0);
            break;
    }
}

+ (dispatch_queue_t) gcdCustomQueue:(NSString *) queueName;
{
    return dispatch_queue_create([queueName UTF8String], NULL);
}

#pragma mark -
#pragma mark 3种队列上执行Block

+ (void) gcdPerformBlockOnMainQueue:(GCDBlock) block feature:(PerformBlockFeature) feature
{
    switch (feature)
    {
        case PerformBlockFeatureChoke:
            dispatch_sync([GCDHelper gcdMainQueue], block);
            break;
            
        case PerformBlockFeatureUnchoke:
            dispatch_async([GCDHelper gcdMainQueue], block);
            break;
            
        default:
            dispatch_sync([GCDHelper gcdMainQueue], block);
            break;
    }
}

+ (void) gcdPerformBlockOnGlobalQueue:(GCDBlock) block feature:(PerformBlockFeature) feature priority:(GlobalQueuePriority) priority
{
    switch (feature)
    {
        case PerformBlockFeatureChoke:
            dispatch_sync([GCDHelper gcdGlobalQueue:priority], block);
            break;
            
        case PerformBlockFeatureUnchoke:
            dispatch_async([GCDHelper gcdGlobalQueue:priority], block);
            break;
            
        default:
            dispatch_sync([GCDHelper gcdGlobalQueue:GlobalQueuePriorityDefault], block);
            break;
    }
}

+ (void) gcdPerformBlockOnCustomQueue:(GCDBlock) block feature:(PerformBlockFeature) feature name:(NSString *) queueName
{
    switch (feature)
    {
        case PerformBlockFeatureChoke:
            dispatch_sync([GCDHelper gcdCustomQueue:queueName], block);
            break;
            
        case PerformBlockFeatureUnchoke:
            dispatch_async([GCDHelper gcdCustomQueue:queueName], block);
            break;
            
        default:
            dispatch_sync([GCDHelper gcdCustomQueue:@"com.GCDHelper.Queue"], block);
            break;
    }
}

//后台执行
+ (void) gcdPerformBlockAsynchronous:(GCDBlock) block
{
    [GCDHelper gcdPerformBlockOnGlobalQueue:block
                                    feature:PerformBlockFeatureUnchoke
                                   priority:GlobalQueuePriorityDefault];
}

//后台获取数据后，回到主线程
+ (void) gcdPerformBlockAsynchronous:(GCDBlock) blockAsyn
                   finishOnMainQueue:(GCDBlock) blockM
{
    dispatch_async([GCDHelper gcdGlobalQueue:GlobalQueuePriorityDefault], ^{
        blockAsyn();
        dispatch_async([GCDHelper gcdMainQueue], ^{
            blockM();
        });
    });
}

#pragma mark -
#pragma mark 队列延迟时间执行方法
+ (void) gcdPerformBlock:(GCDBlock) block onQueue:(dispatch_queue_t) queue delaySecond:(int64_t) second
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, second * NSEC_PER_SEC);
    dispatch_after(popTime, queue, block);
}

#pragma mark -
#pragma mark 只执行一次

+ (void) gcdPerformBlockOnce:(GCDBlock) block
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, block);
}

#pragma mark -
#pragma mark 无序并发

+ (void) gcdBatchPerformBlocks:(NSArray *) blockArray finally:(GCDBlock) finallyBlock
{
    [blockArray retain];
    
    dispatch_queue_t queue = [GCDHelper gcdGlobalQueue:GlobalQueuePriorityDefault];
    dispatch_group_t group = dispatch_group_create();
    
    for(GCDBlock block in blockArray)
    {
        dispatch_group_async(group, queue, ^{
            block();
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    dispatch_async([GCDHelper gcdGlobalQueue:GlobalQueuePriorityDefault], ^{
        finallyBlock();
    });
    
    dispatch_release(group);
    
    [blockArray release];
}

+ (void) gcdBatchPerformBlockWithData:(NSArray *) dataArray
          maxConcurrentOperationCount:(uint) count
                          handleBlock:(GCDBlock1_Obj) block
                              finally:(GCDBlock1_Obj) finallyBlock
{
    [dataArray retain];
    
    dispatch_queue_t queue = [GCDHelper gcdGlobalQueue:GlobalQueuePriorityDefault];
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(count);
    for(id obj in dataArray)
    {
        NSLog(@"并发中");
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group, queue, ^{
            block(obj);
            dispatch_semaphore_signal(semaphore);
        });
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_group_notify(group, queue, ^{
        finallyBlock(dataArray);
    });
    dispatch_release(group);
    
    [dataArray release];
}



#pragma mark -
#pragma mark 图片下载

- (void) gcdImageWithURLString:(NSString *) URLString
{
    [self gcdImageWithURLString:URLString completion:nil];
}

- (void) gcdImageWithURLString:(NSString *) URLString completion:(GCDBlock2_Obj_Obj) completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:URLString]];
        [request setHTTPMethod:@"GET"];
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request
                                                   returningResponse:nil
                                                               error:nil];
        [request release];
        
        UIImage *image  = [UIImage imageWithData:returnData];
        
        if (image)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                completion(image, URLString);
            });
        } else
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                completion(image, URLString);
            });
        }
    });
}

@end


#pragma mark -
#pragma mark 网络部分

@implementation GCDHelper (NetworkConnect)

- (BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags
{
    BOOL connectionUP = YES;
    
    if(!(flags & kSCNetworkReachabilityFlagsReachable))
        connectionUP = NO;
    
    if( (flags & (kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)) == (kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection) )
        connectionUP = NO;
    
    return connectionUP;
}

-(void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _netWorkBlock([self isReachableWithFlags:flags]);
    });
}

static void TMReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    @autoreleasepool
    {
        [(GCDHelper *)info reachabilityChanged:flags];
    }
}

- (void) gcdNetWorkGuarder:(NSString *) hostname withBlock:(GCDBlock1_Bool) block
{
    _netWorkBlock = block;
    
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
    SCNetworkReachabilityContext context = { 0, NULL, NULL, NULL, NULL };
    dispatch_queue_t queue = dispatch_queue_create("com.myself.reachability", NULL);
    context.info = (void *)self;
    SCNetworkReachabilitySetCallback(ref, TMReachabilityCallback, &context);
    SCNetworkReachabilitySetDispatchQueue(ref, queue);
}

@end

@implementation GCDHelper(HttpRequest)

- (void) startPOSTHTTPRequest:(NSString *) URLString
                       params:(NSDictionary *) params
                      timeout:(NSTimeInterval) time
                      success:(GCDHttpRequestBlock) successBlock
                         fail:(GCDHttpRequestBlock) failBlock
{
    [params retain];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __block NSURLResponse  *response = nil;
        __block NSError *error = nil;
        __block NSData *receiveData = nil;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        
        [request setURL:[NSURL URLWithString:[URLString lowercaseString]]];
        [request setHTTPMethod:@"POST"];
        [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
        [request setTimeoutInterval:time];
        
        if (!request)
        {
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"发送请求失败", @"errorKey", nil];
            error = [NSError errorWithDomain:@"www.myself.com" code:100 userInfo:errorInfo];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(response, error, receiveData);
            });
            
            return;
        }
        
        if (params != nil)
        {
            [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDRY]
           forHTTPHeaderField:@"Content-Type"];
            
            int len=512;
            NSMutableData *postData =[NSMutableData dataWithCapacity:len];
            [postData appendData:[[NSString stringWithFormat:@"--%@/r/n", BOUNDRY]
                                  dataUsingEncoding:NSUTF8StringEncoding]];
            int i=0;
            int cnt = [params count];
            
            for (NSString *key in [params allKeys])
            {
                // NSString *str = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"/r/n/r/n", key];
                [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"/r/n/r/n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                
                [postData  appendData: [[NSString stringWithFormat:@"%@",[params objectForKey:key]]
                                        dataUsingEncoding:NSUTF8StringEncoding]];
                if(i != cnt - 1)
                {
                    [postData appendData:[[NSString stringWithFormat:@"/r/n--%@/r/n", BOUNDRY]
                                          dataUsingEncoding:NSUTF8StringEncoding]];
                }
                i++ ;
            }
            [postData  appendData:[[NSString stringWithFormat:@"/r/n--%@--/r/n", BOUNDRY]
                                   dataUsingEncoding:NSUTF8StringEncoding]];
            
            [request  setHTTPBody:postData];
        }
        
        receiveData = [[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error] retain];
        if (!error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(response, nil, receiveData);
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(response, error, receiveData);
            });
        }
        
        [request release];
    });
    
    [params release];
}

- (void) startGETHTTPRequest:(NSString *) URLString
                      params:(NSDictionary *) params
                     timeout:(NSTimeInterval) time
                     success:(GCDHttpRequestBlock) successBlock
                        fail:(GCDHttpRequestBlock) failBlock
{
    [params retain];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSURLResponse  *response = nil;
        __block NSError *error = nil;
        __block NSData *receiveData = nil;
        
        NSMutableString *paramsString = [[NSMutableString alloc] init];
        for(NSString *key in params)
        {
            [paramsString appendFormat:@"&%@=%@", key, [params objectForKey:key]];
        }
        NSString *requestString = [[NSString alloc] initWithFormat:@"%@%@", URLString, paramsString];
        NSURL *reqUrl = [[NSURL alloc] initWithString:requestString];
        
        [paramsString release];
        [requestString release];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        
        [request setURL:reqUrl];
        [request setHTTPMethod:@"GET"];
        [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
        [request setTimeoutInterval:time];
        
        [reqUrl release];
        
        if (request)
        {
            receiveData = [[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error] retain];
        }
        
        if (!error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(response, nil, receiveData);
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(response, error, receiveData);
            });
        }
        
        [request release];
    });
    
    [params release];
}

- (void) gcdHttpRequestWithURL:(NSString *) URLString
                    httpMethod:(GCDHelperHttpRequestMethod) method
                        params:(NSDictionary *) params
                       timeout:(NSTimeInterval) time
                       success:(GCDHttpRequestBlock) successBlock
                          fail:(GCDHttpRequestBlock) failBlock
{
    switch (method)
    {
        case GCDHelperHttpRequestMethodGET:
        {
            [self startGETHTTPRequest:URLString params:params timeout:time success:successBlock fail:failBlock];
            break;
        }
        case GCDHelperHttpRequestMethodPOST:
        {
            [self startPOSTHTTPRequest:URLString params:params timeout:time success:successBlock fail:failBlock];
            break;
        }
            
        default:
            break;
    }
}

@end