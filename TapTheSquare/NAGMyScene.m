//
//  NAGMyScene.m
//  TapTheSquare
//
//  Created by AndrewShmig on 5/29/14.
//  Copyright (c) 2014 Non Atomic Games Inc. All rights reserved.
//

#import "NAGMyScene.h"
#import "GameKit/GameKit.h"

#define TILE_HEIGHT 50
#define TILE_WIDTH 50

@interface NAGMyScene ()
@property (nonatomic, getter=isFirstScreenVisible) BOOL firstScreenVisible;
@property (nonatomic, getter=isGameOver) BOOL gameOverBool;
@property (nonatomic, getter=isAdVisible) BOOL adVisible;

// кол-во игры сыграных
@property NSInteger gamesCount;

// очки, стоимости
@property (nonatomic) NSUInteger score;
@property NSUInteger cellPoints;

// таймер для генерации квадратиков
@property NSTimer *timer;
@property NSArray *timerLevels;
@property NSUInteger timerTimeLevelIndex;

// таймер для переключения уровней
@property NSTimer *levelChangeTimer;

// игровое поле
@property NSMutableSet *usedCells;
@property NSMutableSet *unusedCells;

// Game Center контроллер авторизации
@property UIViewController *gameCenterAuthViewController;
@end


@implementation NAGMyScene

- (id)initWithSize:(CGSize)size
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

    self = [super initWithSize:size];

    if (self) {
        _gamesCount = -1;

        [FlurryAds setAdDelegate:self];

        [self authorizeLocalPlayer];
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
    [self performTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self performTouches:touches];
}

