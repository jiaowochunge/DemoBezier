//
//  GameScene.m
//  DemoBezier
//
//  Created by john on 2016/12/30.
//  Copyright © 2016年 BOLO. All rights reserved.
//

#import "GameScene.h"
#import "SpeedBezier.h"

@implementation GameScene {
    SpeedBezier *_speedNode;
    SKLabelNode *_label;
}

- (void)didMoveToView:(SKView *)view {
    // Setup your scene here
    self.backgroundColor = [SKColor lightGrayColor];
    
    _speedNode = [[SpeedBezier alloc] init];
    _speedNode.position = CGPointMake(0, - 40);
    [self addChild:_speedNode];

    [_speedNode addObserver:self forKeyPath:@"speedCurrent" options:NSKeyValueObservingOptionNew context:NULL];
    
    
    _label = [SKLabelNode labelNodeWithText:[NSString stringWithFormat:@"current speed: %d", _speedNode.speedCurrent]];
    _label.position = CGPointMake(0, 40);
    [self addChild:_label];
}

- (void)willMoveFromView:(SKView *)view
{
    [_speedNode removeObserver:self forKeyPath:@"speedCurrent"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    _label.text = [NSString stringWithFormat:@"current speed: %d", _speedNode.speedCurrent];
}

@end
