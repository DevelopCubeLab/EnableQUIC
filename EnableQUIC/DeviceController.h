#import <Foundation/Foundation.h>

@interface DeviceController : NSObject

- (BOOL) RebootDevice;
- (void) Respring;
- (BOOL)setFileAttributes:(NSString *)filePath
              permissions:(int)permissions
                   owner:(NSString *)owner
                   group:(NSString *)group;

@end

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);
