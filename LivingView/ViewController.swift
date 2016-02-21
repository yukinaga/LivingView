//
//  ViewController.swift
//  LivingView
//
//  Created by Yukinaga Azuma on 2016/02/16.
//  Copyright © 2016年 aeroapps. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //----------Constants------------
    var sizeRatio:CGFloat = 50 //Base size of living view
    var speedRatio:CGFloat = 4 //Base speed of living view
    let growthCostant:CGFloat = 0.6 //Growth rate of living view
    let growthConsumptionConstant:CGFloat = 0.0025 //Resource consumption rate by growth
    var movementConsumptionConstant:CGFloat = 0.001 //Resource consumption rate by movemment
    let resourcePerArea:CGFloat = 8 //Total gained Resource in feeding area
    let deathThreshold:CGFloat = 0.2 //Living views smaller than this rate will die
    let predationConstant:CGFloat = 4 //Gain of predation
    let geneConformityThreshold:CGFloat = 0.01 //Border of species
    let mutationRange:CGFloat = 0.06 //Range of gene mutation
    //-------------------------------
    
    var timer = NSTimer()
    var livingViews:[LivingView] = []
    var feedingAreas:[CGRect] = []
    
    var borderLeft:CGFloat = 0
    var borderRight:CGFloat = 0
    var borderTop:CGFloat = 0
    var borderBottom:CGFloat = 0
    
    @IBOutlet var countLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 0.25, green: 0.5, blue: 0.7, alpha: 1.0)
        
        //Feeding Area
        let rowNumber = 8
        let columnNumber = 8
        let hSpace:CGFloat = self.view.frame.size.width/CGFloat(columnNumber)
        let vSpace:CGFloat = hSpace
        let leftSpace = (self.view.frame.size.width - hSpace*CGFloat(columnNumber))/2
        let topSpace = (self.view.frame.size.height - vSpace*CGFloat(rowNumber))/2
        for var i=0; i<columnNumber; ++i{
            for var j=0; j<rowNumber; ++j{
                if (i%2==0 && j%2==0) || (i%2==1 && j%2==1){
                    let rect = CGRectMake(leftSpace+hSpace*CGFloat(i), topSpace+vSpace*CGFloat(j), hSpace, vSpace)
                    feedingAreas.append(rect)
                }
            }
        }
        let bgView = UIView()
        bgView.frame = CGRectMake(leftSpace, topSpace, hSpace*CGFloat(columnNumber), vSpace*CGFloat(rowNumber))
        bgView.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(bgView)
        for var i=0; i<feedingAreas.count; i++ {
            let feedingView = UIView()
            feedingView.frame = feedingAreas[i]
            feedingView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            self.view.addSubview(feedingView)
        }
        
        //Border
        borderLeft = leftSpace
        borderRight = leftSpace + hSpace*CGFloat(rowNumber)
        borderTop = topSpace
        borderBottom = topSpace + vSpace*CGFloat(columnNumber)
        
        // First livig view
        let firstGenes:[CGFloat] = [
            //Speed
            0.5,
            //Max size
            0.5,
            //Prey
            0.5
        ]
        let livingView = LivingView()
        livingView.genes = firstGenes
        livingView.setSize(sizeRatio * firstGenes[1]*0.5)
        livingView.setSpeed(speedRatio)
        livingView.center = CGPointMake(CGRectGetMidX(feedingAreas[feedingAreas.count/2]), CGRectGetMidY(feedingAreas[feedingAreas.count/2+columnNumber/4]))
        livingView.setHerbivorousness()
        livingView.setColor()
        self.view.addSubview(livingView)
        livingViews.append(livingView)
        
        //Timer
        timer = NSTimer.scheduledTimerWithTimeInterval(
            0.02,
            target: self,
            selector: "doFrame",
            userInfo: nil,
            repeats: true
        )
    }
    
    func doFrame(){
        
        //Gain by area
        var allResourcedLVs = Array<Array<LivingView>>()
        for feedingArea in feedingAreas{
            var resourcedLVs:[LivingView] = []
            for livingView in livingViews {
                if livingView.center.x > feedingArea.origin.x &&
                livingView.center.x < feedingArea.origin.x + feedingArea.size.width &&
                livingView.center.y > feedingArea.origin.y &&
                livingView.center.y < feedingArea.origin.y + feedingArea.size.height
                {
                    resourcedLVs.append(livingView)
                }
            }
            allResourcedLVs.append(resourcedLVs)
        }
        for resourcedLVs in allResourcedLVs {
            if resourcedLVs.count == 0{
                continue
            }
            var totalSize:CGFloat = 0
            for livingView in resourcedLVs {
                totalSize += livingView.currentSize*livingView.currentSize
            }
            if totalSize == 0{
                continue
            }
            for livingView in resourcedLVs {
                livingView.areaGain = resourcePerArea/totalSize*livingView.currentSize*livingView.currentSize*livingView.herbivorousness
            }
        }
        
        //Move
        for livingView in livingViews {
            var randX = CGFloat(arc4random() % 201)
            randX -= 100
            randX /= 100
            randX *= livingView.baseSpeed
            var randY = CGFloat(arc4random() % 201)
            randY -= 100
            randY /= 100
            randY *= livingView.baseSpeed
            livingView.movementRecourceComsumption = 0
            livingView.movementRecourceComsumption = movementConsumptionConstant*livingView.currentSize*livingView.currentSize*abs(randX + randY)
            if livingView.center.x+randX < borderLeft {
                randX = abs(randX)
            }
            if livingView.center.x+randX > borderRight {
                randX = -abs(randX)
            }
            if livingView.center.y+randY < borderTop {
                randY = abs(randY)
            }
            if livingView.center.y+randY > borderBottom {
                randY = -abs(randY)
            }
            livingView.center = CGPointMake(
                livingView.center.x+randX,
                livingView.center.y+randY
            )
        }
        
        //Predation
        for livingView in livingViews {
            livingView.unMarkPredation()
        }
        for var i=0; i<livingViews.count; ++i{
            let lv1 = livingViews[i]
            for var j=i+1; j<livingViews.count; ++j{
                let lv2 = livingViews[j]
                let hRadius = lv1.frame.size.width/2 + lv2.frame.size.width/2
                let vRadius = lv1.frame.size.height/2 + lv2.frame.size.height/2
                let dx = abs(lv1.center.x - lv2.center.x)
                let dy = abs(lv1.center.y - lv2.center.y)
                if dx < hRadius && dy < vRadius {
                    var dG:CGFloat = 0
                    for var k=0; k<lv1.genes.count; ++k{
                        dG += (lv1.genes[k] - lv2.genes[k])*(lv1.genes[k] - lv2.genes[k])
                    }
                    if dG > geneConformityThreshold {
                        let lv1Gain = predationConstant*sqrt(lv1.currentSize)*lv1.genes[2]
                        let lv2Gain = predationConstant*sqrt(lv2.currentSize)*lv2.genes[2]
                        lv1.predationGain = lv1Gain - lv2Gain
                        lv2.predationGain = lv2Gain - lv1Gain
                        lv1.markPredation()
                        lv2.markPredation()
                    }
                }
             }
        }
        
        //Growth
        var deadLVs:[LivingView] = []
        for livingView in livingViews {
            let totalGain = livingView.areaGain-growthConsumptionConstant*(livingView.currentSize * livingView.currentSize) - livingView.movementRecourceComsumption + livingView.predationGain
            let nextSize = livingView.currentSize + growthCostant*totalGain/livingView.currentSize
            if nextSize < sizeRatio * livingView.genes[1] * deathThreshold {
                //Death
                deadLVs.append(livingView)
            }else{
                //Growh
                livingView.setSize(nextSize)
            }
        }
        
        //Vanish Dead LVs
        for deadLV in deadLVs {
            deadLV.removeFromSuperview()
            let idx = livingViews.indexOf(deadLV)
            if (idx != nil) {
                livingViews.removeAtIndex(idx!)
            }
        }
        deadLVs.removeAll()
        
        //Duplication
        var appedingLVs:[LivingView] = []
        for livingView in livingViews {
            if livingView.currentSize > livingView.genes[1] * sizeRatio {
                let copied = LivingView()
                copied.inherit(livingView.genes, mutationRange: mutationRange)
                copied.setSize(sizeRatio * copied.genes[1]*0.7071)
                copied.setSpeed(speedRatio)
                copied.center = livingView.center
                copied.setHerbivorousness()
                copied.setColor()
                self.view.addSubview(copied)
                appedingLVs.append(copied)
                
                livingView.setSize(sizeRatio * livingView.genes[1]*0.7071)
            }
        }
        livingViews += appedingLVs
        
        //Rest gain and consumption
        for livingView in livingViews {
            livingView.areaGain = 0
            livingView.predationGain = 0
        }
        
        //Show Number of living views
        countLabel.text = "\(livingViews.count)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

