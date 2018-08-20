//
//  OverviewController.swift
//  Zendo
//
//  Created by Douglas Purdy on 7/8/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import HealthKit
import Mixpanel
import Charts

enum CurrentInterval: Int {
    case hour = 0
    case day = 1
    case month = 2
    case year = 3
    case all = 4
    
    var interval: Calendar.Component {
        switch self {
        case .hour: return .hour
        case .day: return .day
        case .month: return .month
        case .year: return .year
        case .all: return .day
        }
    }
    
    var range: Int {
        switch self {
        case .hour: return 24
        case .day: return 7
        case .month: return 1
        case .year: return 1
        case .all: return 7
        }
    }
    
}

class OverviewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var currentInterval: CurrentInterval = .hour
    
    let hkPredicate = HKQuery.predicateForWorkouts(with: .mindAndBody)
    let hkType = HKObjectType.workoutType()
    var start = Date()
    var end = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDate()
        
        tableView.backgroundColor = UIColor.clear
        tableView.estimatedRowHeight = 1000.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.locations = [0.0, 0.4]
        gradient.colors = [
            UIColor.zenDarkGreen.cgColor,
            UIColor.zenWhite.cgColor
        ]
        view.layer.insertSublayer(gradient, at: 0)
        view.backgroundColor = UIColor.zenWhite
        
        navigationController?.navigationBar.shadowImage = UIImage()
        
        NotificationCenter.default.addObserver(forName: .reloadOverview, object: nil, queue: .main) { (notification) in
            self.tableView.reloadData()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "overview_enter")
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().time(event: "overview_exit")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .reloadOverview, object: nil)
    }
    
    func populateCharts(_ cell: OverviewTableViewCell, _ currentInterval: CurrentInterval) {
        
        DispatchQueue.main.async() {
            cell.isHiddenHRV = true
            cell.durationView.setTitle("")
        }
        
        let formato = MMChartFormatter()
        formato.currentInterval = currentInterval
        let xaxis = XAxis()
        xaxis.valueFormatter = formato
        
        cell.hrvChart.highlightValues([])
        cell.hrvChart.drawGridBackgroundEnabled = false
        cell.hrvChart.chartDescription?.enabled = false
        cell.hrvChart.autoScaleMinMaxEnabled = true
        cell.hrvChart.noDataText = ""
        
        cell.hrvChart.xAxis.drawGridLinesEnabled = false
        cell.hrvChart.xAxis.drawAxisLineEnabled = false
        cell.hrvChart.rightAxis.drawAxisLineEnabled = false
        cell.hrvChart.leftAxis.drawAxisLineEnabled = false
        
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "ms")
        
        let communityEntries = [ChartDataEntry]()
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        
        communityDataset.setColor(UIColor.zenRed)
        communityDataset.lineWidth = 1.5
        communityDataset.lineDashLengths = [10, 3]
        
        dataset.drawValuesEnabled = false
        dataset.setColor(UIColor.zenDarkGreen)
        dataset.lineWidth = 1.5
        
        dataset.drawCirclesEnabled = true
        dataset.setCircleColor(UIColor.zenDarkGreen)
        dataset.circleRadius = 4
        
        dataset.drawCircleHoleEnabled = true
        dataset.circleHoleRadius = 3
        
        dataset.highlightEnabled = true
        
        // 00 - 0%
        // 80 - 50%
        let gradientColors = [
            ChartColorTemplates.colorFromString("#00277A69").cgColor,
            ChartColorTemplates.colorFromString("#80277A69").cgColor
        ]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        
        dataset.fillAlpha = 1
        dataset.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
        dataset.drawFilledEnabled = true
        
        let handler: ZBFHealthKit.SamplesHandler = { samples, error in
            cell.hrvChart.data?.clearValues()
            cell.hrvChart.data = LineChartData(dataSets: [dataset, communityDataset])
            if let samples = samples {
                samples.sorted(by: <).forEach( { entry in
                    
                    if entry.value > 0.0 {
                        cell.hrvChart.data!.addEntry(ChartDataEntry(x: entry.key, y: entry.value), dataSetIndex: 0)
                    }
                    
                    let community = self.getCommunityDataEntry(key: "sdnn", interval: entry.key, scale: 1.0)
                    
                    cell.hrvChart.data!.addEntry(community, dataSetIndex: 1)
                    
                    print("populateHRVChart: \(entry)")
                    
                })
            } else {
                cell.hrvChart.noDataText = "No HRV date"
                print(error.debugDescription)
            }
            
            DispatchQueue.main.async() {
                cell.hrvChart.data!.highlightEnabled = true
                cell.hrvChart.notifyDataSetChanged()
                cell.hrvChart.xAxis.valueFormatter = xaxis.valueFormatter
                cell.isHiddenHRV = false
                
                self.populateMMChart(cell: cell)
            }
        }
        
        ZBFHealthKit.getHRVSamples(start: start, end: end, currentInterval: currentInterval, handler: handler)
    }
    
    func getCommunityDataEntry(key: String, interval: Double, scale: Double) -> ChartDataEntry {
        var value = CommunityDataLoader.get(measure: key, at: interval)
        value = value * scale
        
        return ChartDataEntry(x: interval, y: value.rounded())
    }
    
    func populateHRV(_ cell: OverviewTableViewCell, _ currentInterval: CurrentInterval) {
        cell.hrvView.setTitle("")
        
        ZBFHealthKit.getHRVAverage(start: start, end: end) { (results, error) in
            if let results = results {
                let value = results.first!.value
                
                DispatchQueue.main.async() {
                    cell.hrvView.setTitle(Int(value.rounded()).description + "ms")
                }
            }
        }
    }
    
    func populateDatetimeSpan(_ cell: HeaderOverviewTableViewCell, _ currentInterval: CurrentInterval) {
        let date = Date().toLocalTime()
        switch currentInterval {
        case .hour:
            cell.dateTimeTitle.text = date.startOfDay.toZendoHeaderDayString
        case .day:
            cell.dateTimeTitle.text = date.startOfWeek.toZendoHeaderDayString + " - " + date.endOfWeek.toZendoHeaderDayString
        case .month:
            cell.dateTimeTitle.text = date.startOfMonth.toZendoHeaderMonthYearString
        case .year:
            cell.dateTimeTitle.text = date.startOfYear.toZendoHeaderYearString
        case .all: break
        }
        
    }
    
    func populateMMChart(cell: OverviewTableViewCell) {
        
        cell.isHiddenMM = true
        
        let formato = MMChartFormatter()
        formato.currentInterval = currentInterval
        let xaxis = XAxis()
        xaxis.valueFormatter = formato
        
        let formatoValue = MMChartValueFormatter()
        let xaxisValue = XAxis()
        xaxisValue.valueFormatter = formatoValue
       
        cell.mmChart.highlightValues([])
        cell.mmChart.xAxis.drawGridLinesEnabled = false
        cell.mmChart.xAxis.drawAxisLineEnabled = false
        cell.mmChart.rightAxis.drawAxisLineEnabled = false
        cell.mmChart.leftAxis.drawAxisLineEnabled = false
        
        cell.mmChart.drawGridBackgroundEnabled = false
        cell.mmChart.chartDescription?.enabled = false
        cell.mmChart.autoScaleMinMaxEnabled = true
        cell.mmChart.noDataText = ""
        
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "mins")
        
        let communityEntries = [ChartDataEntry]()
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        communityDataset.highlightEnabled = false
        
        communityDataset.setColor(UIColor.zenRed)
        communityDataset.lineWidth = 1.5
        communityDataset.lineDashLengths = [10, 3]
        
        dataset.drawValuesEnabled = false
        dataset.setColor(UIColor.zenDarkGreen)
        dataset.lineWidth = 1.5
        dataset.highlightEnabled = true
        
        dataset.drawCirclesEnabled = true
        dataset.setCircleColor(UIColor.zenDarkGreen)
        dataset.circleRadius = 4
        
        dataset.drawCircleHoleEnabled = true
        dataset.circleHoleRadius = 3
        
        // 00 - 0%
        // 80 - 50%
        let gradientColors = [
            ChartColorTemplates.colorFromString("#00277A69").cgColor,
            ChartColorTemplates.colorFromString("#80277A69").cgColor
        ]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        
        dataset.fillAlpha = 1
        dataset.fill = Fill(linearGradient: gradient, angle: 90)
        dataset.drawFilledEnabled = true
        
        ZBFHealthKit.getMindfulMinutes(start: start, end: end, currentInterval: currentInterval) { samples, error in
            DispatchQueue.main.async() {
                cell.mmChart.data?.clearValues()
                cell.mmChart.data = LineChartData(dataSets: [dataset, communityDataset])
            }
            var movingTotal = 0.0
            var movingTotalCount = 0.0
            
            if let samples = samples {
                
                let sam = samples.sorted(by: <)
                
                for var entry in sam {
                    
                    movingTotal += entry.value
                    
                    if entry.value > 0.0 {
                        movingTotalCount += 1
                    }
                    entry.value = (entry.value / 60.0).rounded()
                    
                    DispatchQueue.main.async() {
                        if entry.value > 0.0 {
                            cell.mmChart.data!.addEntry(ChartDataEntry(x: entry.key, y: entry.value), dataSetIndex: 0)
                        }
                        let community = ChartDataEntry(x: entry.key, y: 30.0)
                        cell.mmChart.data!.addEntry(community, dataSetIndex: 1)
                    }
                }
                DispatchQueue.main.async() {
                    cell.mmChart.data!.highlightEnabled = true
                    cell.mmChart.notifyDataSetChanged()
                    cell.mmChart.setNeedsDisplay()
                    cell.mmChart.xAxis.valueFormatter = xaxis.valueFormatter
                    cell.mmChart.rightAxis.valueFormatter = xaxisValue.valueFormatter
                    cell.isHiddenMM = false
                    
                    switch self.currentInterval {
                    case .hour: cell.durationView.setTitle(movingTotal.stringZendoTime)
                    default:
                        let avg = movingTotal / movingTotalCount
                        if avg.isNaN {
                            cell.durationView.setTitle(0.0.stringZendoTime)
                        } else {
                            cell.durationView.setTitle(avg.stringZendoTime)
                        }
                    }
                }
            }
        }
        
    }
    
    //#todo(debt): factor this into the zbfmodel + ui across controllers
    @IBAction func newSession(_ sender: Any) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        let store = HKHealthStore()
        
        store.startWatchApp(with: configuration) { success, error in
            guard success else {
                print (error.debugDescription)
                return
            }
        }
        
        Mixpanel.mainInstance().time(event: "new_session")
        
        let alert = UIAlertController(title: "Starting Watch App", message: "Deep Press + Exit when complete.", preferredStyle: .actionSheet)
        
        let ok = UIAlertAction(title: "Done", style: .default) { action in
            //            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1) ) {
            //                Mixpanel.mainInstance().track(event: "new_session")
            //            }
        }
        
        alert.addAction(ok)
        
        present(alert, animated: true)
    }
    
    func setDate() {
        let date = Date().toLocalTime()
        
        switch self.currentInterval {
        case .hour:
            self.start = date.startOfDay
            self.end = date.endOfDay
        case .day:
            self.start = date.startOfWeek
            self.end = date.endOfWeek
        case .month:
            self.start = date.startOfMonth
            self.end = date.endOfMonth
        case .year:
            self.start = date.startOfYear
            self.end = date.endOfYear
        case .all:
            break
        }
        
        
    }
    
}

