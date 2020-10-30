//
//  MMWormholeAppendingFile.m
//  MMWormhole-iOS
//
//  Created by Liyanwei on 2020/8/25.
//  Copyright © 2020 MMWormhole. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMWormholeAppendingFile.h"

@implementation MMWormholeAppendingFile

#pragma mark - Public Protocol Methods

- (BOOL)writeMessageObject:(id<NSCoding>)messageObject forIdentifier:(NSString *)identifier {
    if (identifier == nil) {
        return NO;
    }
    
    if (messageObject) {
        NSData *archiver = [NSKeyedArchiver archivedDataWithRootObject:messageObject];
        NSData *data = [archiver base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        
        NSString *filePath = [self filePathForIdentifier:identifier];
        
        if (data == nil || filePath == nil) {
            return NO;
        }
        
        BOOL exist = [self.fileManager fileExistsAtPath:filePath];
        if (!exist) {
            [self.fileManager createFileAtPath:filePath contents:nil attributes:nil];
        }
        
        BOOL exist2 = [self.fileManager fileExistsAtPath:filePath];
        NSAssert(exist2, @"文件创建失败");
        NSFileHandle* fielHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        
        // 移动到最后
        [fielHandle seekToEndOfFile];
        
        NSDictionary *fileAtt = [self.fileManager attributesOfItemAtPath:filePath error:nil];
        NSNumber *fileSizeNum = [fileAtt objectForKey:NSFileSize];
        long fileSize = [fileSizeNum longValue];
        if (fileSize > 0) {
            [fielHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        // 追加写入数据
        [fielHandle writeData:data];
        // 关闭
        [fielHandle closeFile];
    }
    
    return YES;
}

- (id<NSCoding>)messageObjectForIdentifier:(NSString *)identifier {
    if (identifier == nil) {
        return nil;
    }
    
    NSString *filePath = [self filePathForIdentifier:identifier];
    
    if (filePath == nil) {
        return nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    if (data == nil) {
        return nil;
    }
    
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *array = [string componentsSeparatedByString:@"\n"];
    
    NSMutableArray* ret = @[].mutableCopy;
    for (id base64Data in array) {
        if (base64Data) {
            // Base64形式的NSData转换为data
            NSData *data = [[NSData alloc] initWithBase64EncodedData:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
            if (data) {
                id t = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if (t) {
                    [ret addObject:t];
                }
            }
        }
    }
    
    //NSLog(@"biubiu read data identifier=%@  data=%@" ,identifier  ,  ret);
    return [ret copy];
}

@end
