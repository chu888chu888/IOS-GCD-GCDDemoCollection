/*
 *  Grand Central Dispatch (GCD)是Apple开发的一个多核编程的解决方法。
 *  系统要求：iOS4.0以上。
 */

#import <Foundation/Foundation.h>

///////////////////////////////////////     enum 声明     /////////////////////////////////////////////////

//队列优先级
typedef enum
{
    GlobalQueuePriorityDefault = 0,
    GlobalQueuePriorityHigh = 2,
    GlobalQueuePriorityLow = -2,
    GlobalQueuePriorityBackground = INT16_MIN
    
} GlobalQueuePriority;

//阻塞、非阻塞
typedef enum
{
    PerformBlockFeatureChoke,
    PerformBlockFeatureUnchoke
    
} PerformBlockFeature;

//网络请求方法
typedef enum GCDHelperHttpRequestMethod
{
    GCDHelperHttpRequestMethodGET = 0,
    GCDHelperHttpRequestMethodPOST
    
} GCDHelperHttpRequestMethod;

///////////////////////////////////////     Block 声明     /////////////////////////////////////////////////

//返回值void
typedef     void (^GCDBlock)                         (void);
typedef     void (^GCDBlock1_Size_t)                 (size_t index);
typedef     void (^GCDBlock1_Int)                    (int index);
typedef     void (^GCDBlock1_Bool)                   (BOOL flag);
typedef     void (^GCDBlock1_Float)                  (float index);
typedef     void (^GCDBlock1_Obj)                    (id object);

//返回值void，两个形式参数
typedef     void (^GCDBlock2)                        (id object1, size_t index);
typedef     void (^GCDBlock2_Obj_Int)                (id object1, int index);
typedef     void (^GCDBlock2_Obj_Obj)                (id object1, id object2);

//有返回值
typedef     id   (^GCD_Obj_Block_Obj)                (id object);
typedef     id   (^GCD_Obj_Block_Void)               (void);

typedef     void (^GCDHttpRequestBlock)              (NSURLResponse *response, NSError *error, NSData *data);


///////////////////////////////////////     GCDHelper 声明     /////////////////////////////////////////////////

@interface GCDHelper : NSObject

/* 获取3种队列 */
+ (dispatch_queue_t) gcdMainQueue;
+ (dispatch_queue_t) gcdGlobalQueue:(GlobalQueuePriority) priority;
+ (dispatch_queue_t) gcdCustomQueue:(NSString *) queueName;

//后台执行
+ (void) gcdPerformBlockAsynchronous:(GCDBlock) block;

//后台获取数据后，回到主线程
+ (void) gcdPerformBlockAsynchronous:(GCDBlock) blockAsyn
                   finishOnMainQueue:(GCDBlock) blockM;


/* 3种队列上执行Block
 *
 * 是否阻塞执行：(PerformBlockFeature) feature
 * 全局队列优先级：(GlobalQueuePriority) priority
 */
+ (void) gcdPerformBlockOnMainQueue:(GCDBlock) block feature:(PerformBlockFeature) feature;

+ (void) gcdPerformBlockOnGlobalQueue:(GCDBlock) block
                              feature:(PerformBlockFeature) feature
                             priority:(GlobalQueuePriority) priority;

+ (void) gcdPerformBlockOnCustomQueue:(GCDBlock) block
                              feature:(PerformBlockFeature) feature
                                 name:(NSString *) queueName;


//延迟执行方法
+ (void) gcdPerformBlock:(GCDBlock) block
                 onQueue:(dispatch_queue_t) queue
             delaySecond:(int64_t) second;


//只执行一次
+ (void) gcdPerformBlockOnce:(GCDBlock) block;

//并发
+ (void) gcdBatchPerformBlocks:(NSArray *) blockArray finally:(GCDBlock) finallyBlock;

+ (void) gcdBatchPerformBlockWithData:(NSArray *) dataArray
          maxConcurrentOperationCount:(uint) count
                          handleBlock:(GCDBlock1_Obj) block
                              finally:(GCDBlock1_Obj) finallyBlock;



@end

///////////////////////////////////////     图片下载     /////////////////////////////////////////////////

@interface GCDHelper (ImageDownload)

- (void) gcdImageWithURLString:(NSString *) URLString;
- (void) gcdImageWithURLString:(NSString *) URLString completion:(GCDBlock2_Obj_Obj) completion;

@end

///////////////////////////////////////     网络请求     /////////////////////////////////////////////////

GCDBlock1_Bool _netWorkBlock;
@interface GCDHelper (NetworkConnect)

//网络连接判断、实时监控
- (void) gcdNetWorkGuarder:(NSString *) hostname withBlock:(GCDBlock1_Bool) block;

@end


@interface GCDHelper (HttpRequest)

//GCD请求网络（GET方式测试通过，POST方式测试未通过）
- (void) gcdHttpRequestWithURL:(NSString *) URLString
                    httpMethod:(GCDHelperHttpRequestMethod) method
                        params:(NSDictionary *) params
                       timeout:(NSTimeInterval) time
                       success:(GCDHttpRequestBlock) successBlock
                          fail:(GCDHttpRequestBlock) failBlock;

@end