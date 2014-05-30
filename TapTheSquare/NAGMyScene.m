//
//  NAGMyScene.m
//  TapTheSquare
//
//  Created by AndrewShmig on 5/29/14.
//  Copyright (c) 2014 Non Atomic Games Inc. All rights reserved.
//

#import "NAGMyScene.h"

#define TILE_HEIGHT 50
#define TILE_WIDTH 50

@interface NAGMyScene ()
@property (nonatomic, getter=isFirstScreenVisible) BOOL firstScreenVisible;
@property NSUInteger score;
@property NSTimer *timer;

@property NSMutableSet *usedCells;
@property NSMutableSet *unusedCells;
@end


@implementation NAGMyScene

- (id)initWithSize:(CGSize)size
{
    NSLog(@"%s", __FUNCTION__);

    self = [super initWithSize:size];

    if (self) {
        self.backgroundColor = [SKColor colorWithRed:0.388
                                               green:0.259
                                                blue:0.875
                                               alpha:0];

        [self resetGameData];
        [self addChild:[self firstScreenLayer]];
    }

    return self;
}

#pragma mark - Scene

- (void)update:(NSTimeInterval)currentTime
{

}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s", __FUNCTION__);
    [self performTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s", __FUNCTION__);
    [self performTouches:touches];
}

- (void)performTouches:(NSSet *)touches
{
    NSLog(@"%s", __FUNCTION__);

    for (UITouch *touch in touches) {
        CGPoint pointInSKScene = [self
                .view convertPoint:[touch locationInView:self.view]
                           toScene:self];
        SKNode *touchedNode = [self nodeAtPoint:pointInSKScene];

        if (self.firstScreenVisible) {
            if ([touchedNode.name isEqualToString:@"playButton"]) {
                [touchedNode removeFromParent];
                self.firstScreenVisible = NO;
                [self startGame];
            }
        } else if (touchedNode.userData != nil){
            NSInteger points = [touchedNode.userData[@"points"] integerValue];
            self.score += points;

            [self.usedCells removeObject:touchedNode.name];
            [self.unusedCells addObject:touchedNode.name];

            [self animatePopupWithPointsInPosition:pointInSKScene];

            [touchedNode removeFromParent];
        }
    }
}

#pragma mark - Game

- (void)startGame
{
    NSLog(@"%s", __FUNCTION__);

    self.timer = [NSTimer timerWithTimeInterval:0.2
                                         target:self
                                       selector:@selector(generateNewSquare:)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop]
                addTimer:self.timer
                 forMode:NSDefaultRunLoopMode];
}

- (void)resetGameData
{
    NSLog(@"%s", __FUNCTION__);

    self.firstScreenVisible = YES;
    self.score = 0;

    self.unusedCells = [NSMutableSet new];
    for (NSInteger i = 0; i < [self fieldMaxCols]; i++) {
        for (NSInteger j = 0; j < [self fieldMaxRows]; j++) {
            NSString *cellName = [NSString stringWithFormat:@"%d_%d", i, j];
            [self.unusedCells addObject:cellName];
        }
    }

    self.usedCells = [NSMutableSet new];
}

- (void)generateNewSquare:(NSTimer *)timer
{
    NSLog(@"%s", __FUNCTION__);

    CGPoint newTilePosition = [self randomSquarePosition];
    CGPoint deadPoint = CGPointMake(-1, -1);

    if (CGPointEqualToPoint(newTilePosition, deadPoint)) {
        [timer invalidate];
        timer = nil;

        [self gameOver];

        return;
    }

//    generating new square
    NSInteger col = (NSInteger) (newTilePosition.x / TILE_WIDTH);
    NSInteger row = (NSInteger) (newTilePosition.y / TILE_HEIGHT);

    SKSpriteNode *square = [SKSpriteNode spriteNodeWithImageNamed:@"square"];
    square.position = newTilePosition;
    square.name = [NSString stringWithFormat:@"%d_%d", col, row];
    square.anchorPoint = CGPointMake(0.08, 0.11);
    square.userData = [@{
            @"points" : @(arc4random() % 100 + 1)
    } mutableCopy];

    [self addChild:square];
}

- (CGPoint)randomSquarePosition
{
    CGPoint deadPoint = CGPointMake(-1, -1);

    if (self.unusedCells.count == 0)
        return deadPoint;

    NSString *randomCellName = [self.unusedCells allObjects][arc4random_uniform(self.unusedCells.count)];

    if (randomCellName == nil)
        return deadPoint;

    [self.unusedCells removeObject:randomCellName];
    [self.usedCells addObject:randomCellName];

    NSArray *parts = [randomCellName componentsSeparatedByString:@"_"];
    NSInteger cols = [parts[0] integerValue];
    NSInteger rows = [parts[1] integerValue];

    CGFloat xOffset = ([self screenWidth] - [self fieldMaxCols] * TILE_WIDTH) / (CGFloat)2.0;
    CGFloat yOffset = ([self screenHeight] - [self fieldMaxRows] * TILE_HEIGHT) / (CGFloat)2.0;

    return CGPointMake(cols * TILE_HEIGHT + xOffset, rows * TILE_WIDTH + yOffset);
}

- (void)gameOver
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)animatePopupWithPointsInPosition:(CGPoint)point
{
    SKAction *moveUp = [SKAction moveToY:point.y + 100 duration:0.2];
    moveUp.timingMode = SKActionTimingEaseIn;
    SKAction *fadeOut = [SKAction fadeOutWithDuration:0.2];
    fadeOut.timingMode = SKActionTimingEaseIn;
    SKAction *removeFromParent = [SKAction removeFromParent];

    SKAction *groupAction = [SKAction group:@[moveUp, fadeOut]];
    SKAction *sequenceAction = [SKAction sequence:@[groupAction, removeFromParent]];

    SKLabelNode *pointsLabelNode = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    pointsLabelNode.text = @"+0.1";
    pointsLabelNode.fontSize = 27;
    pointsLabelNode.position = point;
    pointsLabelNode.fontColor = [SKColor yellowColor];

    [pointsLabelNode runAction:sequenceAction];

    [self addChild:pointsLabelNode];
}

#pragma mark - Layers

- (SKNode *)firstScreenLayer
{
    NSLog(@"%s", __FUNCTION__);

    SKLabelNode *playLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    playLabel.text = @"Tap me!";
    playLabel.fontSize = 37;
    playLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    playLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    playLabel.name = @"playButton";
    playLabel.position = CGPointMake([self screenWidth] / 2, [self screenHeight] / 2);
    playLabel.fontColor = [SKColor colorWithRed:0.435
                                          green:0.914
                                           blue:0.447
                                          alpha:1.0];

    return playLabel;
}

#pragma mark - Device

- (CGFloat)screenHeight
{
    return [UIScreen mainScreen].bounds.size.height;
}

- (CGFloat)screenWidth
{
    return [UIScreen mainScreen].bounds.size.width;
}

- (NSInteger)fieldMaxCols
{
    return (NSInteger) ([self screenWidth] / TILE_WIDTH);
}

- (NSInteger)fieldMaxRows
{
    return (NSInteger) ([self screenHeight] / TILE_HEIGHT);
}

@end
