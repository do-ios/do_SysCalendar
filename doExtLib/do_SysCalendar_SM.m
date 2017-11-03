//
//  do_SysCalendar_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_SysCalendar_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import "doILogEngine.h"
#import "doServiceContainer.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

@interface do_SysCalendar_SM()
@property (nonatomic, strong) NSString * resultEventId;
@property (nonatomic, assign) NSInteger frequency;
@property (nonatomic, strong) NSMutableArray * resultArray;

@end

@implementation do_SysCalendar_SM
#pragma mark - 注册属性（--属性定义--）
/*
 [self RegistProperty:[[doProperty alloc]init:@"属性名" :属性类型 :@"默认值" : BOOL:是否支持代码修改属性]];
 */
-(void)OnInit
{
    [super OnInit];
    //注册属性
}

//销毁所有的全局对象
-(void)Dispose
{
    //(self)类销毁时会调用递归调用该方法，在该类中主动生成的非原生的扩展对象需要主动调该方法使其销毁
}
#pragma mark - 方法
#pragma mark - 同步异步方法的实现

//同步
//异步
- (void)add:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    
    if (![_dictParas objectForKey:@"title"] || ![_dictParas objectForKey:@"description"] || ![_dictParas objectForKey:@"startTime"] || ![_dictParas objectForKey:@"endTime"]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"必填参数遗漏"];
        return;
    }
    
    //必填参数
    NSString * title = [doJsonHelper GetOneText:_dictParas :@"title" :@""];
    NSString * description = [doJsonHelper GetOneText:_dictParas :@"description" :@""];
    NSString * startTimeStr = [doJsonHelper GetOneText:_dictParas :@"startTime" :@""];
    NSString * endTimeStr = [doJsonHelper GetOneText:_dictParas :@"endTime" :@""];
    
    //非必填参数
    NSString * location = [doJsonHelper GetOneText:_dictParas :@"location" :@""];
    NSString * reminderTime = [doJsonHelper GetOneText:_dictParas :@"reminderTime" :@""];
    NSString * reminderRepeatMode = [doJsonHelper GetOneText:_dictParas :@"reminderRepeatMode" :@""];
    NSString * reminderRepeatEndTimeStr = [doJsonHelper GetOneText:_dictParas :@"reminderRepeatEndTime" :@""];
    
    if ([title isEqualToString:@""]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"title参数不能为空"];
        return;
    } else if ([description isEqualToString:@""]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"description参数不能为空"];
        return;
    } else if ([startTimeStr isEqualToString:@""]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"startTimeStr参数不能为空"];
        return;
    } else if ([endTimeStr isEqualToString:@""]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"endTimeStr参数不能为空"];
        return;
    }
    
    
    double startTimeCount = [startTimeStr doubleValue];
    double endTimeCount = [endTimeStr doubleValue];
    double reminderRepeatEndTimeCount = [reminderRepeatEndTimeStr doubleValue];
    if (startTimeCount > endTimeCount) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"开始日期要早于结束日期"];
//        [self returnValueWithParms:parms];
        return;
    }
    
    if (reminderRepeatMode && ![reminderRepeatEndTimeStr isEqualToString:@""]) {
        if (startTimeCount > reminderRepeatEndTimeCount) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"设置的提醒重复时间时间错误"];
