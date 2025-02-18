#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/mount.h>
@import Foundation;

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
        if (argc < 2) {
            NSLog(@"Usage: %s <lock|unlock>", argv[0]);
            return 1; // 参数不足，返回错误
        }

        NSString *action = [NSString stringWithUTF8String:argv[1]];
        NSString *filePath = @"/var/preferences/com.apple.networkd.plist";
        const char *cFilePath = [filePath UTF8String];

        // 判断是锁定还是解锁
        if ([action isEqualToString:@"lock"]) {
            if (chflags(cFilePath, UF_IMMUTABLE) != 0) {
                perror("Error setting immutable flag");
                return 2; // 锁定失败
            }
            NSLog(@"Successfully locked file: %@", filePath);
        } else if ([action isEqualToString:@"unlock"]) {
            if (chflags(cFilePath, 0) != 0) {
                perror("Error removing immutable flag");
                return 3; // 解锁失败
            }
            NSLog(@"Successfully unlocked file: %@", filePath);
        } else {
            NSLog(@"Invalid action. Use 'lock' or 'unlock'.");
            return 4; // 非法参数
        }

        return 0; // 成功
    }
}
