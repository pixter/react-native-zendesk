
#import "RNZendeskChat.h"
#import <AnswerBotSDK/AnswerBotSDK.h>
#import <AnswerBotProvidersSDK/AnswerBotProvidersSDK.h>
#import <ChatSDK/ChatSDK.h>
#import <ChatProvidersSDK/ChatProvidersSDK.h>
#import <MessagingSDK/MessagingSDK.h>
#import <CommonUISDK/CommonUISDK.h>
#import <SupportSDK/SupportSDK.h>
#import <SupportProvidersSDK/SupportProvidersSDK.h>
#import <ZendeskCoreSDK/ZendeskCoreSDK.h>

@implementation RNZendeskChat

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(setVisitorInfo:(NSDictionary *)options) {
  ZDKChatAPIConfiguration *config = [[ZDKChatAPIConfiguration alloc] init];
  if (options[@"department"]) {
    config.department = options[@"department"];
  }
  if (options[@"tags"]) {
    config.tags = options[@"tags"];
  }
  config.visitorInfo = [[ZDKVisitorInfo alloc] initWithName:options[@"name"]
                                                email:options[@"email"]
                                                phoneNumber:options[@"phone"]];
  ZDKChat.instance.configuration = config;

  NSLog(@"Setting visitor info: department: %@ tags: %@, email: %@, name: %@, phone: %@", config.department, config.tags, config.visitorInfo.email, config.visitorInfo.name, config.visitorInfo.phoneNumber);
}

RCT_EXPORT_METHOD(chatConfiguration: (NSDictionary *)options) {
    ZDKChatConfiguration *chatConfiguration = [[ZDKChatConfiguration alloc] init];
    if (options[@"chatMenuActions"]) {
        chatConfiguration.chatMenuActions = options[@"chatMenuActions"];
    }
    if (options[@"isChatTranscriptPromptEnabled"]) {
        chatConfiguration.isChatTranscriptPromptEnabled = options[@"isChatTranscriptPromptEnabled"];
    }
    if (options[@"isPreChatFormEnabled"]) {
        chatConfiguration.isPreChatFormEnabled = options[@"isPreChatFormEnabled"];
    }
    if (options[@"isOfflineFormEnabled"]) {
        chatConfiguration.isOfflineFormEnabled = options[@"isOfflineFormEnabled"];
    }
    if (options[@"isAgentAvailabilityEnabled"]) {
        chatConfiguration.isAgentAvailabilityEnabled = options[@"isAgentAvailabilityEnabled"];
    }
}

RCT_EXPORT_METHOD(startChat:(NSDictionary *)options) {
  [self setVisitorInfo:options];

  dispatch_sync(dispatch_get_main_queue(), ^{
    [self startChatFunction:options];
  });
}

RCT_EXPORT_METHOD(showHelpCenter:(NSDictionary *)options) {
  [self setVisitorInfo:options];
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self showHelpCenterFunction:options];
  });
}

RCT_EXPORT_METHOD(setUserIdentity: (NSDictionary *)user) {
  if (user[@"token"]) {
    id<ZDKObjCIdentity> userIdentity = [[ZDKObjCJwt alloc] initWithToken:user[@"token"]];
    [[ZDKZendesk instance] setIdentity:userIdentity];
  } else {
    id<ZDKObjCIdentity> userIdentity = [[ZDKObjCAnonymous alloc] initWithName:user[@"name"] // name is nullable
                                          email:user[@"email"]]; // email is nullable
    [[ZDKZendesk instance] setIdentity:userIdentity];
  }
}

RCT_EXPORT_METHOD(init:(NSDictionary *)options) {
  [ZDKZendesk initializeWithAppId:options[@"appId"]
      clientId: options[@"clientId"]
      zendeskUrl: options[@"url"]];
  [ZDKSupport initializeWithZendesk: [ZDKZendesk instance]];
  [ZDKAnswerBot initializeWithZendesk:[ZDKZendesk instance] support:[ZDKSupport instance]];
  [ZDKChat initializeWithAccountKey:options[@"key"] queue:dispatch_get_main_queue()];
}

RCT_EXPORT_METHOD(initChat:(NSString *)key) {
  [ZDKChat initializeWithAccountKey:key queue:dispatch_get_main_queue()];
}

