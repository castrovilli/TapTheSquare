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
@property (nonatomic, getter=isGameOver) BOOL gameOver;

// очки, стоимости
@property NSUInteger score;
@property NSUInteger cellPoints;

// таймер для генерации квадратиков
@property NSTimer *timer;
@property NSMutableArray *timerLevels;
@property NSUInteger timerTimeLevelIndex;

// таймер для переключения уровней
@property NSTimer *levelChangeTimer;

// игровое поле
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
    [self updateScoreLabel];
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

        if (self.isGameOver) {
            NSLog(@"SOMETHING GOES HERE");
        } else if (self.firstScreenVisible) {
            if ([touchedNode.name isEqualToString:@"playButton"]) {
                [touchedNode removeFromParent];
                self.firstScreenVisible = NO;
                [self startGame];
                [self addChild:[self scoreLayer]];
            }
        } else if ([touchedNode.name isEqualToString:@"adTile"]) {
            NSLog(@"===> AD TILE");
        } else if ([touchedNode.name isEqualToString:@"clearTile"]) {
//            добавляем пользователю баллы = кол-ву клеток на поле
            NSUInteger winPoints = self.cellPoints * self.usedCells.count;
            self.score += winPoints;

//            освобождаем занятые ячейки
            [self.unusedCells unionSet:self.usedCells];
            [self.usedCells removeAllObjects];

//            очищаем поле
            [self enumerateChildNodesWithName:@"*"
                                   usingBlock:^(SKNode *node, BOOL *stop) {
                if (![node.name isEqualToString:@"scoreLabel"])
                    [node removeFromParent];
            }];

//            анимируем суммарный выигрыш пользователя
            [self animatePopupWithPoints:winPoints
                              inPosition:pointInSKScene];
        } else if ([touchedNode.name isEqualToString:@"failTile"]) {
            [self gameOver];
        } else if ([touchedNode.name isEqualToString:@"standartTile"]) {
            self.score += self.cellPoints;

            NSString *touchedNodeUniqueName = [NSString stringWithFormat:@"%@_%@",
                                                                         touchedNode
                                                                                 .userData[@"col"],
                                                                         touchedNode
                                                                                 .userData[@"row"]];
            [self.usedCells removeObject:touchedNodeUniqueName];
            [self.unusedCells addObject:touchedNodeUniqueName];

            [self animatePopupWithPoints:self.cellPoints
                              inPosition:pointInSKScene];

            [touchedNode removeFromParent];
        }
    }
}

#pragma mark - Game

