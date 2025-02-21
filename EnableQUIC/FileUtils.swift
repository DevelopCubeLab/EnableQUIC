import Foundation

class FileUtils {
 
    // 检查Root权限的方法
    static func checkInstallPermission() -> Bool {
        let path = "/var/mobile/Library/Preferences"
        let writeable = access(path, W_OK) == 0
        return writeable
    }
    
    static func getNetworkdConfigStatus() -> [(String, Bool)] {
        return getNetworkdConfigStatus(filePath: "/var/preferences/com.apple.networkd.plist")
    }
    
    static func getNetworkdConfigStatus(filePath: String) -> [(String, Bool)] {
        
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
        var defaultConfigItems: [(String, Bool)] = []
        
        if #available(iOS 15.0, *) { // iOS 15和iOS 16是一样的配置
            defaultConfigItems = [
                ("enable_quic", true),
                ("disable_quic_race", false),
                ("disable_quic_race5", false)
            ]
        } else { // iOS 14的配置
            defaultConfigItems = [
                ("disable_quic_race", false),
            ]
        }
        
        // 调用 editQUICProfile 传递系统支持的配置项和默认配置
        return editQUICProfile(statusItems: statusItems, defaultConfigItems: defaultConfigItems)
    }
    
    static func setDefaultQUICConfig(statusItems: [(String, Bool)]) -> Bool {
        
        // 默认配置
        var defaultConfigItems: [(String, Bool)] = []
        
        // 备份目录
        let backupFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("backups").appendingPathComponent("com.apple.networkd.plist")
        
        if FileManager.default.fileExists(atPath: backupFilePath.path) { // 如果备份文件存在，则先从备份中读取默认设置
            defaultConfigItems = getNetworkdConfigStatus(filePath: backupFilePath.path)
        }
        
        if defaultConfigItems.isEmpty { // 如果备份是空的或者没有备份，则直接提供默认设置
            if #available(iOS 15.5, *) { // iOS 15.5 ~ iOS 17.0 默认的配置
                defaultConfigItems = [
                    ("enable_quic", true),
                    ("disable_quic_race", true),
                    ("disable_quic_race5", true)
                ]
            } else if #available(iOS 15.0, *) { // iOS 15.0 ~ 15.4.1 默认的配置
                defaultConfigItems = [
                    ("enable_quic", false),
                    ("disable_quic_race", true),
                    ("disable_quic_race5", true)
                ]
            } else { // iOS 14的默认设置，理论上iOS 14是不支持的
                defaultConfigItems = [
                    ("disable_quic_race", true),
                ]
            }
        }
        
        // 调用 editQUICProfile 传递系统支持的配置项和默认配置
        return editQUICProfile(statusItems: statusItems, defaultConfigItems: defaultConfigItems)
    }
    
    static func customerQUICProfile(statusItems: [(String, Bool)]) -> Bool {
        return editQUICProfile(statusItems: statusItems, defaultConfigItems: nil)
    }
    
    static func setLockProfileAttributes(lock: Bool) -> Bool {
        let deviceController = DeviceController()
        return deviceController.setFileLock(lock)
//        return deviceController.setFileAttributes("/var/preferences/com.apple.networkd.plist", permissions: 0o444, owner: "root", group: "wheel")
    }
    
    /// 获取文件是否被锁定
    static func isFileLocked() -> Bool {
        var fileStat = stat()
        
        // 调用 stat() 获取文件信息
        if stat("/var/preferences/com.apple.networkd.plist", &fileStat) == 0 {
            // 判断文件是否具有 UF_IMMUTABLE (uchg) 标志
            return (fileStat.st_flags & UInt32(UF_IMMUTABLE)) != 0
        } else {
            print("Failed to get file attributes")
            return false
        }
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
                deviceController.setFileAttributes(backupFilePath.path, permissions: 0o644, owner: "root", group: "wheel")
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
                NSLog("QUIC configuration updated successfully.")
                return deviceController.setFileAttributes(originalFilePath, permissions: 0o644, owner: "root", group: "wheel")
            } else {
                NSLog("Failed to write plist file directly. Trying alternative method...")
                            
                // 备用方案：先写入 app 沙盒 tmp 目录，再复制回去
                let tmpDirectory = FileManager.default.temporaryDirectory
                let tmpFilePath = tmpDirectory.appendingPathComponent("com.apple.networkd.plist").path
                
                if plistDict.write(toFile: tmpFilePath, atomically: true) {
                    let deviceController = DeviceController()
                    if deviceController.moveFile(fromPath: tmpFilePath, toPath: originalFilePath) {
                        let success = deviceController.setFileAttributes(originalFilePath, permissions: 0o644, owner: "root", group: "wheel")
                        NSLog("QUIC configuration updated successfully via tmp copy.")
                        return success
                    } else {
                        NSLog("Failed to copy file from tmp to original location.")
                    }
                } else {
                    NSLog("Failed to write plist file to tmp directory.")
                }
                
            }
        } catch {
            NSLog("Error: \(error)")
            return false
        }
        
        return false
    }
    
}
