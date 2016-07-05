//
//  CircleChart.swift
//  ASPCircleChart
//
//  Created by Andrei-Sergiu Pițiș on 15/06/16.
//  Copyright © 2016 Andrei-Sergiu Pițiș. All rights reserved.
//

import UIKit

/**
Protocol that describes the datasource methods used by the CircleChart.
*/
@objc public protocol ASPCircleChartDataSource {
	func numberOfDataPoints() -> Int
	func dataPointAtIndex(index: Int) -> Int
	func dataPointsSum() -> Int
	func colorForDataPointAtIndex(index: Int) -> UIColor
}

/**
A simple chart that uses slices on a circle to represent data.
*/
@IBDesignable public class ASPCircleChart: UIView {
	
	/**
	The starting angle in radians. Default value starts from the top.
	*/
	public var initialAngle: CGFloat = 3.0 * CGFloat(M_PI_2)
	
	/**
	The width of the circle.
	*/
	@IBInspectable public var circleWidth: CGFloat = 10.0
	
	/**
	The spacing between items. Should be a value between 0.0 and 0.5.
	*/
	@IBInspectable public var itemSpacing: CGFloat = 0.07 {
		didSet {
			itemSpacing = max(0.0, min(0.5, itemSpacing))
		}
	}
	
	/**
	The datasource of the Chart.
	*/
	@IBOutlet public var dataSource: ASPCircleChartDataSource? {
		didSet {
			reloadDataSource()
		}
	}
	
	private var startPoint: Int = 0
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		reloadDataSource()
	}
	
	/**
	Reloads the datasource. Handles delete, insert and update animations.
	*/
	public func reloadDataSource() {
		if let dataSource = dataSource {
			let numberOfDataPoints = dataSource.numberOfDataPoints()
			
			let itemCount = layer.sublayers?.count ?? 0
			if itemCount < numberOfDataPoints {
				insertNewSlices(numberOfDataPoints - itemCount)
			} else {
				removeExtraSlices(itemCount - numberOfDataPoints)
			}
			
			updateSlices(numberOfDataPoints)
		}
	}
	
	private func insertNewSlices(itemsToInsert: Int) {
		let oldCount = layer.sublayers?.filter({ (item) -> Bool in
			return item is ASPCircleChartSliceLayer
		}).count ?? 0
		
		for index in 0..<itemsToInsert {
			let slice = ASPCircleChartSliceLayer()
			slice.frame = bounds
			slice.strokeWidth = circleWidth
			slice.strokeColor = dataSource!.colorForDataPointAtIndex(oldCount + index)
			layer.addSublayer(slice)
		}
	}
	
	private func removeExtraSlices(itemsToRemove: Int) {
		for _ in 0..<itemsToRemove {
			layer.sublayers?.last?.removeFromSuperlayer()
		}
	}
	
	private func updateSlices(itemsToUpdate: Int) {
		startPoint = 0
		
		var startAngle: CGFloat = initialAngle
		let maxPoint = dataSource!.dataPointsSum()
		
		let slices = layer.sublayers?.filter({ (item) -> Bool in
			return item is ASPCircleChartSliceLayer
		}) as? [ASPCircleChartSliceLayer] ?? []
		
		for index in 0..<slices.count {
			let slice = slices[index]
			let dataPoint = dataSource!.dataPointAtIndex(index)
			
			startPoint += dataPoint
			
			var endAngle: CGFloat = rangeMap(CGFloat(startPoint), min: 0.0, max: CGFloat(maxPoint), newMin: 0.0 + initialAngle, newMax: 2.0 * CGFloat(M_PI) + initialAngle)
			
			if endAngle - itemSpacing < startAngle && dataPoint > 0 {
				let tempAngle = endAngle - itemSpacing
				endAngle = startAngle
				startAngle = tempAngle
			} else if dataPoint > 0 {
				endAngle -= itemSpacing
			}
			
			if (startAngle != endAngle - itemSpacing) && dataPoint > 0 {
				slice.startAngle = startAngle
				slice.endAngle = endAngle
				slice.strokeWidth = circleWidth
				slice.strokeColor = dataSource!.colorForDataPointAtIndex(index)
				
				startAngle = endAngle + itemSpacing
			} else {
				slice.startAngle = startAngle
				slice.endAngle = startAngle
				startAngle += itemSpacing
			}
		}
	}
}