//            [self returnValueWithParms:parms];
            return;
        }
    }
    
    EKEventStore * store = [[EKEventStore alloc] init];
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
        if (error) {
            NSException * exception = (NSException *)error;
            [[doServiceContainer Instance].LogEngine WriteError:exception :@""];
        }
        else if (!granted) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"用户没有授权"];
           
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"未授权访问日历" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            [alert show];
        }
        else {
            //添加日程
            EKEvent * event = [EKEvent eventWithEventStore:store];
            event.title = title;
            event.notes = description;
            //时间格式
            NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
            NSTimeInterval startTime = [startTimeStr doubleValue]/1000;
            NSDate * startTimeDate = [NSDate dateWithTimeIntervalSince1970:startTime];
            event.startDate = startTimeDate;
            
            NSTimeInterval endTime = [endTimeStr doubleValue]/1000;
            NSDate * endTimeDate = [NSDate dateWithTimeIntervalSince1970:endTime];
            event.endDate = endTimeDate;
            
            if (location && ![location isEqualToString:@""]) {
                event.location = location;
            }
            //提醒时间未设置则准时提醒
            if (reminderTime && ![reminderTime isEqualToString:@""]) {
                NSInteger minute = [reminderTime integerValue];
                [event addAlarm:[EKAlarm alarmWithRelativeOffset:-60*minute]];
            }
            if ([reminderTime isEqualToString:@""]) {
                [event addAlarm:[EKAlarm alarmWithRelativeOffset:0]];
            }
            if (reminderRepeatMode && ![reminderRepeatMode isEqualToString:@""]) {
                
                if ([reminderRepeatMode isEqualToString:@"Day"] || [reminderRepeatMode isEqualToString:@"day"]) {
                    _frequency = EKRecurrenceFrequencyDaily;
                }
                else if ([reminderRepeatMode isEqualToString:@"Week"] || [reminderRepeatMode isEqualToString:@"week"]) {
                    _frequency = EKRecurrenceFrequencyWeekly;
                }
                else if ([reminderRepeatMode isEqualToString:@"Month"] || [reminderRepeatMode isEqualToString:@"month"]) {
                    _frequency = EKRecurrenceFrequencyMonthly;
                }
                else {
                    _frequency = EKRecurrenceFrequencyYearly;
                }
                
                //如果提醒重复结束时间为空，则默认为10年结束
                if (reminderRepeatEndTimeStr && ![reminderRepeatEndTimeStr isEqualToString:@""]) {
                    NSTimeInterval reminderRepeatEndTime = [reminderRepeatEndTimeStr doubleValue]/1000;
                    NSDate * reminderRepeatEndTimeDate = [NSDate dateWithTimeIntervalSince1970:reminderRepeatEndTime];
                    EKRecurrenceRule * rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:_frequency interval:1 end:[EKRecurrenceEnd recurrenceEndWithEndDate:reminderRepeatEndTimeDate]];
                    [event addRecurrenceRule:rule];
                } else {
                    NSCalendar * allCalendar = [NSCalendar currentCalendar];
                    NSDateComponents * endDateComponents = [[NSDateComponents alloc] init];
                    endDateComponents.year = 10;
                    NSDate * reminderRepeatEndTimeDate = [allCalendar dateByAddingComponents:endDateComponents
                                                                    toDate:[NSDate date]
                                                                   options:0];
                    EKRecurrenceRule * rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:_frequency interval:1 end:[EKRecurrenceEnd recurrenceEndWithEndDate:reminderRepeatEndTimeDate]];
                    [event addRecurrenceRule:rule];
                }
            }
        
            [event setCalendar:[store defaultCalendarForNewEvents]];
            NSError * error;
            [store saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
            //返回所添加日程的唯一ID
            _resultEventId = event.eventIdentifier;
            
            [NSThread sleepForTimeInterval:1.0];
            
            //参数字典_dictParas
            id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
            //自己的代码实现
            
            NSString *_callbackName = [parms objectAtIndex:2];
            //回调函数名_callbackName
            doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
            //_invokeResult设置返回值
            [_invokeResult SetResultText:_resultEventId];
            
            [_scritEngine Callback:_callbackName :_invokeResult];
        }
    }];
}
- (void)delete:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSString * deleteId = [doJsonHelper GetOneText:_dictParas :@"id" :@""];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    EKEventStore * store = [[EKEventStore alloc] init];
    EKEvent * event = [store eventWithIdentifier:deleteId];
    NSError * error;
    BOOL deleteResult = [store removeEvent:event span:EKSpanThisEvent commit:YES error:&error];
    
    NSString *_callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    //_invokeResult设置返回值
    [_invokeResult SetResultBoolean:deleteResult];
    
    [_scritEngine Callback:_callbackName :_invokeResult];
}
- (void)getAll:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    EKEventStore * store = [[EKEventStore alloc] init];
    
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
        if (!granted) {
            [[doServiceContainer Instance].LogEngine WriteError:nil :@"用户没有授权"];
            
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"未授权访问日历" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            [alert show];
        }
        else if (error) {
            NSException * exception = (NSException *)error;
            [[doServiceContainer Instance].LogEngine WriteError:exception :@""];
        }
        else {
            _resultArray = [NSMutableArray array];
            
            NSArray * array = [store calendarsForEntityType:EKEntityTypeEvent];
            NSMutableArray * mutArray = [NSMutableArray array];
            for (int i = 0; i < array.count; i++) {
                EKCalendar * calendar = array[i];
                EKCalendarType type = calendar.type;
                //个人、工作、Birthday
                if (type == EKCalendarTypeLocal || type == EKCalendarTypeCalDAV || type == EKCalendarTypeBirthday) {
                    [mutArray addObject:calendar];
                }
            }
            
            //获取全部日程  注:iOS没有获取全部日程的方法，只能通过谓词查询，故设一极大值，前后各1年。超出时限后获取不到数据或数据不全
            NSCalendar * allCalendar = [NSCalendar currentCalendar];
            //创建起始日期组件
            NSDateComponents * startDateComponents = [[NSDateComponents alloc] init];
            startDateComponents.year = -2;
            NSDate * startDate = [allCalendar dateByAddingComponents:startDateComponents
                                                              toDate:[NSDate date]
                                                             options:0];
            //创建结束日期组件
            NSDateComponents * endDateComponents = [[NSDateComponents alloc] init];
            endDateComponents.year = 2;
            NSDate * endDate = [allCalendar dateByAddingComponents:endDateComponents
                                                            toDate:[NSDate date]
                                                           options:0];
            
            //创建谓词
            NSPredicate * predicate = [store predicateForEventsWithStartDate:startDate
                                                                     endDate:endDate
                                                                   calendars:mutArray];
            NSArray * events = [store eventsMatchingPredicate:predicate];
            //处理返回结果
            for (int i = 0; i<events.count; i++) {
                EKEvent * event = events[i];
                NSString * eventId = event.eventIdentifier;
                NSString * title = event.title;
                NSString * description = event.notes;
                NSTimeInterval startTimeInterval = [event.startDate timeIntervalSince1970]*1000;
                NSString * startTime = [NSString stringWithFormat:@"%f", startTimeInterval];
                NSArray * startArr = [startTime componentsSeparatedByString:@"."];
                NSString * start = [startArr objectAtIndex:0];
                NSTimeInterval endTimeInterval = [event.endDate timeIntervalSince1970]*1000;
                NSString * endTime = [NSString stringWithFormat:@"%f", endTimeInterval];
                NSArray * endArr = [endTime componentsSeparatedByString:@"."];
                NSString * end = [endArr objectAtIndex:0];
                NSString * location = event.location;
                NSString * detailInfo = nil;
                if (!description || [description isEqualToString:@""]) {
                    detailInfo = [NSString  stringWithFormat:@"{id:'%@',title:'%@',description:'',startTime:'%@',endTime:'%@',location:'%@'}", eventId,title,start,end,location];
                } else {
                    detailInfo = [NSString  stringWithFormat:@"{id:'%@',title:'%@',description:'%@',startTime:'%@',endTime:'%@',location:'%@'}", eventId,title,description,start,end,location];
                }
                [_resultArray addObject:detailInfo];
            }
            
            NSString *_callbackName = [parms objectAtIndex:2];
            //回调函数名_callbackName
            doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
            //_invokeResult设置返回值
            [_invokeResult SetResultArray:_resultArray];
            
            [_scritEngine Callback:_callbackName :_invokeResult];
        }
    }];
    
}
- (void)update:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    if (![_dictParas objectForKey:@"id"]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"必填参数遗漏"];
        return;
    }
    
    NSString * updateId = [doJsonHelper GetOneText:_dictParas :@"id" :@""];
    NSString * title = [doJsonHelper GetOneText:_dictParas :@"title" :@""];
    NSString * description = [doJsonHelper GetOneText:_dictParas :@"description" :@""];
    NSString * startTimeStr = [doJsonHelper GetOneText:_dictParas :@"startTime" :@""];
    NSString * endTimeStr = [doJsonHelper GetOneText:_dictParas :@"endTime" :@""];
    NSString * location = [doJsonHelper GetOneText:_dictParas :@"location" :@""];
    
    if ([updateId isEqualToString:@""]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"id参数不能为空"];
        
        id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
        NSString *_callbackName = [parms objectAtIndex:2];
        doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
        [_invokeResult SetResultBoolean:false];
        [_scritEngine Callback:_callbackName :_invokeResult];
        return;
    }
    
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    EKEventStore * store = [[EKEventStore alloc] init];
    EKEvent * event = [store eventWithIdentifier:updateId];
   
    if (title && ![title isEqualToString:@""]) {
        event.title = title;
    }
    if (description && ![description isEqualToString:@""]) {
        event.notes = description;
    }
    //时间格式
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];

    if (startTimeStr && ![startTimeStr isEqualToString:@""]) {
        NSTimeInterval startTime = [startTimeStr doubleValue]/1000;
        NSDate * startTimeDate = [NSDate dateWithTimeIntervalSince1970:startTime];
        event.startDate = startTimeDate;
    }
    if (endTimeStr && ![endTimeStr isEqualToString:@""]) {
        NSTimeInterval endTime = [endTimeStr doubleValue]/1000;
        NSDate * endTimeDate = [NSDate dateWithTimeIntervalSince1970:endTime];
        event.endDate = endTimeDate;
    }
    if (location && ![location isEqualToString:@""]) {
        event.location = location;
    }
    
    NSError * err;
    BOOL updateResult = [store saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
    NSString *_callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    //_invokeResult设置返回值
    [_invokeResult SetResultBoolean:updateResult];
    
    
    [_scritEngine Callback:_callbackName :_invokeResult];
}

#pragma mark - private method
//时间参数错误，返回类型：string，返回值：空
- (void)returnValueWithParms:(NSArray *)parms {
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString * _callbackName = [parms objectAtIndex:2];
    doInvokeResult * _invokeResult = [[doInvokeResult alloc] init];
    [_invokeResult SetResultText:@""];
    [_scriptEngine Callback:_callbackName :_invokeResult];
}

@end
