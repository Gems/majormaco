//
//  BTDevice.m
//  btutil
//
//  Created by Marshall Brekka on 12/11/12.
//  Copyright (c) 2012 Marshall Brekka. All rights reserved.
//

#import "BTDevice.h"


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
    if ([device openConnection] != kIOReturnSuccess) {
        printf("The device failed to connect\n");
        return 1;
    }
    return 0;
}

+ (int) connectAddress:(NSString *)address {
    IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:address];
    if (device == NULL) {
        printf("There is no device paired with the address %s\n", [address UTF8String]);
        return 1;
    } else {
        return [BTDevice connect:device];
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
