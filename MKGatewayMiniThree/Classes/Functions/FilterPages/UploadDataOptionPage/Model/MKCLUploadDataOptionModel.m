//
//  MKCLUploadDataOptionModel.m
//  MKGatewayMiniThree_Example
//
//  Created by aa on 2024/1/12.
//  Copyright © 2024 aadyx2007@163.com. All rights reserved.
//

#import "MKCLUploadDataOptionModel.h"

#import "MKMacroDefines.h"

#import "MKCLDeviceModeManager.h"

#import "MKCLMQTTInterface.h"

@interface MKCLUploadDataOptionModel ()

@property (nonatomic, strong)dispatch_queue_t readQueue;

@property (nonatomic, strong)dispatch_semaphore_t semaphore;

@end

@implementation MKCLUploadDataOptionModel

- (void)readDataWithSucBlock:(void (^)(void))sucBlock failedBlock:(void (^)(NSError *error))failedBlock {
    dispatch_async(self.readQueue, ^{
        if (![self readUploadDataOption]) {
            [self operationFailedBlockWithMsg:@"Read Upload Data option Error" block:failedBlock];
            return;
        }
        moko_dispatch_main_safe(^{
            if (sucBlock) {
                sucBlock();
            }
        });
    });
}

- (void)configDataWithSucBlock:(void (^)(void))sucBlock failedBlock:(void (^)(NSError *error))failedBlock {
    dispatch_async(self.readQueue, ^{
        if (![self configUploadDataOption]) {
            [self operationFailedBlockWithMsg:@"Setup failed!" block:failedBlock];
            return;
        }
        moko_dispatch_main_safe(^{
            if (sucBlock) {
                sucBlock();
            }
        });
    });
}

#pragma mark - interface
- (BOOL)readUploadDataOption {
    __block BOOL success = NO;
    [MKCLMQTTInterface cl_readUploadDataOptionWithMacAddress:[MKCLDeviceModeManager shared].macAddress topic:[MKCLDeviceModeManager shared].subscribedTopic sucBlock:^(id  _Nonnull returnData) {
        success = YES;
        self.timestamp = ([returnData[@"data"][@"timestamp"] integerValue] == 1);
        self.rawData_advertising = ([returnData[@"data"][@"adv_data"] integerValue] == 1);
        self.rawData_response = ([returnData[@"data"][@"rsp_data"] integerValue] == 1);
        dispatch_semaphore_signal(self.semaphore);
    } failedBlock:^(NSError * _Nonnull error) {
        dispatch_semaphore_signal(self.semaphore);
    }];
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    return success;
}

- (BOOL)configUploadDataOption {
    __block BOOL success = NO;
    [MKCLMQTTInterface cl_configUploadDataOption:self macAddress:[MKCLDeviceModeManager shared].macAddress topic:[MKCLDeviceModeManager shared].subscribedTopic sucBlock:^(id  _Nonnull returnData) {
        success = YES;
        dispatch_semaphore_signal(self.semaphore);
    } failedBlock:^(NSError * _Nonnull error) {
        dispatch_semaphore_signal(self.semaphore);
    }];
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    return success;
}

#pragma mark - private method
- (void)operationFailedBlockWithMsg:(NSString *)msg block:(void (^)(NSError *error))block {
    moko_dispatch_main_safe(^{
        NSError *error = [[NSError alloc] initWithDomain:@"uploadParams"
                                                    code:-999
                                                userInfo:@{@"errorInfo":msg}];
        block(error);
    })
}

#pragma mark - getter
- (dispatch_semaphore_t)semaphore {
    if (!_semaphore) {
        _semaphore = dispatch_semaphore_create(0);
    }
    return _semaphore;
}

- (dispatch_queue_t)readQueue {
    if (!_readQueue) {
        _readQueue = dispatch_queue_create("uploadQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _readQueue;
}

@end
