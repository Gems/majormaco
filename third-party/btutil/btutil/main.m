//
//  main.m
//  btutil
//
//  Created by Marshall Brekka on 12/10/12.
//  Copyright (c) 2012 Marshall Brekka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "BTDevice.h"

void printUsage(const char * binName) {
    printf("Usage: %s [list [<address>]] [connect|disconnect <address>]\n", binName);
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        if(argc == 1) {
            printUsage(argv[0]);
            return 1;
        }
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
        NSString *task = [arguments objectAtIndex:1];
        
        if([task isEqualToString:@"list"]) {
            NSArray *devices = [IOBluetoothDevice pairedDevices];
            NSString *address;
            if (argc == 3) {
                address = [arguments objectAtIndex:2];
            }
            for(id object in devices) {
                if (argc == 3) {
                    if([[object addressString] isEqualToString:address]) {
                        [BTDevice list:object];
                    }
                } else {
                    [BTDevice list:object];
                }
                
            }
        } else if ([task isEqualToString:@"connect"] && argc == 3) {
            return [BTDevice connectAddress:[arguments objectAtIndex:2]];
        } else if ([task isEqualToString:@"disconnect"] && argc == 3) {
            return [BTDevice disconnectAddress:[arguments objectAtIndex:2]];
        } else {
            printUsage(argv[0]);
        }
    }
    return 0;
}

