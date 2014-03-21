//
//  BTDevice.m
//  btutil
//
//  Created by Marshall Brekka on 12/11/12.
//  Copyright (c) 2012 Marshall Brekka. All rights reserved.
//

#import "BTDevice.h"
#import <time.h>

@implementation BTDevice
+ (void) list:(IOBluetoothDevice*)device {
    NSString *onOff;

    if([device isConnected]) {
        onOff = @"ON ";
    } else {
        onOff = @"OFF";
    }
    
    printf("%s %s %s\n", [onOff UTF8String], [[device addressString] UTF8String], [[device name] UTF8String]);
}

+ (int) connect:(IOBluetoothDevice*)device {
    return [self connect:device withRSSIThreshold:nil andTimeout:nil];
}

+ (int) connect:(IOBluetoothDevice*)device withRSSIThreshold:(NSNumber *) RSSIThreshold andTimeout:(NSNumber *) timeout {
    if ([device openConnection] != kIOReturnSuccess) {
        printf("The device failed to connect\n");
        return 1;
    }

    if (RSSIThreshold != nil) {
        printf("RSSI threshold:%d\n", [RSSIThreshold intValue]);
        
        time_t currentTime = time(NULL);

        int till = (int)currentTime + [timeout intValue];
        int rssi;
        
        while ((int) time(NULL) < till) {
            rssi = (int) [device rawRSSI];
            
            if (rssi != 127 && rssi >= [RSSIThreshold intValue]) {
                break;
            }

            [NSThread sleepForTimeInterval:0.016];
        }
        
        if (rssi < [RSSIThreshold intValue]) {
            printf("RSSI threshold is not passed\n");
            return 1;
        }
        
        printf("RSSI: %d\n", rssi);
    }
    
    printf("OK. Connected\n");

    return 0;
}

+ (int) connectAddress:(NSString *)address {
    return [self connectAddress:address withRSSIThreshold:nil andTimeout:nil];
}

+ (int) connectAddress:(NSString *)address withRSSIThreshold:(NSNumber *) RSSIThreshold andTimeout:(NSNumber *) timeout {
    IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:address];

    if (device == NULL) {
        printf("There is no device paired with the address %s\n", [address UTF8String]);
        return 1;
    } else if (RSSIThreshold != nil && timeout == nil) {
        printf("RSSI threshold specified but there is no timeout");
        return 1;
    } else {
        return [BTDevice connect:device withRSSIThreshold:RSSIThreshold andTimeout:timeout];
    }
}

+ (int) disconnect:(IOBluetoothDevice*)device {
    if ([device closeConnection] && [device isConnected]) {
        printf("The device failed to disconnect\n");
        return 1;
    }
    return 0;
}

+ (int) disconnectAddress:(NSString *)address {
    IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:address];
    if (device == NULL) {
        printf("There is no device paired with the address %s\n", [address UTF8String]);
        return 1;
    } else {
        return [BTDevice disconnect:device];
    }
    
}
@end