- (void)performTouches:(NSSet *)touches
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

    for (UITouch *touch in touches) {
        CGPoint pointInSKScene = [self
                .view convertPoint:[touch locationInView:self.view]
                           toScene:self];
        SKNode *touchedNode = [self nodeAtPoint:pointInSKScene];

        if (self.gameOverBool) {
//            хак здесь для того, чтобы при move табличка финальная не убиралась
//            поэтому и проверка на активность игрового поля
            if (!self.userInteractionEnabled)
                return;

            [[self childNodeWithName:@"backgroundColorLayer"] removeFromParent];

            [self resetGameData];
            [self startGame];
        }

        if (self.firstScreenVisible) {
            if ([touchedNode.name isEqualToString:@"playButton"]) {
                [touchedNode removeFromParent];
                self.firstScreenVisible = NO;
                [self startGame];
                [self addChild:[self scoreLayer]];
            }
        } else if ([touchedNode.name isEqualToString:@"adTile"]) {
            if ([FlurryAds adReadyForSpace:@"GAME_VIEW"]) {
                [FlurryAds displayAdForSpace:@"GAME_VIEW" onView:self.view];
            } else {
                unsigned long winPoints = 2ul * self.cellPoints;
                NSString *cellName = [NSString stringWithFormat:@"%@_%@",
                                                                touchedNode
                                                                        .userData[@"col"],
                                                                touchedNode
                                                                        .userData[@"row"]];

                self.score += winPoints;

                [self.usedCells removeObject:cellName];
                [self.unusedCells addObject:cellName];

                [self animatePopupWithPoints:winPoints
                                  inPosition:pointInSKScene];
                [touchedNode removeFromParent];
            }
        } else if ([touchedNode.name isEqualToString:@"clearTile"]) {
//            добавляем пользователю баллы = кол-ву клеток на поле
            NSUInteger winPoints = self.cellPoints * self.usedCells.count;
            self.score += winPoints;

//            освобождаем занятые ячейки
            [self.unusedCells unionSet:self.usedCells];
            [self.usedCells removeAllObjects];

//            очищаем поле
            [self clearField];

//            анимируем суммарный выигрыш пользователя
            [self animatePopupWithPoints:winPoints
                              inPosition:pointInSKScene];
        } else if ([touchedNode.name isEqualToString:@"failTile"]) {
//            удаляем всплывшие очки, иначе они просто "заморозятся" при удалении действий с ноды
            [[self childNodeWithName:@"pointsLabel"] removeFromParent];

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
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

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
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

    self.backgroundColor = [SKColor colorWithRed:0.388
                                           green:0.259
                                            blue:0.875
                                           alpha:0];

    self.gamesCount++;
    self.firstScreenVisible = (self.gamesCount == 0);

    self.gameOverBool = NO;
    self.score = 0;
    self.cellPoints = 1ul;
    self.timerTimeLevelIndex = 0;
    self.timerLevels = @[@1.0,
                         @0.8,
                         @0.6,
                         @0.4,
                         @0.2,
                         @0.1,
                         @0.08,
                         @0.06,
                         @0.04,
                         @0.02];

    self.unusedCells = [NSMutableSet new];
    for (NSUInteger i = 0; i < [self fieldMaxCols]; i++) {
        for (NSUInteger j = 0; j < [self fieldMaxRows]; j++) {
            NSString *cellName = [NSString stringWithFormat:@"%@_%@",
                                                            @(i),
                                                            @(j)];
            [self.unusedCells addObject:cellName];
        }
    }

    self.usedCells = [NSMutableSet new];

//    очистим поле от всех тайлов
    [self clearField];
}

- (void)generateNewSquare:(NSTimer *)timer
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

//    если отображается реклама не будем обновлять поле и добавлять новых квадратиков
    if (self.isAdVisible)
        return;

    CGPoint newTilePosition = [self randomSquarePosition];
    CGPoint deadPoint = CGPointMake(-1, -1);

    if (CGPointEqualToPoint(newTilePosition, deadPoint)) {
        [timer invalidate];
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
            NSString *cellName = [NSString stringWithFormat:@"%@_%@",
                                                            @(col),
                                                            @(row)];

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
//    нет смысла переключаться на новый уровень, если пользователь смотрит рекламу
    if (self.isAdVisible)
        return;

//    изменяем интервалы/скорость заполнения игрового поля
    if (self.timerTimeLevelIndex == self.timerLevels.count - 1) {
        self.timerTimeLevelIndex = 0;

//        сбрасываем стоимость ячеек на первоначальное значение
        self.cellPoints = 1ul;
    } else {
        self.timerTimeLevelIndex++;

        //    изменяем стоимость удаленной клетки
        self.cellPoints = self.cellPoints << 1;
    }

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

    u_int32_t index = arc4random_uniform(self.unusedCells.count);
    NSString *randomCellName = [self
            .unusedCells allObjects][(NSUInteger) index];

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
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

    self.gameOverBool = YES;

//    блокируем игровую сцену
    self.userInteractionEnabled = NO;

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
        if ([node.name isEqualToString:@"pointsLabel"])
            [node removeFromParent];
        else
            [node removeAllActions];
    }];
    self.paused = NO;

//    накладываем на экран темный фон
    SKColor *backgroundColor = [SKColor colorWithWhite:0.0
                                                 alpha:0.7];
    SKSpriteNode *blackBackground = [SKSpriteNode spriteNodeWithColor:backgroundColor
                                                                 size:self
                                                                         .size];
    blackBackground.zPosition = 2;
    blackBackground.anchorPoint = CGPointZero;
    blackBackground.name = @"backgroundColorLayer";

//    game over надпись добавим
    SKLabelNode *gameOverLabel = [SKLabelNode labelNodeWithFontNamed:@"Cooper Std"];
    gameOverLabel.text = @"Game Over";
    gameOverLabel.fontColor = [SKColor yellowColor];
    gameOverLabel.fontSize = 37;
    gameOverLabel
            .position = CGPointMake([self screenWidth] / (CGFloat) 2.0, [self screenHeight] / (CGFloat) 2.0);
    [blackBackground addChild:gameOverLabel];

//    добавляем надпись с кол-во очков ниже надписи с концом игры
    SKLabelNode *finalScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Cooper Std"];
    finalScoreLabel.text = [NSString stringWithFormat:@"%012lu",
                                                      (unsigned long) self
                                                              .score];
    finalScoreLabel.fontColor = [SKColor redColor];
    finalScoreLabel.fontSize = 27;
    finalScoreLabel
            .position = CGPointMake([self screenWidth] / (CGFloat) 2.0, gameOverLabel
            .position.y - 30);
    [blackBackground addChild:finalScoreLabel];

