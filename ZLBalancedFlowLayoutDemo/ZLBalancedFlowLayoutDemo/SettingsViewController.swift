//
//  SettingsViewController.swift
//  ZLBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 1/1/15.
//  Copyright (c) 2015 Zhixuan Lai. All rights reserved.
//

import UIKit

class SettingsViewController : UITableViewController {
    
    weak var demoViewController: ViewController?

    class func presentInViewController(viewController: ViewController) {
        var settingsViewController = SettingsViewController(style: .Grouped)
        settingsViewController.demoViewController = viewController
        viewController.presentViewController(UINavigationController(rootViewController: settingsViewController), animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done,  target: self, action: Selector("doneButtonAction:"))
    }
    
    var rowHeightLabel: UILabel?
    var numSectionsLabel: UILabel?
    var numRepetitionLabel: UILabel?

    // MARK: - Action
    func doneButtonAction(sender:UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func directionSwitchAction(sender:UISwitch) {
        demoViewController?.direction = sender.on ? .Vertical : .Horizontal
    }
    
    func rowHeightSliderAction(sender:UISlider) {
        demoViewController?.rowHeight = CGFloat(50 + sender.value * 100)
        rowHeightLabel?.text = "\(demoViewController!.rowHeight)"
    }

    func rowHeightSwitchAction(sender:UISwitch) {
        demoViewController?.enforcesRowHeight = sender.on
    }

    func numSectionsSliderAction(sender:UISlider) {
        demoViewController?.numSections = Int(1 + sender.value * 19)
        numSectionsLabel?.text = "\(demoViewController!.numSections)"
    }

    func numRepetitionsSliderAction(sender:UISlider) {
        demoViewController?.numRepetitions = Int(1 + sender.value * 19)
        numRepetitionLabel?.text = "\(demoViewController!.numRepetitions)"
    }

    
    // MARK: - Cells
    enum SettingsTableViewControllerSection: Int {
        case Direction, RowHeight, DataSource, Count
        
        enum DirectionRow: Int {
            case Direction, Count
        }
        
        enum RowHeightRow: Int {
            case RowHeight, EnforcesRowHeight, Count
        }
        
        enum DataSourceRow: Int {
            case NumSections, NumRepetitions, Count
        }
        
        static let sectionTitles = [Direction: "Scroll Direction", RowHeight: "Row Height", DataSource: ""]
        static let sectionCount = [Direction: DirectionRow.Count.rawValue, RowHeight: RowHeightRow.Count.rawValue, DataSource: DataSourceRow.Count.rawValue, ];
        
        func sectionHeaderTitle() -> String {
            if let sectionTitle = SettingsTableViewControllerSection.sectionTitles[self] {
                return sectionTitle
            } else {
                return "Section"
            }
        }
        
        func sectionRowCount() -> Int {
            if let sectionCount = SettingsTableViewControllerSection.sectionCount[self] {
                return sectionCount
            } else {
                return 0
            }
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return SettingsTableViewControllerSection.Count.rawValue
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsTableViewControllerSection(rawValue:section)!.sectionRowCount()
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingsTableViewControllerSection(rawValue:section)!.sectionHeaderTitle()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cellIdentifier = String(format: "s%li-r%li", indexPath.section, indexPath.row)
        var cell:UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        if cell==nil {
            cell = UITableViewCell(style: .Value1, reuseIdentifier: cellIdentifier)
        }
        
        cell.selectionStyle = .None
        switch SettingsTableViewControllerSection(rawValue:indexPath.section)! {
        case .Direction:
            switch SettingsTableViewControllerSection.DirectionRow(rawValue: indexPath.row)! {
            case .Direction:
                var directionSwith = UISwitch()
                directionSwith.addTarget(self, action: Selector("directionSwitchAction:"), forControlEvents: .ValueChanged)
                if let demoViewController = demoViewController {
                    directionSwith.on = demoViewController.direction == .Vertical
                }
                cell.accessoryView = directionSwith
                cell.textLabel!.text = "Vertical"
            default:
                cell.textLabel!.text = "Direction"
            }
        case .RowHeight:
            switch SettingsTableViewControllerSection.RowHeightRow(rawValue: indexPath.row)! {
            case .RowHeight:
                var slider = UISlider()
                slider.addTarget(self, action: Selector("rowHeightSliderAction:"), forControlEvents: .ValueChanged)
                if let demoViewController = demoViewController {
                    slider.value = Float((demoViewController.rowHeight-50)/100)
                    cell.detailTextLabel!.text = "\(demoViewController.rowHeight)"
                }
                cell.accessoryView = slider
                cell.textLabel!.text = "Height"
                rowHeightLabel = cell.detailTextLabel
            case .EnforcesRowHeight:
                var enforceSwith = UISwitch()
                enforceSwith.addTarget(self, action: Selector("rowHeightSwitchAction:"), forControlEvents: .ValueChanged)
                if let demoViewController = demoViewController {
                    enforceSwith.on = demoViewController.enforcesRowHeight
                }
                cell.accessoryView = enforceSwith
                cell.textLabel!.text = "Enforces Row Height"
            default:
                cell.textLabel!.text = "RowHeight"
            }
        case .DataSource:
            switch SettingsTableViewControllerSection.DataSourceRow(rawValue: indexPath.row)! {
            case .NumSections:
                var slider = UISlider()
                slider.addTarget(self, action: Selector("numSectionsSliderAction:"), forControlEvents: .ValueChanged)
                if let demoViewController = demoViewController {
                    slider.value = Float(demoViewController.numSections-1)/19.0
                    cell.detailTextLabel!.text = "\(demoViewController.numSections)"
                }
                cell.accessoryView = slider
                cell.textLabel!.text = "# Sections"
                numSectionsLabel = cell.detailTextLabel
            case .NumRepetitions:
                var slider = UISlider()
                slider.addTarget(self, action: Selector("numRepetitionsSliderAction:"), forControlEvents: .ValueChanged)
                if let demoViewController = demoViewController {
                    slider.value = Float(demoViewController.numRepetitions-1)/19.0
                    cell.detailTextLabel!.text = "\(demoViewController.numRepetitions)"
                }
                cell.accessoryView = slider
                cell.textLabel!.text = "# Repetitions"
                numRepetitionLabel = cell.detailTextLabel
            default:
                cell.textLabel!.text = "DataSource"
            }
        default:
            cell.textLabel!.text = "N/A"
        }
        
        
        return cell
    }
    
}