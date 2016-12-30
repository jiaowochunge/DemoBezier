//
//  SpeedBezier.m
//  MABOT
//
//  Created by john on 2016/12/20.
//  Copyright © 2016年 BOLO. All rights reserved.
//

#import "SpeedBezier.h"

static NSString *ChangeSpeedActionKey2 = @"changeSpeedActionKey2";

@interface SpeedBezier()

@property (nonatomic, assign) NSInteger speedMin;

@property (nonatomic, assign) NSInteger speedMax;

@property (nonatomic, assign, readwrite) NSInteger speedCurrent;

@property (nonatomic, assign) BOOL trackMode;

@property (nonatomic, strong) SKSpriteNode *speedAddButton;

@property (nonatomic, strong) SKSpriteNode *speedSubButton;

@property (nonatomic, strong) SKShapeNode *speedProgress;

@property (nonatomic, weak) SKShapeNode *speedProgressBG;

// 当前操作的按钮。touchEnd 中移除动作
@property (nonatomic, weak) SKSpriteNode *actionButton;

@end

@implementation SpeedBezier

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        
        _speedMin = 0;
        _speedMax = 100;
        _speedCurrent = 50;
        
        // 加减按钮
        self.speedAddButton = [SKSpriteNode spriteNodeWithImageNamed:@"speed_plus"];
        _speedAddButton.zPosition = 15;
        _speedAddButton.position = CGPointMake(114, 0);
        [self addChild:_speedAddButton];
        
        self.speedSubButton = [SKSpriteNode spriteNodeWithImageNamed:@"speed_minus"];
        _speedSubButton.zPosition = 15;
        _speedSubButton.position = CGPointMake(-104, 0);
        [self addChild:_speedSubButton];
        
        // 进度条蓝色背景
        SKShapeNode *progressBG = [SKShapeNode node];
        progressBG.path = [self progressPath:1].CGPath;
        progressBG.fillColor = [SKColor colorWithRed:55 / 255.0 green:207 / 255.0 blue:247 / 255.0 alpha:1];
        progressBG.strokeColor = progressBG.fillColor;
        progressBG.zPosition = 10;
        progressBG.position = CGPointZero;
        [self addChild:progressBG];
        self.speedProgressBG = progressBG;
        
        // 进度条
        self.speedProgress = [SKShapeNode node];
        _speedProgress.position = CGPointZero;
        _speedProgress.zPosition = 20;
        _speedProgress.fillColor = [SKColor colorWithRed:255 / 255.0 green:235 / 255.0 blue:149 / 255.0 alpha:1];
        _speedProgress.strokeColor = _speedProgress.fillColor;
        [self updateSpeedProgress];
        [self addChild:_speedProgress];
    }
    return self;
}

/** 根据进度返回对应bezier曲线
 * @param r 进度 [0, 1]
 * @return 贝塞尔曲线
 */
- (UIBezierPath *)progressPath:(CGFloat)r
{
    NSParameterAssert(r >= 0 && r <=1);
    // 两条贝塞尔曲线的控制点。我觉得这个应该是2次曲线，但不知道为什么2次曲线有些误差
    CGPoint u_p1 = CGPointMake(-78, 0), u_p2 = CGPointMake(7, 51.25), u_p3 = CGPointMake(67.67, 1.93), u_p4 = u_p3;
    CGPoint d_p1 = u_p1, d_p2 = CGPointMake(-0.5, 58.2), d_p3 = CGPointMake(92, 13.8), d_p4 = d_p3;
    // 计算subCurve控制点
    CGPoint s_u_p1 = u_p1;
    CGPoint s_u_p2 = CGPointMake(r * u_p2.x - (r - 1) * u_p1.x,
                                 r * u_p2.y - (r - 1) * u_p1.y);
    CGPoint s_u_p3 = CGPointMake(r * r * u_p3.x - 2 * r * (r - 1) * u_p2.x + (r - 1) * (r - 1) * u_p1.x,
                                 r * r * u_p3.y - 2 * r * (r - 1) * u_p2.y + (r - 1) * (r - 1) * u_p1.y);
    CGPoint s_u_p4 = CGPointMake(r * r * r * u_p4.x  - 3 * r * r * (r - 1) * u_p3.x + 3 * r * (r - 1) * (r - 1) * u_p2.x - (r - 1) * (r - 1) * (r - 1) * u_p1.x,
                                 r * r * r * u_p4.y  - 3 * r * r * (r - 1) * u_p3.y + 3 * r * (r - 1) * (r - 1) * u_p2.y - (r - 1) * (r - 1) * (r - 1) * u_p1.y);
    CGPoint s_d_p1 = d_p1;
    CGPoint s_d_p2 = CGPointMake(r * d_p2.x - (r - 1) * d_p1.x,
                                 r * d_p2.y - (r - 1) * d_p1.y);
    CGPoint s_d_p3 = CGPointMake(r * r * d_p3.x - 2 * r * (r - 1) * d_p2.x + (r - 1) * (r - 1) * d_p1.x,
                                 r * r * d_p3.y - 2 * r * (r - 1) * d_p2.y + (r - 1) * (r - 1) * d_p1.y);
    CGPoint s_d_p4 = CGPointMake(r * r * r * d_p4.x  - 3 * r * r * (r - 1) * d_p3.x + 3 * r * (r - 1) * (r - 1) * d_p2.x - (r - 1) * (r - 1) * (r - 1) * d_p1.x,
                                 r * r * r * d_p4.y  - 3 * r * r * (r - 1) * d_p3.y + 3 * r * (r - 1) * (r - 1) * d_p2.y - (r - 1) * (r - 1) * (r - 1) * d_p1.y);
    UIBezierPath* path = UIBezierPath.bezierPath;
    // 从起点开始绘制
    [path moveToPoint: s_u_p1];
    [path addCurveToPoint: s_u_p4 controlPoint1: s_u_p2 controlPoint2: s_u_p3];
    // 回到起点，绘制下面一条曲线。因为反过来从终点开始绘制计算很麻烦，我们上面的计算也不是从终点开始绘制的，而是从起点开始绘制的
    [path moveToPoint:s_d_p1];
    [path addCurveToPoint: s_d_p4 controlPoint1: s_d_p2 controlPoint2: s_d_p3];
    // 连接两条曲线终点，闭合图形
    [path addLineToPoint:s_u_p4];
    return path;
}

