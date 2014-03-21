//
//  BTDevice.h
//  btutil
//
//  Created by Marshall Brekka on 12/11/12.
//  Copyright (c) 2012 Marshall Brekka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@interface BTDevice : NSObject
+ (void) list: (IOBluetoothDevice*)device;
+ (int) connect:(IOBluetoothDevice*)device;
+ (int) connect:(IOBluetoothDevice*)device withRSSIThreshold:(NSNumber *) RSSIThreshold andTimeout:(NSNumber *) timeout;
+ (int) connectAddress:(NSString*)address;
+ (int) connectAddress:(NSString *)address withRSSIThreshold:(NSNumber *) RSSIThreshold andTimeout:(NSNumber *) timeout;
+ (int) disconnect:(IOBluetoothDevice*)device;
+ (int) disconnectAddress:(NSString*)address;
@end
