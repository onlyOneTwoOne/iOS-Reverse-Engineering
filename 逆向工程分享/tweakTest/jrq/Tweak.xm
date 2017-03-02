%hook MicroMessengerAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"hello World" delegate:nil cancelButtonTitle:@"cancel" otherButtonTitles: nil];
	[alertView show];
#pragma clang diagnostic pop


return %orig;
}

%end

