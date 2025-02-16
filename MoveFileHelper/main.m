#include <stdio.h>
@import Foundation;

int main(int argc, char *argv[], char *envp[]) {
    @autoreleasepool {
        if (argc < 3) {
            NSLog(@"Usage: %s <source> <destination>", argv[0]);
            return 1; // 返回错误码 1，表示参数不足
        }
        
        uid_t uid = getuid();
        gid_t gid = getgid();
        NSLog(@"QUIC Helper------> Running as UID: %d, GID: %d", uid, gid);

        NSString *source = [NSString stringWithUTF8String:argv[1]];
        NSString *destination = [NSString stringWithUTF8String:argv[2]];
        NSError *error = nil;

        NSFileManager *fileManager = [NSFileManager defaultManager];

        // 先给 /var/preferences/ 赋予写入权限
        NSDictionary *attributes = @{NSFilePosixPermissions: @0777};
        NSError *chmodError = nil;
        [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:@"/var/preferences/" error:&chmodError];

        if (chmodError) {
            NSLog(@"QUIC Helper------> Failed to change permissions of /var/preferences/: %@", chmodError.localizedDescription);
        }
        
        // 确保源文件存在
        if (![fileManager fileExistsAtPath:source]) {
            NSLog(@"QUIC Helper------> Error: Source file does not exist at path %@", source);
            return 2; // 错误码 2：源文件不存在
        }

        // 目标文件如果已经存在，先删除
        if ([fileManager fileExistsAtPath:destination]) {
            if (![fileManager removeItemAtPath:destination error:&error]) {
                NSLog(@"QUIC Helper------> Error removing existing destination file: %@", error.localizedDescription);
//                return 3; // 错误码 3：无法删除目标文件
            }
        }

        // 移动文件
        if (![fileManager moveItemAtPath:source toPath:destination error:&error]) {
            NSLog(@"QUIC Helper------> Error moving file: %@", error.localizedDescription);
            return 4; // 错误码 4：移动文件失败
        }

        NSLog(@"QUIC Helper------> File moved successfully from %@ to %@", source, destination);
        return 0; // 成功
    }
}
