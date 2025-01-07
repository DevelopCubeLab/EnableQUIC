import Foundation

class FileUtils {
 
    // 检查Root权限的方法
    static func checkInstallPermission() -> Bool {
        let path = "/var/mobile/Library/Preferences"
        let writeable = access(path, W_OK) == 0
        return writeable
    }
    
    static func getNetworkdConfigStatus() -> [(String, Bool)] {
        // 文件路径
        let filePath = "/var/preferences/com.apple.networkd.plist"
        guard let plistDict = NSDictionary(contentsOfFile: filePath) as? [String: Any] else {
            return [] // 如果文件不存在或格式错误，返回空数组
        }

        // 存储状态信息
        var statusData: [(String, Bool)] = []

        // 读取 enable_quic
        if let enableQuic = plistDict["enable_quic"] as? Bool {
            statusData.append(("enable_quic", enableQuic))
        }

        // 读取 disable_quic_race
        if let disableQuicRace = plistDict["disable_quic_race"] as? Bool {
            statusData.append(("disable_quic_race", disableQuicRace))
        }

        // 读取 disable_quic_race5
        if let disableQuicRace5 = plistDict["disable_quic_race5"] as? Bool {
            statusData.append(("disable_quic_race5", disableQuicRace5))
        }

        return statusData
    }
    
    static func enableQUIC(statusItems: [(String, Bool)]) -> Bool {
        // 默认配置
        let defaultConfigItems: [(String, Bool)] = [
            ("enable_quic", true),
            ("disable_quic_race", false),
            ("disable_quic_race5", false)
        ]
        
        // 调用 editQUICProfile 传递系统支持的配置项和默认配置
        return editQUICProfile(statusItems: statusItems, defaultConfigItems: defaultConfigItems)
    }
    
    static func setDefaultQUICConfig(statusItems: [(String, Bool)]) -> Bool {
        // 默认配置
        let defaultConfigItems: [(String, Bool)] = [
            ("enable_quic", false),
            ("disable_quic_race", true),
            ("disable_quic_race5", true)
        ]
        
        // 调用 editQUICProfile 传递系统支持的配置项和默认配置
        return editQUICProfile(statusItems: statusItems, defaultConfigItems: defaultConfigItems)
    }
    
    static func customerQUICProfile(statusItems: [(String, Bool)]) -> Bool {
        return editQUICProfile(statusItems: statusItems, defaultConfigItems: nil)
    }
    
    static func setLockProfileAttributes() -> Bool {
        let deviceController = DeviceController()
        if !deviceController.setFileAttributes("/var/preferences/com.apple.networkd.plist", permissions: 0o444, owner: "root", group: "wheel") {
            return setOwnerAndPermissions(forFile: "/var/preferences/com.apple.networkd.plist", permissions: 0o444)
        }
        return true
    }
    
    private static func editQUICProfile(statusItems: [(String, Bool)], defaultConfigItems: [(String, Bool)]? = nil) -> Bool {
        if statusItems.isEmpty {
            return false
        }

        // 原始文件路径
        let originalFilePath = "/var/preferences/com.apple.networkd.plist"
        
        // 备份目录
        let backupDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("backups")
        let backupFilePath = backupDirectory.appendingPathComponent("com.apple.networkd.plist")
        
        // 内置默认配置仅包含键
        let builtInDefaultKeys: [String] = [
            "enable_quic",
            "disable_quic_race",
            "disable_quic_race5"
        ]
        
        do {
            let fileManager = FileManager.default
            
            // 创建备份目录
            if !fileManager.fileExists(atPath: backupDirectory.path) {
                try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            // 备份文件
            if !fileManager.fileExists(atPath: backupFilePath.path) {
                try fileManager.copyItem(atPath: originalFilePath, toPath: backupFilePath.path)

                // 设置备份文件权限和所有者
                let deviceController = DeviceController()
                let success = deviceController.setFileAttributes(backupFilePath.path, permissions: 0o644, owner: "root", group: "wheel")
                if !success {
                    NSLog("Failed to set file attributes for backup.")
                    setOwnerAndPermissions(forFile: backupFilePath.path, permissions: 0o644)
                }
            }

            // 加载原始文件内容
            guard let plistDict = NSMutableDictionary(contentsOfFile: originalFilePath) else {
                NSLog("Failed to load plist file.")
                return false
            }

            // 动态修改配置
            if let defaultItems = defaultConfigItems {
                // 使用 defaultConfigItems 中的值覆盖
                for (key, value) in defaultItems {
                    plistDict[key] = value
                }
            } else {
                // 使用内置的默认键，仅更新 statusItems 中的支持键
                for (key, value) in statusItems {
                    if builtInDefaultKeys.contains(key) {
                        plistDict[key] = value
                    }
                }
            }

            // 写回文件
            if plistDict.write(toFile: originalFilePath, atomically: true) {
                // 设置权限和所有者
                let deviceController = DeviceController()
                let success = deviceController.setFileAttributes(originalFilePath, permissions: 0o644, owner: "root", group: "wheel")
                if !success {
                    return setOwnerAndPermissions(forFile: originalFilePath, permissions: 0o644)
                }
                NSLog("QUIC configuration updated successfully.")
                return true
            } else {
                NSLog("Failed to write plist file.")
                return false
            }
        } catch {
            NSLog("Error: \(error)")
            return false
        }
    }
    
    @discardableResult
    static func setOwnerAndPermissions(forFile filePath: String, permissions: mode_t) -> Bool {
        guard !filePath.isEmpty else {
            print("File path is nil or empty.")
            return false
        }

        let fileSystemPath = (filePath as NSString).fileSystemRepresentation
        
        guard let rootUser = getpwnam("root"), let wheelGroup = getgrnam("wheel") else {
            print("Failed to get root user or wheel group.")
            return false
        }

        if chown(fileSystemPath, rootUser.pointee.pw_uid, wheelGroup.pointee.gr_gid) != 0 {
            perror("Failed to change file owner and group")
            return false
        }

        if chmod(fileSystemPath, permissions) != 0 {
            perror("Failed to change file permissions")
            return false
        }

        return true
    }




    
}