//    добавляем кнопку Play Again
    SKLabelNode *playAgainButton = [SKLabelNode labelNodeWithFontNamed:@"Cooper Std"];
    playAgainButton.text = @"Tap again!";
    playAgainButton.fontColor = [SKColor colorWithRed:0.435
                                                green:0.914
                                                 blue:0.447
                                                alpha:1.0];
    playAgainButton.fontSize = 47;
    playAgainButton
            .position = CGPointMake([self screenWidth] / (CGFloat) 2.0, finalScoreLabel
            .position.y - 100);
    [blackBackground addChild:playAgainButton];

    [self addChild:blackBackground];

//    блокируем игровое поле на 2 секунды, чтобы игрок увидел свой счет
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(enableGameField:)
                                   userInfo:nil
                                    repeats:NO];

//    авторизуем пользователя в ГЦ и отправляем его очки
    __weak NAGMyScene *weakSelf = self;

    if (![GKLocalPlayer localPlayer].isAuthenticated && self
            .gameCenterAuthViewController != nil) {
        [[[UIApplication sharedApplication] keyWindow]
                .rootViewController presentViewController:self
                .gameCenterAuthViewController
                                                 animated:YES
                                               completion:^{

            if ([GKLocalPlayer localPlayer].isAuthenticated) {
                [weakSelf sendScoreToGameCenter];
            }
        }];
    } else if ([GKLocalPlayer localPlayer].isAuthenticated) {
        [weakSelf sendScoreToGameCenter];
    }
}

- (void)enableGameField:(NSTimer *)timer
{
    self.userInteractionEnabled = YES;
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
    pointsLabelNode.text = [NSString stringWithFormat:@"+%lu",
                                                      (unsigned long) points];
    pointsLabelNode.fontSize = 27;
    pointsLabelNode.position = position;
    pointsLabelNode.fontColor = [SKColor yellowColor];
    pointsLabelNode.name = @"pointsLabel";

    [pointsLabelNode runAction:sequenceAction];

    [self addChild:pointsLabelNode];
}

- (void)updateScoreLabel
{
    SKLabelNode *score = (SKLabelNode *) [self childNodeWithName:@"scoreLabel"];
    score.text = [NSString stringWithFormat:@"Score: %012lu",
                                            (unsigned long) self.score];
}

- (void)clearField
{
    [self enumerateChildNodesWithName:@"*"
                           usingBlock:^(SKNode *node, BOOL *stop) {
        if (![node.name isEqualToString:@"scoreLabel"])
            [node removeFromParent];
    }];
}

#pragma mark - Layers

- (SKNode *)firstScreenLayer
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

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
    scoreLabel.text = [NSString stringWithFormat:@"Score: %012lu",
                                                 (unsigned long) self.score];
    scoreLabel.zPosition = 1;
    scoreLabel.name = @"scoreLabel";

    CGRect accumulatedRect = scoreLabel.calculateAccumulatedFrame;
    scoreLabel.position = CGPointMake(accumulatedRect.size
            .width / 2, [self screenHeight] - accumulatedRect.size.height);

    return scoreLabel;
}

#pragma mark - Game Center

- (void)authorizeLocalPlayer
{
    __weak NAGMyScene *weakSelf = self;

    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *authController,
                                        NSError *error) {
        if (authController != nil) {
            weakSelf.gameCenterAuthViewController = authController;
        }
    };
}

- (void)sendScoreToGameCenter
{
//                отправляем пользовательские очки в ГЦ
    GKScore *score = [GKScore new];
    score.value = self.score;
    score.leaderboardIdentifier = @"scoreTable";

    [GKScore reportScores:@[score]
    withCompletionHandler:nil];
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

#pragma mark - Flurry Ads

- (BOOL)spaceShouldDisplay:(NSString *)adSpace
              interstitial:(BOOL)interstitial
{
    if (interstitial) {
        self.paused = YES;
        self.adVisible = YES;

        return YES;
    }

    return NO;
}

- (void)spaceDidDismiss:(NSString *)adSpace
           interstitial:(BOOL)interstitial
{
    if (interstitial) {
        self.paused = NO;
        self.adVisible = NO;
    }
}

@end
