//
//  do_SysCalendar_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_SysCalendar_App.h"
static do_SysCalendar_App* instance;
@implementation do_SysCalendar_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_SysCalendar_App alloc]init];
    return instance;
}
@end