- (void)startGame
{
    NSLog(@"%s", __FUNCTION__);

//    инициализация таймера переключения уровней
    self.levelChangeTimer = [NSTimer timerWithTimeInterval:5.0 // seconds
                                                    target:self
                                                  selector:@selector(changeGameLevel:)
                                                  userInfo:nil
                                                   repeats:YES];

    [[NSRunLoop mainRunLoop]
                addTimer:self.levelChangeTimer
                 forMode:NSDefaultRunLoopMode];

//    инициализация таймера генерации игрового поля
    self.timer = [NSTimer timerWithTimeInterval:[self.timerLevels[self
            .timerTimeLevelIndex] floatValue]
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
    self.gameOver = NO;
    self.score = 0;
    self.cellPoints = 1 << 0;
    self.timerTimeLevelIndex = 0;
    self.timerLevels = [@[@1.0,
                          @0.8,
                          @0.6,
                          @0.4,
                          @0.2,
                          @0.09,
                          @0.07,
                          @0.05,
                          @0.03,
                          @0.01,
                          @0.001] mutableCopy];

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

    SKSpriteNode *square = [self randomSquareTile];
    square.position = newTilePosition;
    square.anchorPoint = CGPointMake(0.08, 0.11);
    square.userData = [@{
            @"col" : @(col),
            @"row" : @(row)
    } mutableCopy];

//        добавляем действие по автоматическому удалению особых квадратиков
    if ([square.name isEqualToString:@"adTile"] || [square
            .name isEqualToString:@"failTile"] || [square
            .name isEqualToString:@"clearTile"]) {

        __weak NAGMyScene *weakSelf = self;
        SKAction *waitAction = [SKAction waitForDuration:2.0];
        SKAction *removeAction = [SKAction removeFromParent];
        SKAction *restoreCell = [SKAction runBlock:^{
            NSString *cellName = [NSString stringWithFormat:@"%d_%d", col, row];

            [weakSelf.unusedCells addObject:cellName];
            [weakSelf.usedCells removeObject:cellName];
        }];
        SKAction *sequenceAction = [SKAction sequence:@[waitAction,
                                                        restoreCell,
                                                        removeAction]];

        [square runAction:sequenceAction];
    }

    [self addChild:square];
}

- (SKSpriteNode *)randomSquareTile
{
    SKSpriteNode *node;
    NSInteger value = arc4random_uniform(100);

    if (0 <= value && value <= 90) {
        node = [SKSpriteNode spriteNodeWithImageNamed:@"square"];
        node.name = @"standartTile";
    } else if (90 < value && value <= 95) {
        if (arc4random_uniform(2) == 1) {
            node = [SKSpriteNode spriteNodeWithImageNamed:@"square_clear"];
            node.name = @"clearTile";
        } else {
            node = [SKSpriteNode spriteNodeWithImageNamed:@"square_fail"];
            node.name = @"failTile";
        }
    } else {
        node = [SKSpriteNode spriteNodeWithImageNamed:@"square_ad"];
        node.name = @"adTile";
    }

    return node;
}

- (void)changeGameLevel:(NSTimer *)timer
{
//    изменяем интервалы/скорость заполнения игрового поля
    if (self.timerTimeLevelIndex == self.timerLevels.count - 1) {
        self.timerTimeLevelIndex = 0;
    } else {
        self.timerTimeLevelIndex++;
    }

//    изменяем стоимость удаленной клетки
    self.cellPoints = self.cellPoints << 1;

//    отключаем текущий таймер
    [self.timer invalidate];
    self.timer = nil;

//    создаем новый с новым интервалом добавления квадратиков на поле
    self.timer = [NSTimer timerWithTimeInterval:[self.timerLevels[self
            .timerTimeLevelIndex] floatValue]
                                         target:self
                                       selector:@selector(generateNewSquare:)
                                       userInfo:nil
                                        repeats:YES];

    [[NSRunLoop mainRunLoop]
                addTimer:self.timer
                 forMode:NSDefaultRunLoopMode];
}

- (CGPoint)randomSquarePosition
{
    CGPoint deadPoint = CGPointMake(-1, -1);

    if (self.unusedCells.count == 0)
        return deadPoint;

    NSString *randomCellName = [self
            .unusedCells allObjects][arc4random_uniform(self.unusedCells
            .count)];

    if (randomCellName == nil)
        return deadPoint;

    [self.unusedCells removeObject:randomCellName];
    [self.usedCells addObject:randomCellName];

    NSArray *parts = [randomCellName componentsSeparatedByString:@"_"];
    NSInteger cols = [parts[0] integerValue];
    NSInteger rows = [parts[1] integerValue];

    CGFloat xOffset = ([self screenWidth] - [self fieldMaxCols] * TILE_WIDTH) / (CGFloat) 2.0;
    CGFloat yOffset = ([self screenHeight] - [self fieldMaxRows] * TILE_HEIGHT) / (CGFloat) 2.0;

    return CGPointMake(cols * TILE_HEIGHT + xOffset, rows * TILE_WIDTH + yOffset);
}

- (void)gameOver
{
    NSLog(@"%s", __FUNCTION__);

    self.gameOver = YES;

//    останавливаем основной таймер переключения уровней
    [self.levelChangeTimer invalidate];
    self.levelChangeTimer = nil;

//    останавливаем таймер, который заполняет квадратиками поле
    [self.timer invalidate];
    self.timer = nil;

//    отменим все actions
    self.paused = YES;
    [self enumerateChildNodesWithName:@"*"
                           usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
    self.paused = NO;
}

- (void)animatePopupWithPoints:(NSUInteger)points
                    inPosition:(CGPoint)position
{
    SKAction *moveUp = [SKAction moveToY:position.y + 100 duration:0.2];
    moveUp.timingMode = SKActionTimingEaseIn;
    SKAction *fadeOut = [SKAction fadeOutWithDuration:0.2];
    fadeOut.timingMode = SKActionTimingEaseIn;
    SKAction *removeFromParent = [SKAction removeFromParent];

    SKAction *groupAction = [SKAction group:@[moveUp, fadeOut]];
    SKAction *sequenceAction = [SKAction sequence:@[groupAction,
                                                    removeFromParent]];

    SKLabelNode *pointsLabelNode = [SKLabelNode labelNodeWithFontNamed:@"Cooper Std"];
    pointsLabelNode.text = [NSString stringWithFormat:@"+%d", points];
    pointsLabelNode.fontSize = 27;
    pointsLabelNode.position = position;
    pointsLabelNode.fontColor = [SKColor yellowColor];

    [pointsLabelNode runAction:sequenceAction];

    [self addChild:pointsLabelNode];
}

- (void)updateScoreLabel
{
    SKLabelNode *score = (SKLabelNode *) [self childNodeWithName:@"scoreLabel"];
    score.text = [NSString stringWithFormat:@"Score: %09d", self.score];
}

#pragma mark - Layers

- (SKNode *)firstScreenLayer
{
    NSLog(@"%s", __FUNCTION__);

    SKLabelNode *playLabel = [SKLabelNode labelNodeWithFontNamed:@"Cooper Std"];
    playLabel.text = @"Tap me!";
    playLabel.fontSize = 37;
    playLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    playLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    playLabel.name = @"playButton";
    playLabel
            .position = CGPointMake([self screenWidth] / 2, [self screenHeight] / 2);
    playLabel.fontColor = [SKColor colorWithRed:0.435
                                          green:0.914
                                           blue:0.447
                                          alpha:1.0];

    return playLabel;
}

- (SKNode *)scoreLayer
{
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Cooper Std"];
    scoreLabel.fontColor = [SKColor yellowColor];
    scoreLabel.fontSize = 27;
    scoreLabel.text = [NSString stringWithFormat:@"Score: %09d", self.score];
    scoreLabel.zPosition = 5;
    scoreLabel.name = @"scoreLabel";
    scoreLabel.position = CGPointMake(130, [self screenHeight] - scoreLabel
            .calculateAccumulatedFrame.size.height);

    return scoreLabel;
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
