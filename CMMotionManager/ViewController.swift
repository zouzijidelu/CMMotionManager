//
//  ViewController.swift
//  CMMotionManager
//
//  Created by wzb on 2023/7/15.
//
import UIKit
import CoreMotion
 
class ViewController: UIViewController {
    //用于显示数据信息
    @IBOutlet weak var textView: UITextView!
    var startTime: Int = 0

    @IBOutlet weak var timeLabel: UILabel!
    //运动管理器
    let motionManager = CMMotionManager()
    var fileHandle: FileHandle!
    //刷新时间间隔
    let timeInterval: TimeInterval = 0.001
    var updateTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        createFile()
    }
    
    func createFile() {
        guard var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        path.append("/imu0数据.txt")
//        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
//        } else {
//            try? FileManager.default.removeItem(atPath: path)
//        }
        fileHandle = FileHandle(forWritingAtPath: path)!
        self.write( str: "#timestamp [ns]    w_RS_S_x [rad s^-1]    w_RS_S_y [rad s^-1]    w_RS_S_z [rad s^-1]    a_RS_S_x [m s^-2]    a_RS_S_y [m s^-2]    a_RS_S_z [m s^-2]\n")
    }
     
    //点击获取当前陀螺仪数据
    @IBAction func getGyroData(_ sender: Any) {
        startTime = Int(Date().timeIntervalSince1970)
        //判断设备支持情况
        guard motionManager.isGyroAvailable else {
            self.textView.text = "\n当前设备不支持陀螺仪\n"
            return
        }
        //设置刷新时间间隔
        self.motionManager.gyroUpdateInterval = self.timeInterval
        self.motionManager.accelerometerUpdateInterval = self.timeInterval
        
        var text = ""
        var fileText = ""
         
//        //开始实时获取数据
        let queue = OperationQueue.current
        self.motionManager.startGyroUpdates(to: queue!, withHandler: { (gyroData, error) in })
        //检查传感器在设备中是否可用
        if motionManager.isAccelerometerAvailable {
            //使用推送的方式开始对传感器进行检测
            motionManager.startAccelerometerUpdates(to: .main, withHandler: {(accelerometerData:CMAccelerometerData?,error:Error?) -> Void in})
        }else{
            print("您的设备不支持此功能")
        }
        updateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { [weak self] (timer )in
            if let rotationRate = self?.motionManager.gyroData?.rotationRate {
                text = "";
                //fileText = "IMU   \(Date().milliStamp)"
                fileText = "\(Date().milliStamp)"
                text += "rotationRate-x: \(rotationRate.x)\n"
                
                text += "rotationRate-y: \(rotationRate.y)\n"
                text += "rotationRate-z: \(rotationRate.z)\n"
                fileText += "   \(rotationRate.x)   \(rotationRate.y)   \(rotationRate.z)"
                //self.textView.text = text
            }
            if let acceleration = self?.motionManager.accelerometerData?.acceleration {
                //获取设备在三个轴方向上的加速度  并在字符串末尾添加回车符
                text+="accelerometer-x:\(acceleration.x)\n"
                text+="accelerometer-y:\(acceleration.y)\n"
                text+="accelerometer-z:\(acceleration.z)"
                fileText += "   \(acceleration.x)   \(acceleration.y)   \(acceleration.z)\n"
                self?.write(str: fileText)
                self?.textView.text = text
            }
        })
    }
    
    func write(str: String) {
        
        fileHandle.seekToEndOfFile()
        fileHandle.write(str.data(using: .utf8)!)
    }
    
    @IBAction func removeFile(_ sender: Any) {
        guard var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        path.append("/imu0数据.txt")
        try? FileManager.default.removeItem(atPath: path)
    }
    
    @IBAction func stop(_ sender: Any) {
        self.motionManager.stopGyroUpdates()
        self.motionManager.stopAccelerometerUpdates()
        let time = Int(Date().timeIntervalSince1970) - startTime
        self.timeLabel.text = "时间: \(time) 秒"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension Date {

/// 获取当前 秒级 时间戳 - 10位
var timeStamp : String {
    let timeInterval: TimeInterval = self.timeIntervalSince1970
    let timeStamp = Int(timeInterval)
    return "\(timeStamp)"
}

/// 获取当前 毫秒级 时间戳 - 13位
var milliStamp : String {
    let timeInterval: TimeInterval = self.timeIntervalSince1970
    let millisecond = CLongLong(round(timeInterval*1000))
    return "\(millisecond)"
}
}
