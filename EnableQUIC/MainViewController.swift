import UIKit
import AudioToolbox

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let versionCode = "1.0"
    
    var tableView = UITableView()
    
    var sectionTitles = [
        NSLocalizedString("Status_text", comment: ""),
        NSLocalizedString("Settings_text", comment: ""),
        NSLocalizedString("About_text", comment: "")
    ]
    
    var sections = [
        [],
        [NSLocalizedString("CFBundleDisplayName", comment: ""), NSLocalizedString("Restore_Default_Settings_text", comment: "")],
        [NSLocalizedString("Version_text", comment: ""), "GitHub", NSLocalizedString("How_It_Works_text", comment: ""), NSLocalizedString("Introduction_QUIC_text", comment: ""), NSLocalizedString("Reference_text", comment: "")]
    ]
    
    var statusItems: [(String, Bool)] = []
    
    var hasRootPermission = false
    var clickIconImageTimes = 0
    var showAdvancedItems = false // 是否显示高级设置
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 设置背景颜色
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        // 设置标题
        self.title = NSLocalizedString("CFBundleDisplayName", comment: "")
        
        let iconImageView = UIImageView(image: UIImage(named: "icon"))
        // 禁用自动调整大小
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        // 设置图片适应方式
        iconImageView.contentMode = .scaleAspectFit
        
        // 向View中添加控件
        self.view.addSubview(iconImageView)
        
        // iOS 15 之后的版本使用新的UITableView样式
        if #available(iOS 15.0, *) {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }

        // 设置表格视图的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self

        // 注册表格单元格
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // 将表格视图添加到主视图
        view.addSubview(tableView)

        // 设置表格视图的布局
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 80),  // 设置宽度
            iconImageView.heightAnchor.constraint(equalToConstant: 80), // 设置高度
            iconImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor), // 水平居中
            iconImageView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50),
            
            tableView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        
        if !FileUtils.checkInstallPermission() {
            DispatchQueue.main.async {
                self.showAlertDialog(messags: NSLocalizedString("Need_Install_With_TrollStore_text", comment: ""), showRespringButton: false)
            }
            
            return
        } else {
            hasRootPermission = true
        }
        
        self.loadConfigData()
        
        // 给icon imageview添加点击手势以辅助启动高级设置
        iconImageView.isUserInteractionEnabled = true
        let clickGesture = UITapGestureRecognizer(target: self, action: #selector(onClickIconImageView))
        iconImageView.addGestureRecognizer(clickGesture)
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return statusItems.count
        } else if section == 3 {
            return statusItems.count + 3
        } else {
            return sections[section].count
        }
        
    }
    
    // MARK: - 设置每个分组的标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    // MARK: - 设置每个分组的末尾文本
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("Warning_message", comment: "")
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "AppCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "AppCell")
        
        //重置 Cell 状态 解决经典列表复用bug
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        if #available(iOS 13.0, *) {
            cell.textLabel?.textColor = .label
        }
        cell.accessoryView = nil
        cell.accessoryType = .none