RCT_EXPORT_METHOD(openTicket:(NSDictionary *)options){
    dispatch_async(dispatch_get_main_queue(), ^{

      ZDKCustomField *phoneField = [[ZDKCustomField alloc] initWithFieldId:@360033143751 value:options[@"phone"]];
      ZDKCustomField *contractNumberField = [[ZDKCustomField alloc] initWithFieldId:@360033057132 value:options[@"contract_number"]];
      ZDKCustomField *emailField = [[ZDKCustomField alloc] initWithFieldId:@360034437452 value:options[@"email"]];
      ZDKCustomField *nameField = [[ZDKCustomField alloc] initWithFieldId:@360033143911 value:options[@"name"]];
      ZDKCustomField *motiveField = [[ZDKCustomField alloc] initWithFieldId:@360033095651 value:options[@"motive"]];
      ZDKCustomField *documentField = [[ZDKCustomField alloc] initWithFieldId:@360033102052 value:options[@"document"]];
      ZDKCustomField *submotiveField = [[ZDKCustomField alloc] initWithFieldId:options[@"submotiveField"] value:options[@"submotive"]];

      ZDKRequestUiConfiguration * config = [ZDKRequestUiConfiguration new];

      config.customFields =  @[phoneField,
                       contractNumberField,
                       emailField,
                       nameField,
                       motiveField,
                       submotiveField,
                       documentField];

      UIViewController *requestController = [ZDKRequestUi buildRequestUiWith:@[config]];
      UIViewController *nav = [[UINavigationController alloc] initWithRootViewController:requestController];

      UIWindow *window=[UIApplication sharedApplication].keyWindow;
      UIViewController *vc = [window rootViewController];
      [vc presentViewController:nav animated:true completion:nil];

    });
}


RCT_EXPORT_METHOD(setPrimaryColor:(NSString *)color) {
  [ZDKCommonTheme currentTheme].primaryColor = [UIColor colorWithRed: 0.00 green: 0.21 blue: 0.64 alpha: 1.00];
}

RCT_EXPORT_METHOD(openTicketList){
    dispatch_async(dispatch_get_main_queue(), ^{

        ZDKRequestListUiConfiguration * config = [ZDKRequestListUiConfiguration new];

        config.allowRequestCreation = NO;

        UIViewController *requestScreen = [ZDKRequestUi buildRequestListWith:@[config]];
        UIViewController *nav = [[UINavigationController alloc] initWithRootViewController:requestScreen];

        UIWindow *window=[UIApplication sharedApplication].keyWindow;
        UIViewController *vc = [window rootViewController];
        [vc presentViewController:nav animated:true completion:nil];

    });
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (void) showHelpCenterFunction:(NSDictionary *)options {
    NSError *error = nil;
    ZDKChatEngine *chatEngine = [ZDKChatEngine engineAndReturnError:&error];
    ZDKSupportEngine *supportEngine = [ZDKSupportEngine engineAndReturnError:&error];
    NSArray *engines = @[];
    ZDKMessagingConfiguration *messagingConfiguration = [ZDKMessagingConfiguration new];
    NSString *botName = @"ChatBot";
    if (options[@"botName"]) {
      botName = options[@"botName"];
    }
    if (options[@"withChat"]) {
      engines = @[(id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error]];
    }
    ZDKHelpCenterUiConfiguration* helpCenterUiConfig = [ZDKHelpCenterUiConfiguration new];
    helpCenterUiConfig.objcEngines = engines;
    ZDKArticleUiConfiguration* articleUiConfig = [ZDKArticleUiConfiguration new];
    articleUiConfig.objcEngines = engines;
     if (options[@"disableTicketCreation"]) {
         helpCenterUiConfig.showContactOptions = NO;
         articleUiConfig.showContactOptions = NO;
    }
    UIViewController* controller = [ZDKHelpCenterUi buildHelpCenterOverviewUiWithConfigs: @[helpCenterUiConfig, articleUiConfig]];
    // controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Close"
    //                                                                                    style: UIBarButtonItemStylePlain
    //                                                                                   target: self
    //                                                                                   action: @selector(chatClosedClicked)];

    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: controller];
    [topController presentViewController:navControl animated:YES completion:nil];
}

- (void) startChatFunction:(NSDictionary *)options {
    ZDKMessagingConfiguration *messagingConfiguration = [ZDKMessagingConfiguration new];
    NSString *botName = @"ChatBot";
    if (options[@"botName"]) {
      botName = options[@"botName"];
    }
    messagingConfiguration.name = botName;

    if (options[@"botImage"]) {
      messagingConfiguration.botAvatar = options[@"botImage"];
    }

    NSError *error = nil;
    NSMutableArray *engines = [[NSMutableArray alloc] init];
    if (options[@"chatOnly"]) {
      engines = @[
        (id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error]
    ];
    } else {
      engines = @[
        (id <ZDKEngine>) [ZDKAnswerBotEngine engineAndReturnError:&error],
        (id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error],
        (id <ZDKEngine>) [ZDKSupportEngine engineAndReturnError:&error],
      ];
    }
    ZDKChatConfiguration *chatConfiguration = [[ZDKChatConfiguration alloc] init];
    chatConfiguration.isPreChatFormEnabled = YES;
    chatConfiguration.isAgentAvailabilityEnabled = YES;

    UIViewController *chatController =[ZDKMessaging.instance buildUIWithEngines:engines
                                                                        configs:@[messagingConfiguration, chatConfiguration]
                                                                            error:&error];
    if (error) {
      NSLog(@"Error occured %@", error);
    }
    chatController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Close"
                                                                                       style: UIBarButtonItemStylePlain
                                                                                      target: self
                                                                                      action: @selector(chatClosedClicked)];


        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }

        UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: chatController];
        [topController presentViewController:navControl animated:YES completion:nil];
}

- (void) chatClosedClicked {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    [topController dismissViewControllerAnimated:TRUE completion:NULL];
}
@end
