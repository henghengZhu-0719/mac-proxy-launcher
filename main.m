#import <AppKit/AppKit.h>

@interface Launcher : NSObject <NSApplicationDelegate>
@property NSStatusItem *gptItem;
@property NSStatusItem *codeItem;
@property NSStatusItem *cursorItem;
@property NSString *proxy;
@property NSArray<NSString *> *proxies;
@property NSString *lastStatus;
@property NSMutableSet<NSString *> *launching;
@end
@implementation Launcher
- (void)applicationDidFinishLaunching:(NSNotification *)note {
    self.proxies = @[@"http://10.126.126.1:8787", @"http://10.144.144.1:8788"];
    NSString *saved = [NSUserDefaults.standardUserDefaults stringForKey:@"selectedProxy"];
    self.proxy = [self.proxies containsObject:saved] ? saved : self.proxies.firstObject;
    self.launching = [NSMutableSet new];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    self.gptItem = [NSStatusBar.systemStatusBar statusItemWithLength:24];
    self.codeItem = [NSStatusBar.systemStatusBar statusItemWithLength:24];
    self.cursorItem = [NSStatusBar.systemStatusBar statusItemWithLength:24];
    NSArray *items = @[self.gptItem, self.codeItem, self.cursorItem];
    NSArray *names = @[@"ChatGPT", @"Visual Studio Code", @"Cursor"];
    NSArray *symbols = @[@"bubble.left.and.bubble.right.fill", @"chevron.left.forwardslash.chevron.right", @"cursorarrow"];
    for (NSUInteger i = 0; i < items.count; i++) {
        NSStatusItem *item = items[i];
        NSString *filename = [names[i] stringByAppendingString:@".app"];
        NSString *path = [@"/Applications" stringByAppendingPathComponent:filename];
        if (![NSFileManager.defaultManager fileExistsAtPath:path])
            path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Applications"] stringByAppendingPathComponent:filename];
        NSImage *icon = [NSFileManager.defaultManager fileExistsAtPath:path] ?
            [NSWorkspace.sharedWorkspace iconForFile:path] :
            [NSImage imageWithSystemSymbolName:symbols[i] accessibilityDescription:names[i]];
        icon.size = NSMakeSize(16, 16);
        item.button.title = @"";
        item.button.image = icon;
        item.button.imagePosition = NSImageOnly;
        [item.button setAccessibilityLabel:names[i]];
    }
    self.gptItem.button.action = @selector(clickGPT:);
    self.codeItem.button.action = @selector(clickCode:);
    self.cursorItem.button.action = @selector(clickCursor:);
    for (NSStatusItem *item in items) {
        item.button.target = self;
        item.button.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
        [item.button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];
    }
    [self setStatus:@"先连接 EasyTier。左键启动或强制重启应用，右键选择代理或退出。"];
}
- (void)setStatus:(NSString *)text {
    self.lastStatus = text;
    NSString *tip = [NSString stringWithFormat:@"%@\n代理：%@\n右键选择代理或退出", text, self.proxy];
    self.gptItem.button.toolTip = [@"ChatGPT\n" stringByAppendingString:tip];
    self.codeItem.button.toolTip = [@"VS Code\n" stringByAppendingString:tip];
    self.cursorItem.button.toolTip = [@"Cursor\n" stringByAppendingString:tip];
}
- (void)showError:(NSString *)text {
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"未能启动应用";
    alert.informativeText = text;
    [alert addButtonWithTitle:@"好"];
    [alert runModal];
}
- (BOOL)showMenuIfNeeded:(NSStatusBarButton *)button {
    NSEvent *event = NSApp.currentEvent;
    if (event.type != NSEventTypeRightMouseUp) return NO;
    NSMenu *menu = [NSMenu new];
    NSMenuItem *heading = [[NSMenuItem alloc] initWithTitle:@"选择代理（适用于全部三个应用）" action:nil keyEquivalent:@""];
    heading.enabled = NO;
    [menu addItem:heading];
    menu.autoenablesItems = NO;
    for (NSString *proxy in self.proxies) {
        NSMenuItem *option = [[NSMenuItem alloc] initWithTitle:[proxy substringFromIndex:7] action:@selector(selectProxy:) keyEquivalent:@""];
        option.target = self;
        option.representedObject = proxy;
        option.state = [proxy isEqualToString:self.proxy] ? NSControlStateValueOn : NSControlStateValueOff;
        option.enabled = self.launching.count == 0;
        [menu addItem:option];
    }
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出代理启动器" action:@selector(terminate:) keyEquivalent:@""];
    quit.target = NSApp;
    [menu addItem:quit];
    [NSMenu popUpContextMenu:menu withEvent:event forView:button];
    return YES;
}
- (void)selectProxy:(NSMenuItem *)sender {
    NSString *selected = sender.representedObject;
    if (self.launching.count || ![self.proxies containsObject:selected]) return;
    self.proxy = selected;
    [NSUserDefaults.standardUserDefaults setObject:selected forKey:@"selectedProxy"];
    [self setStatus:@"已选择代理。点击应用图标，以所选代理启动或强制重启。"];
}
- (void)clickGPT:(NSStatusBarButton *)button {
    if (![self showMenuIfNeeded:button]) [self openChatGPT];
}
- (void)clickCode:(NSStatusBarButton *)button {
    if (![self showMenuIfNeeded:button]) [self openCode];
}
- (void)clickCursor:(NSStatusBarButton *)button {
    if (![self showMenuIfNeeded:button]) [self launch:@"Cursor" bundleID:@"com.todesktop.230313mzl4w4u92"];
}
- (void)openChatGPT { [self launch:@"ChatGPT" bundleID:@"com.openai.codex"]; }
- (void)openCode { [self launch:@"Visual Studio Code" bundleID:@"com.microsoft.VSCode"]; }
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