extension OverviewController: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return stringForValue(value, self.currentInterval.interval)
    }
    
    func stringForValue(_ value: Double, _ interval: Calendar.Component) -> String {
        let date = Date(timeIntervalSince1970: value)
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent;
        
        switch interval {
        case .hour: dateFormatter.setLocalizedDateFormatFromTemplate("HH:mm")
        case .day: dateFormatter.setLocalizedDateFormatFromTemplate("MM-dd")
        case .month: dateFormatter.setLocalizedDateFormatFromTemplate("MM-dd")
        case .year: dateFormatter.setLocalizedDateFormatFromTemplate("MM")
        default: dateFormatter.setLocalizedDateFormatFromTemplate("MM")
        }
        
        let localDate = dateFormatter.string(from: date)
        
        return localDate.description
    }
    
}

extension OverviewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeaderOverviewTableViewCell.reuseIdentifierCell) as! HeaderOverviewTableViewCell
        populateDatetimeSpan(cell, currentInterval)
        cell.backgroundColor = UIColor.zenDarkGreen
        for button in cell.buttons {
            button.layer.cornerRadius = 5.0
            button.backgroundColor = button.tag == currentInterval.rawValue ? UIColor.white : UIColor.clear
            button.setTitleColor(button.tag == currentInterval.rawValue ? UIColor.zenDarkGreen : UIColor.white, for: .normal)
        }
        cell.action = { tag in
            self.currentInterval = CurrentInterval(rawValue: tag)!
            
            self.setDate()
            
            self.tableView.reloadData()

            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OverviewTableViewCell.reuseIdentifierCell, for: indexPath) as! OverviewTableViewCell
        
        if self.currentInterval == .hour {
            cell.durationView.zenInfoViewType = .totalMins
        } else {
            cell.durationView.zenInfoViewType = .minsAverage
        }
        
        populateHRV(cell, currentInterval)
        populateCharts(cell, currentInterval)
        
        return cell
    }
    
}


extension OverviewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 90.0
    }
    
}
