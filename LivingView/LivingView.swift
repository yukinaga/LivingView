//
//  LivingView.swift
//  LivingView
//
//  Created by Yukinaga Azuma on 2016/02/16.
//  Copyright © 2016年 aeroapps. All rights reserved.
//

import Foundation
import UIKit

class LivingView: UIView {
    
    var genes:[CGFloat] = []
    
    var baseSpeed:CGFloat = 0
    var currentSize:CGFloat = 0
    var areaGain:CGFloat = 0
    var predationGain:CGFloat = 0
    var movementRecourceComsumption:CGFloat = 0
    var herbivorousness:CGFloat = 0
    
    func inherit(originalGenes:[CGFloat], mutationRange:CGFloat){
        for var gene in originalGenes {
            var rand = CGFloat(arc4random() % 2001)
            rand -= 1000
            rand /= 1000
            let mutation = rand * abs(rand) * mutationRange
            gene += mutation
            if gene < 0.001 {
                gene = 0.001
            }
            genes.append(gene)
        }
        //Prey can't be larger than 1.
        if genes[2] > 1 {
            genes[2] = 1
        }
    }
    
    func setSize(lvSize:CGFloat){
        currentSize = lvSize
        self.frame = CGRectMake(
            self.frame.origin.x+(self.frame.size.width-lvSize)/2,
            self.frame.origin.y+(self.frame.size.height-lvSize)/2,
            lvSize,
            lvSize
        )
        self.layer.cornerRadius = currentSize/2*genes[2]
    }
    
    func setSpeed(speedRatio:CGFloat){
        baseSpeed = speedRatio * genes[0]
    }
    
    func setHerbivorousness(){
        if genes[2] > 1 {
            herbivorousness = 0
        }else{
            herbivorousness = 1-genes[2]
        }
    }
    
    func setColor(){
        self.backgroundColor = UIColor(red: genes[2], green: genes[1], blue: genes[0], alpha: 1.0)
    }
    
    func markPredation(){
        self.layer.borderColor = UIColor.redColor().CGColor
        self.layer.borderWidth = 1
    }

    func unMarkPredation(){
        self.layer.borderWidth = 0
    }
}