//        cell.selectionStyle = .none
        cell.isUserInteractionEnabled = true
        
        if indexPath.section == 0 { //状态
            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
            cell.textLabel?.text = statusItems[indexPath.row].0 // key
            cell.detailTextLabel?.text = statusItems[indexPath.row].1 ? "True": "Flase" // value
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else if indexPath.section == 1 {
            cell.textLabel?.text = sections[indexPath.section][indexPath.row]
            if !hasRootPermission { // 处理无权限的问题
                cell.textLabel?.textColor = .lightGray //文本变成灰色
                cell.selectionStyle = .none
            } else {
                cell.selectionStyle = .default
                if indexPath.row == 0 {
                    cell.textLabel?.textAlignment = .center
                    cell.textLabel?.textColor = .systemRed
                } else if indexPath.row == 1 {
                    cell.textLabel?.textAlignment = .center
                    cell.textLabel?.textColor = .systemBlue
                }
            }
        } else if indexPath.section == 2 {
            cell.textLabel?.text = sections[indexPath.section][indexPath.row]
            if indexPath.row == 0 {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
                cell.textLabel?.text = sections[indexPath.section][indexPath.row]
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? NSLocalizedString("Unknown_text", comment: "")
                if version != versionCode { // 判断版本号是不是有人篡改
                    cell.detailTextLabel?.text = versionCode
                } else {
                    cell.detailTextLabel?.text = version
                }
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default // 启用选中效果
            }
        } else if indexPath.section == 3 {
            if indexPath.row < statusItems.count {
                cell.textLabel?.text = statusItems[indexPath.row].0 // key
                let switchView = UISwitch(frame: .zero)
                switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none // 禁止点击特效
                switchView.tag = indexPath.row
                switchView.isEnabled = true
                // 设置状态
                switchView.isOn = statusItems[indexPath.row].1
            } else if indexPath.row == statusItems.count {
                cell.textLabel?.text = NSLocalizedString("Save_text", comment: "")
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .systemBlue
            } else if indexPath.row == (statusItems.count + 1) {
                cell.textLabel?.text = NSLocalizedString("Lock_Permissions_text", comment: "")
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .systemRed
            } else if indexPath.row == (statusItems.count + 2) {
                cell.textLabel?.text = NSLocalizedString("Hide_Advanced_Settings_text", comment: "")
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .systemBlue
            }
            
        } else {
            cell.textLabel?.text = sections[indexPath.section][indexPath.row]
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate 点击item的事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 && hasRootPermission { // 设置
            tableView.deselectRow(at: indexPath, animated: true)
            if indexPath.row == 0 {
                let alert = UIAlertController(
                    title: NSLocalizedString("Alert_text", comment: ""), // 设置标题
                    message: NSLocalizedString("Enable_QUIC_message", comment: ""), // 设置文本提示
                    preferredStyle: .alert // 弹窗样式
                )
                
                // 添加确定按钮
                let confirmButton = UIAlertAction(title: NSLocalizedString("Confirm_text", comment: ""), style: .default // 按钮样式
                ) { _ in
                    // 按钮回调处理
                    if FileUtils.enableQUIC(statusItems: self.statusItems) {
                        // 刷新数据和列表
                        self.loadConfigData()
                        tableView.reloadData()
                        
                        self.showAlertDialog(messags: String.localizedStringWithFormat(NSLocalizedString("Enable_QUIC_Successful_text", comment: ""), FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path.appending("/backups/") ?? NSLocalizedString("Unknown_text", comment: "")), showRespringButton: true)
                        
                    } else {
                        self.showAlertDialog(messags: NSLocalizedString("Enable_QUIC_Failed_text", comment: ""), showRespringButton: false)
                    }
                }
                alert.addAction(confirmButton)
                // 添加取消按钮
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel_text", comment: ""), style: .cancel))
                // 显示弹窗
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }

            } else {
                let alert = UIAlertController(
                    title: NSLocalizedString("Alert_text", comment: ""), // 设置标题
                    message: NSLocalizedString("Restore_QUIC_message", comment: ""), // 设置文本提示
                    preferredStyle: .alert // 弹窗样式
                )
                
                // 添加确定按钮
                let confirmButton = UIAlertAction(title: NSLocalizedString("Confirm_text", comment: ""), style: .default // 按钮样式
                ) { _ in
                    // 按钮回调处理
                    if FileUtils.setDefaultQUICConfig(statusItems: self.statusItems) {
                        // 刷新数据和列表
                        self.loadConfigData()
                        tableView.reloadData()
                        
                        self.showAlertDialog(messags: NSLocalizedString("Restore_Config_Successful_text", comment: ""), showRespringButton: true)
                    } else {
                        self.showAlertDialog(messags: NSLocalizedString("Restore_Config_Failed_text", comment: ""), showRespringButton: false)
                    }
                }
                alert.addAction(confirmButton)
                // 添加取消按钮
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel_text", comment: ""), style: .cancel))
                // 显示弹窗
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
            }

        }
        if indexPath.section == 2 { // 关于
            tableView.deselectRow(at: indexPath, animated: true)
            if indexPath.row == 1 {
                if let url = URL(string: "https://github.com/DevelopCubeLab/EnableQUIC") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if indexPath.row == 2 {
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: NSLocalizedString("How_It_Works_text", comment: ""),
                        message: NSLocalizedString("Works_Principle_text", comment: ""),
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss_text", comment: ""), style: .cancel))
                    self.present(alert, animated: true)
                }
            } else if indexPath.row == 3 {
                if let url = URL(string: "https://developer.apple.com/videos/play/wwdc2021/10094/") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if indexPath.row == 4 {
                if let url = URL(string: "https://www.feng.com/post/13873305") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        if indexPath.section == 3 { // 高级设置
            if indexPath.row == (statusItems.count) {
                let alert = UIAlertController(
                    title: NSLocalizedString("Alert_text", comment: ""), // 设置标题
                    message: NSLocalizedString("Enable_QUIC_message", comment: ""), // 设置文本提示
                    preferredStyle: .alert // 弹窗样式
                )
                
                // 添加确定按钮
                let confirmButton = UIAlertAction(title: NSLocalizedString("Confirm_text", comment: ""), style: .default // 按钮样式
                ) { _ in
                    // 按钮回调处理
                    if FileUtils.customerQUICProfile(statusItems: self.statusItems) {
                        // 刷新数据和列表
                        self.loadConfigData()
                        tableView.reloadData()
                        
                        self.showAlertDialog(messags: NSLocalizedString("Save_Config_Successful_text", comment: ""), showRespringButton: true)
                    } else {
                        self.showAlertDialog(messags: NSLocalizedString("Save_Config_Failed_text", comment: ""), showRespringButton: false)
                    }
                }
                alert.addAction(confirmButton)
                // 添加取消按钮
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel_text", comment: ""), style: .cancel))
                // 显示弹窗
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
            } else if indexPath.row == (statusItems.count + 1) {
                // 锁定文件权限
                let alert = UIAlertController(
                    title: NSLocalizedString("Alert_text", comment: ""), // 设置标题
                    message: NSLocalizedString("Lock_QUIC_Config_message", comment: ""), // 设置文本提示
                    preferredStyle: .alert // 弹窗样式
                )
                
                // 添加确定按钮
                let confirmButton = UIAlertAction(title: NSLocalizedString("Confirm_text", comment: ""), style: .default // 按钮样式
                ) { _ in
                    // 按钮回调处理
                    if FileUtils.setLockProfileAttributes() {
                        // 刷新数据和列表
                        self.loadConfigData()
                        tableView.reloadData()
                        
                        self.showAlertDialog(messags: NSLocalizedString("Lock_QUIC_Config_Successful_text", comment: ""), showRespringButton: true)
                    } else {
                        self.showAlertDialog(messags: NSLocalizedString("Lock_QUIC_Config_Failed_text", comment: ""), showRespringButton: false)
                    }
                }
                alert.addAction(confirmButton)
                // 添加取消按钮
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel_text", comment: ""), style: .cancel))
                // 显示弹窗
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
            } else if indexPath.row == (statusItems.count + 2) {
                // 隐藏高级设置
                showAdvancedItems = false
                clickIconImageTimes = 0
                // 删除数据集
                sectionTitles.remove(at: 3)
                sections.remove(at: 3)
                // 刷新列表
                tableView.reloadData()
            }
        }
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        // 设置数据
        self.statusItems[sender.tag].1 = sender.isOn
    }
    
    override var canBecomeFirstResponder: Bool {
        // 仅在需要时启用摇动事件
        if showAdvancedItems {
            return false
        } else if clickIconImageTimes > 2 {
            return true
        }
        return false
    }

    func showAdvancedSettingItems() {
        showAdvancedItems = true
        // 停止监听摇动事件
        resignFirstResponder()
        
        sectionTitles.append(NSLocalizedString("Advanced_Settings_text", comment: ""))
        sections.append([])
        tableView.reloadData() // 刷新列表
        
    }
    
    func loadConfigData() {
        // 添加状态item
        statusItems = []
        statusItems = FileUtils.getNetworkdConfigStatus()
        if statusItems.count == 0 {
            DispatchQueue.main.async {
                self.showAlertDialog(messags: NSLocalizedString("Not_Supported_text", comment: ""), showRespringButton: false)
            }
        }
    }
    
    @objc func onClickIconImageView() {
        if self.hasRootPermission && !self.showAdvancedItems {
            self.clickIconImageTimes += 1 // 增加点击次数
            if self.clickIconImageTimes > 3 {
                becomeFirstResponder() // 开启摇动事件监听
            }
        }
        
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        if clickIconImageTimes >= 5 && !showAdvancedItems {
            // 显示高级设置并停止监听摇动事件
            showAdvancedSettingItems()
            // 震动
            AudioServicesPlaySystemSound(1521)
        }
    }
    
    func showAlertDialog(messags: String, showRespringButton: Bool) {
        let alert = UIAlertController(
            title: NSLocalizedString("Alert_text", comment: ""),
            message: messags,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss_text", comment: ""), style: .cancel))
        if showRespringButton {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Respiring_text", comment: ""), style: .default) { _ in
                let deviceController = DeviceController()
                deviceController.respring()
            })
        }
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

}

