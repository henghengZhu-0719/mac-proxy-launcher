#import <AppKit/AppKit.h>

@interface Launcher : NSObject <NSApplicationDelegate, NSMenuDelegate>
@property NSStatusItem *statusItem;
@property NSString *proxy;
@property NSString *lastStatus;
@property NSMutableSet<NSString *> *launching;
@end
@implementation Launcher
- (void)applicationDidFinishLaunching:(NSNotification *)note {
    self.proxy = @"http://10.126.126.1:8787";
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"selectedProxy"];
    self.launching = [NSMutableSet new];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    NSString *iconPath = [NSBundle.mainBundle pathForResource:@"LauncherIcon" ofType:@"png"];
    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    icon.size = NSMakeSize(18, 18);
    icon.template = NO;
    self.statusItem.button.image = icon;
    self.statusItem.button.imagePosition = NSImageOnly;
    [self.statusItem.button setAccessibilityLabel:@"代理启动器"];
    NSMenu *menu = [NSMenu new];
    menu.delegate = self;
    menu.autoenablesItems = NO;
    self.statusItem.menu = menu;
    [self setStatus:@"代理启动器"];
}
- (void)setStatus:(NSString *)text {
    self.lastStatus = text;
    self.statusItem.button.toolTip = [NSString stringWithFormat:@"%@\n%@", text, self.proxy];
}
- (void)menuNeedsUpdate:(NSMenu *)menu {
    [menu removeAllItems];
    NSArray *names = @[@"ChatGPT", @"Visual Studio Code", @"Cursor", @"Antigravity", @"Antigravity IDE"];
    NSArray *symbols = @[@"bubble.left.and.bubble.right.fill", @"chevron.left.forwardslash.chevron.right", @"cursorarrow", @"sparkles", @"hammer"];
    NSArray *bundleIDs = @[@"com.openai.codex", @"com.microsoft.VSCode", @"com.todesktop.230313mzl4w4u92", @"com.google.antigravity", @"com.google.antigravity-ide"];
    for (NSUInteger i = 0; i < names.count; i++) {
        NSString *name = names[i];
        BOOL launching = [self.launching containsObject:name];
        NSString *title = launching ? [name stringByAppendingString:@"…"] : name;
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(selectApplication:) keyEquivalent:@""];
        item.target = self;
        item.representedObject = @{@"name":name, @"bundleID":bundleIDs[i]};
        item.enabled = !launching;
        item.toolTip = @"启动或强制重启";
        NSString *filename = [name stringByAppendingString:@".app"];
        NSString *path = [@"/Applications" stringByAppendingPathComponent:filename];
        if (![NSFileManager.defaultManager fileExistsAtPath:path])
            path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Applications"] stringByAppendingPathComponent:filename];
        NSImage *image = [NSFileManager.defaultManager fileExistsAtPath:path] ?
            [NSWorkspace.sharedWorkspace iconForFile:path] :
            [NSImage imageWithSystemSymbolName:symbols[i] accessibilityDescription:name];
        image.size = NSMakeSize(16, 16);
        item.image = image;
        [menu addItem:item];
    }
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *proxyItem = [[NSMenuItem alloc] initWithTitle:[self.proxy substringFromIndex:7] action:nil keyEquivalent:@""];
    proxyItem.enabled = NO;
    [menu addItem:proxyItem];
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出" action:@selector(terminate:) keyEquivalent:@""];
    quit.target = NSApp;
    [menu addItem:quit];
}
- (void)selectApplication:(NSMenuItem *)sender {
    NSDictionary *application = sender.representedObject;
    [self launch:application[@"name"] bundleID:application[@"bundleID"]];
}
- (void)showError:(NSString *)text {
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"未能启动应用";
    alert.informativeText = text;
    [alert addButtonWithTitle:@"好"];
    [alert runModal];
}
- (void)launch:(NSString *)name bundleID:(NSString *)bundleID {
    if ([self.launching containsObject:name]) return;
    NSURL *url = nil;
    NSArray *folders = @[@"/Applications", [NSHomeDirectory() stringByAppendingPathComponent:@"Applications"]];
    for (NSString *folder in folders) {
        NSString *path = [folder stringByAppendingPathComponent:[name stringByAppendingString:@".app"]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { url=[NSURL fileURLWithPath:path]; break; }
    }
    if (!url) url = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:bundleID];
    if (!url) { [self setStatus:[NSString stringWithFormat:@"找不到 %@，请先安装到“应用程序”。",name]]; [self showError:self.lastStatus]; return; }
    NSString *actualID = [NSBundle bundleWithURL:url].bundleIdentifier ?: bundleID;
    NSArray<NSRunningApplication *> *running = [NSRunningApplication runningApplicationsWithBundleIdentifier:actualID];
    [self.launching addObject:name];
    if (running.count) {
        [self setStatus:[NSString stringWithFormat:@"正在强制退出并重启 %@…",name]];
        for (NSRunningApplication *app in running) {
            if (!app.terminated && ![app forceTerminate]) {
                [self.launching removeObject:name];
                [self setStatus:[NSString stringWithFormat:@"无法退出 %@，请手动退出后再试。",name]];
                [self showError:self.lastStatus];
                return;
            }
        }
        [self waitForExit:running url:url name:name deadline:[NSDate dateWithTimeIntervalSinceNow:10]];
    } else {
        [self openURL:url name:name];
    }
}
- (void)waitForExit:(NSArray<NSRunningApplication *> *)apps url:(NSURL *)url name:(NSString *)name deadline:(NSDate *)deadline {
    BOOL stopped = YES;
    for (NSRunningApplication *app in apps) {
        if (!app.terminated) { stopped = NO; break; }
    }
    if (stopped) { [self openURL:url name:name]; return; }
    if (deadline.timeIntervalSinceNow <= 0) {
        [self.launching removeObject:name];
        [self setStatus:[NSString stringWithFormat:@"等待 %@ 退出超时，请手动检查后重试。",name]];
        [self showError:self.lastStatus];
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self waitForExit:apps url:url name:name deadline:deadline];
    });
}
- (void)openURL:(NSURL *)url name:(NSString *)name {
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
    config.activates = YES;
    config.environment = @{@"HTTP_PROXY":self.proxy, @"HTTPS_PROXY":self.proxy,
        @"http_proxy":self.proxy, @"https_proxy":self.proxy, @"ALL_PROXY":@"", @"all_proxy":@"",
        @"NO_PROXY":@"localhost,127.0.0.1,::1", @"no_proxy":@"localhost,127.0.0.1,::1"};
    config.arguments = @[[ @"--proxy-server=" stringByAppendingString:self.proxy], @"--proxy-bypass-list=localhost;127.0.0.1;[::1]"];
    [self setStatus:[NSString stringWithFormat:@"正在通过代理启动 %@…",name]];
    [NSWorkspace.sharedWorkspace openApplicationAtURL:url configuration:config completionHandler:^(NSRunningApplication *app, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.launching removeObject:name];
            [self setStatus:error ? [@"启动失败：" stringByAppendingString:error.localizedDescription] :
                [NSString stringWithFormat:@"已启动 %@。若页面无法联网，请检查 EasyTier 连接。",name]];
            if (error) [self showError:self.lastStatus];
        });
    }];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return NO; }
@end
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = NSApplication.sharedApplication;
        Launcher *delegate = [Launcher new];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
