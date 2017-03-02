//
//  autoGetRedEnv.m
//  autoGetRedEnv
//
//  Created by East on 16/3/21.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "CaptainHook.h"

/**
 *  插件功能
 */
static int const kCloseRedEnvPlugin = 0;
static int const kOpenRedEnvPlugin = 1;
static int const kCloseRedEnvPluginForMyself = 2;
static int const kCloseRedEnvPluginForMyselfFromChatroom = 3;

//0：关闭红包插件
//1：打开红包插件
//2: 不抢自己的红包
//3: 不抢群里自己发的红包
static int HBPliginType = 0;

#define SAVESETTINGS(key, value) { \
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); \
NSString *docDir = [paths objectAtIndex:0]; \
if (!docDir){ return;} \
NSMutableDictionary *dict = [NSMutableDictionary dictionary]; \
NSString *path = [docDir stringByAppendingPathComponent:@"HBPluginSettings.txt"]; \
[dict setObject:value forKey:key]; \
[dict writeToFile:path atomically:YES]; \
}

#define LOADSETTINGS(key) ({ \
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); \
NSString *docDir = [paths objectAtIndex:0]; \
if (!docDir){ return} \
NSString *path = [docDir stringByAppendingPathComponent:@"HBPluginSettings.txt"]; \
NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path]; \
if(!dict){ return} \
NSNumber *number = [dict objectForKey:key]; \
0})

CHDeclareClass(CMessageMgr);

CHMethod(2, void, CMessageMgr, AsyncOnAddMsg, id, arg1, MsgWrap, id, arg2)
{
    CHSuper(2, CMessageMgr, AsyncOnAddMsg, arg1, MsgWrap, arg2);
    //Ivar:定义对象的实例变量,包括类型和名字
    Ivar uiMessageTypeIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_uiMessageType");
    //获取成员变量的偏移量
    ptrdiff_t offset = ivar_getOffset(uiMessageTypeIvar);
    unsigned char *stuffBytes = (unsigned char *)(__bridge void *)arg2;
    //获取到消息类型
    NSUInteger m_uiMessageType = * ((NSUInteger *)(stuffBytes + offset));
    
    Ivar nsFromUsrIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsFromUsr");
    //获取到消息来源用户
    id m_nsFromUsr = object_getIvar(arg2, nsFromUsrIvar);
    
    Ivar nsContentIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsContent");
    //获取到消息内容
    id m_nsContent = object_getIvar(arg2, nsContentIvar);
    
    switch(m_uiMessageType) {
        case 49: {
            //防滥用
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *docDir = [paths objectAtIndex:0];
            NSString *path = [docDir stringByAppendingPathComponent:@"HBPluginSettings.txt"];
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
            NSNumber *hbSum = [dict objectForKey:@"ZRHBSum"];
            NSInteger hbint = hbSum.integerValue;
            NSLog(@"zr的抢红包log：dic:%@",dict);
            NSLog(@"zr的抢红包log：hbint：%ld",(long)hbint);
            if (hbint <= 5) {
                hbint ++;
                SAVESETTINGS(@"ZRHBSum", [NSNumber numberWithInteger:hbint]);
            }else {
                return;
            }
            
            //微信的服务中心，携程也是这么做的，抽象出service
            Method methodMMServiceCenter = class_getClassMethod(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
            IMP impMMSC = method_getImplementation(methodMMServiceCenter);
            id MMServiceCenter = impMMSC(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
            //红包控制器
            id logicMgr = ((id (*)(id, SEL, Class))objc_msgSend)(MMServiceCenter, @selector(getService:),objc_getClass("WCRedEnvelopesLogicMgr"));
            //通讯录管理器，稍后拼接红包参数用
            id contactManager = ((id (*)(id, SEL, Class))objc_msgSend)(MMServiceCenter, @selector(getService:),objc_getClass("CContactMgr"));
            Method methodGetSelfContact = class_getInstanceMethod(objc_getClass("CContactMgr"), @selector(getSelfContact));
            IMP impGS = method_getImplementation(methodGetSelfContact);
            id selfContact = impGS(contactManager, @selector(getSelfContact));
            
            if ([m_nsContent rangeOfString:@"wxpay://"].location != NSNotFound) {
                NSString *nativeUrl = m_nsContent;
                NSRange rangeStart = [m_nsContent rangeOfString:@"wxpay://c2cbizmessagehandler/hongbao"];
                if (rangeStart.location != NSNotFound) {
                    NSUInteger locationStart = rangeStart.location;
                    nativeUrl = [nativeUrl substringFromIndex:locationStart];
                }
                NSRange rangeEnd = [nativeUrl rangeOfString:@"]]"];
                if (rangeEnd.location != NSNotFound) {
                    NSUInteger locationEnd = rangeEnd.location;
                    nativeUrl = [nativeUrl substringToIndex:locationEnd];
                }
                NSString *naUrl = [nativeUrl substringFromIndex:[@"wxpay://c2cbizmessagehandler/hongbao/receivehongbao?" length]];
                NSArray *parameterPairs =[naUrl componentsSeparatedByString:@"&"];
                
                NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:[parameterPairs count]];
                for (NSString *currentPair in parameterPairs) {
                    NSRange range = [currentPair rangeOfString:@"="];
                    if(range.location == NSNotFound)
                        continue;
                    NSString *key = [currentPair substringToIndex:range.location];
                    NSString *value =[currentPair substringFromIndex:range.location + 1];
                    [parameters setObject:value forKey:key];
                }
                
                //红包参数
                NSMutableDictionary *params = [@{} mutableCopy];
                [params setObject:parameters[@"msgtype"]?:@"null" forKey:@"msgType"];
                [params setObject:parameters[@"sendid"]?:@"null" forKey:@"sendId"];
                [params setObject:parameters[@"channelid"]?:@"null" forKey:@"channelId"];
                id getContactDisplayName = objc_msgSend(selfContact, @selector(getContactDisplayName));
                id m_nsHeadImgUrl = objc_msgSend(selfContact, @selector(m_nsHeadImgUrl));
                [params setObject:getContactDisplayName forKey:@"nickName"];
                [params setObject:m_nsHeadImgUrl forKey:@"headImg"];
                [params setObject:[NSString stringWithFormat:@"%@", nativeUrl]?:@"null" forKey:@"nativeUrl"];
                [params setObject:m_nsFromUsr?:@"null" forKey:@"sessionUserName"];
                
                //自动抢红包
                ((void (*)(id, SEL, NSMutableDictionary*))objc_msgSend)(logicMgr, @selector(OpenRedEnvelopesRequest:), params);
                return;
            }
            break;
        }
        default:
            break;
    }
}

__attribute__((constructor)) static void entry()
{
    CHLoadLateClass(CMessageMgr);
    CHClassHook(2, CMessageMgr, AsyncOnAddMsg, MsgWrap);
}