// 绘制速度进度条
- (void)updateSpeedProgress
{
    CGFloat p = (CGFloat)_speedCurrent / _speedMax;
    _speedProgress.path = [self progressPath:p].CGPath;
}

- (void)addSpeedAction
{
    [self changeSpeed:1];
}

- (void)subSpeedAction
{
    [self changeSpeed:-1];
}

- (void)changeSpeed:(NSInteger)value
{
    NSInteger speedCurrent = _speedCurrent + value;
    speedCurrent = MAX(speedCurrent, _speedMin);
    speedCurrent = MIN(speedCurrent, _speedMax);
    if (_speedCurrent == speedCurrent) {
        return;
    }
    // 注意使用 setter 方式赋值，不要使用 `_speedCurrent = speedCurrent` ,会导致 kvo 无效
    self.speedCurrent = speedCurrent;
    [self updateSpeedProgress];
    
    _speedProgress.hidden = _speedCurrent == 0;
}

- (void)changeSpeedTo:(NSInteger)value
{
    value = MAX(value, _speedMin);
    value = MIN(value, _speedMax);
    if (_speedCurrent == value) {
        return;
    }
    // 注意使用 setter 方式赋值，不要使用 `_speedCurrent = value` ,会导致 kvo 无效
    self.speedCurrent = value;
    [self updateSpeedProgress];
    
    _speedProgress.hidden = _speedCurrent == 0;
}

#pragma mark - touch event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint location = [touch locationInNode:self];
    NSArray *buttonArr = @[_speedSubButton, _speedAddButton];
    for (SKSpriteNode *button in buttonArr) {
        if ([button containsPoint:location]) {
            button.alpha = 0.7;
            
            // 每 0.1 秒修改一次
            SEL fn = NULL;
            if (button == _speedSubButton) {
                fn = @selector(subSpeedAction);
            } else {
                fn = @selector(addSpeedAction);
            }
            SKAction *changeAction = [SKAction performSelector:fn onTarget:self];
            SKAction *haltAction = [SKAction waitForDuration:0.1];
            SKAction *onceAction = [SKAction sequence:@[changeAction, haltAction]];
            SKAction *multiAction = [SKAction repeatActionForever:onceAction];
            [button runAction:multiAction withKey:ChangeSpeedActionKey2];
            _actionButton = button;
            break;
        }
    }
    if ([_speedProgressBG containsPoint:location]) {
        _trackMode = YES;
        
        NSInteger speed = _speedMax * (location.x - CGRectGetMinX(_speedProgressBG.frame)) / CGRectGetWidth(_speedProgressBG.frame);
        
        [self changeSpeedTo:speed];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (_trackMode) {
        UITouch *touch = touches.anyObject;
        CGPoint location = [touch locationInNode:self];
        
        NSInteger speed = _speedMax * (location.x - CGRectGetMinX(_speedProgressBG.frame)) / CGRectGetWidth(_speedProgressBG.frame);
        [self changeSpeedTo:speed];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (_actionButton) {
        _actionButton.alpha = 1.0;
        [_actionButton removeActionForKey:ChangeSpeedActionKey2];
    }
    if (_trackMode) {
        _trackMode = NO;
        UITouch *touch = touches.anyObject;
        CGPoint location = [touch locationInNode:self];
        // update progress
        NSInteger speed = _speedMax * (location.x - CGRectGetMinX(_speedProgressBG.frame)) / CGRectGetWidth(_speedProgressBG.frame);
        [self changeSpeedTo:speed];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
}

@end
