#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <pwd.h>
#include <grp.h>  // 导入组信息
#include <sys/types.h>

int main(int argc, char *argv[]) {
    if (argc != 5) {
        fprintf(stderr, "Usage: %s <file_path> <permissions> <owner> <group>\n", argv[0]);
        return 1;
    }

    const char *filePath = argv[1];
    int permissions = strtol(argv[2], NULL, 8);  // 转换成八进制权限
    const char *owner = argv[3];
    const char *group = argv[4];

    // 设置文件权限
    if (chmod(filePath, permissions) < 0) {
        perror("chmod failed");
        return 2;
    }

    // 设置文件所有者和组
    struct passwd *pwd = getpwnam(owner); // 获取用户ID
    struct group *grp = getgrnam(group);  // 获取组ID

    if (pwd == NULL || grp == NULL) {
        fprintf(stderr, "Failed to find user or group\n");
        return 3;
    }

    if (chown(filePath, pwd->pw_uid, grp->gr_gid) < 0) {
        perror("chown failed");
        return 4;
    }

    printf("File attributes set successfully\n");
    return 0;
}
