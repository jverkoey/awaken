#import <IOKit/pwr_mgt/IOPMLib.h>
#import <Carbon/Carbon.h>
#import "GBView.h"
#import "GBViewGL.h"
#import "GBViewMetal.h"
#import "GBButtons.h"
#import "NSString+StringForKey.h"
#import "Document.h"
#import "Emulator.h"

#define JOYSTICK_HIGH 0x4000
#define JOYSTICK_LOW 0x3800

static const uint8_t workboy_ascii_to_key[] = {
    ['0'] = GB_WORKBOY_0,
    ['`'] = GB_WORKBOY_UMLAUT,
    ['1'] = GB_WORKBOY_1,
    ['2'] = GB_WORKBOY_2,
    ['3'] = GB_WORKBOY_3,
    ['4'] = GB_WORKBOY_4,
    ['5'] = GB_WORKBOY_5,
    ['6'] = GB_WORKBOY_6,
    ['7'] = GB_WORKBOY_7,
    ['8'] = GB_WORKBOY_8,
    ['9'] = GB_WORKBOY_9,
    
    ['\r'] = GB_WORKBOY_ENTER,
    [3] = GB_WORKBOY_ENTER,
    
    ['!'] = GB_WORKBOY_EXCLAMATION_MARK,
    ['$'] = GB_WORKBOY_DOLLAR,
    ['#'] = GB_WORKBOY_HASH,
    ['~'] = GB_WORKBOY_TILDE,
    ['*'] = GB_WORKBOY_ASTERISK,
    ['+'] = GB_WORKBOY_PLUS,
    ['-'] = GB_WORKBOY_MINUS,
    ['('] = GB_WORKBOY_LEFT_PARENTHESIS,
    [')'] = GB_WORKBOY_RIGHT_PARENTHESIS,
    [';'] = GB_WORKBOY_SEMICOLON,
    [':'] = GB_WORKBOY_COLON,
    ['%'] = GB_WORKBOY_PERCENT,
    ['='] = GB_WORKBOY_EQUAL,
    [','] = GB_WORKBOY_COMMA,
    ['<'] = GB_WORKBOY_LT,
    ['.'] = GB_WORKBOY_DOT,
    ['>'] = GB_WORKBOY_GT,
    ['/'] = GB_WORKBOY_SLASH,
    ['?'] = GB_WORKBOY_QUESTION_MARK,
    [' '] = GB_WORKBOY_SPACE,
    ['\''] = GB_WORKBOY_QUOTE,
    ['@'] = GB_WORKBOY_AT,
    
    ['q'] = GB_WORKBOY_Q,
    ['w'] = GB_WORKBOY_W,
    ['e'] = GB_WORKBOY_E,
    ['r'] = GB_WORKBOY_R,
    ['t'] = GB_WORKBOY_T,
    ['y'] = GB_WORKBOY_Y,
    ['u'] = GB_WORKBOY_U,
    ['i'] = GB_WORKBOY_I,
    ['o'] = GB_WORKBOY_O,
    ['p'] = GB_WORKBOY_P,
    ['a'] = GB_WORKBOY_A,
    ['s'] = GB_WORKBOY_S,
    ['d'] = GB_WORKBOY_D,
    ['f'] = GB_WORKBOY_F,
    ['g'] = GB_WORKBOY_G,
    ['h'] = GB_WORKBOY_H,
    ['j'] = GB_WORKBOY_J,
    ['k'] = GB_WORKBOY_K,
    ['l'] = GB_WORKBOY_L,
    ['z'] = GB_WORKBOY_Z,
    ['x'] = GB_WORKBOY_X,
    ['c'] = GB_WORKBOY_C,
    ['v'] = GB_WORKBOY_V,
    ['b'] = GB_WORKBOY_B,
    ['n'] = GB_WORKBOY_N,
    ['m'] = GB_WORKBOY_M,
};

static const uint8_t workboy_vk_to_key[] = {
    [kVK_F1] = GB_WORKBOY_CLOCK,
    [kVK_F2] = GB_WORKBOY_TEMPERATURE,
    [kVK_F3] = GB_WORKBOY_MONEY,
    [kVK_F4] = GB_WORKBOY_CALCULATOR,
    [kVK_F5] = GB_WORKBOY_DATE,
    [kVK_F6] = GB_WORKBOY_CONVERSION,
    [kVK_F7] = GB_WORKBOY_RECORD,
    [kVK_F8] = GB_WORKBOY_WORLD,
    [kVK_F9] = GB_WORKBOY_PHONE,
    [kVK_F10] = GB_WORKBOY_UNKNOWN,
    [kVK_Delete] = GB_WORKBOY_BACKSPACE,
    [kVK_Shift] = GB_WORKBOY_SHIFT_DOWN,
    [kVK_RightShift] = GB_WORKBOY_SHIFT_DOWN,
    [kVK_UpArrow] = GB_WORKBOY_UP,
    [kVK_DownArrow] = GB_WORKBOY_DOWN,
    [kVK_LeftArrow] = GB_WORKBOY_LEFT,
    [kVK_RightArrow] = GB_WORKBOY_RIGHT,
    [kVK_Escape] = GB_WORKBOY_ESCAPE,
    [kVK_ANSI_KeypadDecimal] = GB_WORKBOY_DECIMAL_POINT,
    [kVK_ANSI_KeypadClear] = GB_WORKBOY_M,
    [kVK_ANSI_KeypadMultiply] = GB_WORKBOY_H,
    [kVK_ANSI_KeypadDivide] = GB_WORKBOY_J,
};

@implementation GBView
{
    uint32_t *image_buffers[3];
    unsigned char current_buffer;
    BOOL mouse_hidden;
    NSTrackingArea *tracking_area;
    BOOL _mouseHidingEnabled;
    bool axisActive[2];
    bool underclockKeyDown;
    double clockMultiplier;
    double analogClockMultiplier;
    bool analogClockMultiplierValid;
    NSEventModifierFlags previousModifiers;
    JOYController *lastController;
    GB_frame_blending_mode_t _frameBlendingMode;
}

+ (instancetype)alloc
{
    return [self allocWithZone:NULL];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    if (self == [GBView class]) {
        if ([GBViewMetal isSupported]) {
            return [GBViewMetal allocWithZone: zone];
        }
        return [GBViewGL allocWithZone: zone];
    }
    return [super allocWithZone:zone];
}

- (void) createInternalView
{
    assert(false && "createInternalView must not be inherited");
}

- (void) _init
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratioKeepingChanged) name:@"GBAspectChanged" object:nil];
    tracking_area = [ [NSTrackingArea alloc] initWithRect:(NSRect){}
                                                  options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect
                                                    owner:self
                                                 userInfo:nil];
    [self addTrackingArea:tracking_area];
    clockMultiplier = 1.0;
    [self createInternalView];
    [self addSubview:self.internalView];
    self.internalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [JOYController registerListener:self];
}

- (void)screenSizeChanged
{
    if (image_buffers[0]) free(image_buffers[0]);
    if (image_buffers[1]) free(image_buffers[1]);
    if (image_buffers[2]) free(image_buffers[2]);

    NSSize screenSize = _emulator.screenSize;
    size_t buffer_size = sizeof(image_buffers[0][0]) * screenSize.width * screenSize.height;
    
    image_buffers[0] = calloc(1, buffer_size);
    image_buffers[1] = calloc(1, buffer_size);
    image_buffers[2] = calloc(1, buffer_size);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setFrame:self.superview.frame];
    });
}

- (void) ratioKeepingChanged
{
    [self setFrame:self.superview.frame];
}

- (void) setFrameBlendingMode:(GB_frame_blending_mode_t)frameBlendingMode
{
    _frameBlendingMode = frameBlendingMode;
    [self setNeedsDisplay:YES];
}


- (GB_frame_blending_mode_t)frameBlendingMode
{
    if (_frameBlendingMode == GB_FRAME_BLENDING_MODE_ACCURATE) {
        if (!_emulator || _emulator.isSGB) {
            return GB_FRAME_BLENDING_MODE_SIMPLE;
        }
        return _emulator.isOddFrame ? GB_FRAME_BLENDING_MODE_ACCURATE_ODD : GB_FRAME_BLENDING_MODE_ACCURATE_EVEN;
    }
    return _frameBlendingMode;
}
- (unsigned char) numberOfBuffers
{
    return _frameBlendingMode? 3 : 2;
}

- (void)dealloc
{
    free(image_buffers[0]);
    free(image_buffers[1]);
    free(image_buffers[2]);
    if (mouse_hidden) {
        mouse_hidden = false;
        [NSCursor unhide];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setRumble:0];
    [JOYController unregisterListener:self];
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (!(self = [super initWithCoder:coder])) { 
        return self;
    }
    [self _init];
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (!(self = [super initWithFrame:frameRect])) { 
        return self;
    }
    [self _init];
    return self;
}

- (void)setFrame:(NSRect)frame
{
    frame = self.superview.frame;
    if (_emulator && ![[NSUserDefaults standardUserDefaults] boolForKey:@"GBAspectRatioUnkept"]) {
        double ratio = frame.size.width / frame.size.height;
        NSSize screenSize = _emulator.screenSize;
        if (ratio >= screenSize.width / screenSize.height) {
            double new_width = round(frame.size.height / screenSize.height * screenSize.width);
            frame.origin.x = floor((frame.size.width - new_width) / 2);
            frame.size.width = new_width;
            frame.origin.y = 0;
        }
        else {
            double new_height = round(frame.size.width / screenSize.width * screenSize.height);
            frame.origin.y = floor((frame.size.height - new_height) / 2);
            frame.size.height = new_height;
            frame.origin.x = 0;
        }
    }

    [super setFrame:frame];
}

- (void) flip
{
    if (analogClockMultiplierValid && [[NSUserDefaults standardUserDefaults] boolForKey:@"GBAnalogControls"]) {
        _emulator.clockMultiplier = analogClockMultiplier;
        if (self.emulator.partner) {
            self.emulator.partner.clockMultiplier = analogClockMultiplier;
        }
        if (analogClockMultiplier == 1.0) {
            analogClockMultiplierValid = false;
        }
    }
    else {
        if (underclockKeyDown && clockMultiplier > 0.5) {
            clockMultiplier -= 1.0/16;
            _emulator.clockMultiplier = clockMultiplier;
            self.emulator.partner.clockMultiplier = analogClockMultiplier;
        }
        if (!underclockKeyDown && clockMultiplier < 1.0) {
            clockMultiplier += 1.0/16;
            _emulator.clockMultiplier = clockMultiplier;
            self.emulator.partner.clockMultiplier = analogClockMultiplier;
        }
    }
    current_buffer = (current_buffer + 1) % self.numberOfBuffers;
}

- (uint32_t *) pixels
{
    return image_buffers[(current_buffer + 1) % self.numberOfBuffers];
}

-(void)keyDown:(NSEvent *)theEvent
{
    if ([theEvent type] != NSEventTypeFlagsChanged && theEvent.isARepeat) return;
    unsigned short keyCode = theEvent.keyCode;
    if (_emulator.workboyEnabled) {
        if (theEvent.keyCode < sizeof(workboy_vk_to_key) && workboy_vk_to_key[theEvent.keyCode]) {
            [_emulator setWorkboyKey:workboy_vk_to_key[theEvent.keyCode]];
            return;
        }
        unichar c = [theEvent type] != NSEventTypeFlagsChanged? [theEvent.charactersIgnoringModifiers.lowercaseString characterAtIndex:0] : 0;
        if (c < sizeof(workboy_ascii_to_key) && workboy_ascii_to_key[c]) {
            [_emulator setWorkboyKey:workboy_ascii_to_key[c]];
            return;
        }
    }
    
    bool handled = false;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    unsigned player_count = _emulator.numberOfPlayers;
    if (self.emulator.partner) {
        player_count = 2;
    }
    for (unsigned player = 0; player < player_count; player++) {
        for (GBButton button = 0; button < GBButtonCount; button++) {
            NSNumber *key = [defaults valueForKey:button_to_preference_name(button, player)];
            if (!key) continue;

            if (key.unsignedShortValue == keyCode) {
                handled = true;
                switch (button) {
                    case GBTurbo:
                        if (self.emulator.isSlave) {
                            [self.emulator.partner setTurboMode:true noFrameSkip:false];
                        }
                        else {
                            [_emulator setTurboMode:true noFrameSkip:self.isRewinding];
                        }
                        analogClockMultiplierValid = false;
                        break;
                        
                    case GBRewind:
                        if (!self.emulator.partner) {
                            self.isRewinding = true;
                            [_emulator setTurboMode:false noFrameSkip:false];
                        }
                        break;
                        
                    case GBUnderclock:
                        underclockKeyDown = true;
                        analogClockMultiplierValid = false;
                        break;
                        
                    default:
                        if (self.emulator.partner) {
                            if (player == 0) {
                                [_emulator setKeyStateForButton:(GB_key_t)button forPlayer:0 pressed:true];
                            }
                            else {
                              [self.emulator.partner setKeyStateForButton:(GB_key_t)button
                                                                forPlayer:0
                                                                  pressed:true];
                            }
                        }
                        else {
                            [_emulator setKeyStateForButton:(GB_key_t)button forPlayer:player pressed:true];
                        }
                        break;
                }
            }
        }
    }

    if (!handled && [theEvent type] != NSEventTypeFlagsChanged) {
        [super keyDown:theEvent];
    }
}

-(void)keyUp:(NSEvent *)theEvent
{
    unsigned short keyCode = theEvent.keyCode;
    if (_emulator.workboyEnabled) {
        if (keyCode == kVK_Shift || keyCode == kVK_RightShift) {
            [_emulator setWorkboyKey:GB_WORKBOY_SHIFT_UP];
        }
        else {
            [_emulator setWorkboyKey:GB_WORKBOY_NONE];
        }

    }
    bool handled = false;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    unsigned player_count = _emulator.numberOfPlayers;
    if (self.emulator.partner) {
        player_count = 2;
    }
    for (unsigned player = 0; player < player_count; player++) {
        for (GBButton button = 0; button < GBButtonCount; button++) {
            NSNumber *key = [defaults valueForKey:button_to_preference_name(button, player)];
            if (!key) continue;
            
            if (key.unsignedShortValue == keyCode) {
                handled = true;
                switch (button) {
                    case GBTurbo:
                        if (self.emulator.isSlave) {
                            [self.emulator.partner setTurboMode:false noFrameSkip:false];
                        }
                        else {
                            [_emulator setTurboMode:false noFrameSkip:false];
                        }
                        analogClockMultiplierValid = false;
                        break;
                        
                    case GBRewind:
                        self.isRewinding = false;
                        break;
                        
                    case GBUnderclock:
                        underclockKeyDown = false;
                        analogClockMultiplierValid = false;
                        break;
                        
                    default:
                        if (self.emulator.partner) {
                            if (player == 0) {
                                [_emulator setKeyStateForButton:(GB_key_t)button forPlayer:0 pressed:false];
                            }
                            else {
                              [self.emulator.partner setKeyStateForButton:(GB_key_t)button
                                                                forPlayer:0
                                                                  pressed:false];
                            }
                        }
                        else {
                            [_emulator setKeyStateForButton:(GB_key_t)button forPlayer:player pressed:false];
                        }
                        break;
                }
            }
        }
    }
    if (!handled && [theEvent type] != NSEventTypeFlagsChanged) {
        [super keyUp:theEvent];
    }
}

- (void)setRumble:(double)amp
{
    [lastController setRumbleAmplitude:amp];
}

- (void)controller:(JOYController *)controller movedAxis:(JOYAxis *)axis
{
    if (![self.window isMainWindow]) return;

    NSDictionary *mapping = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"JoyKitInstanceMapping"][controller.uniqueID];
    if (!mapping) {
        mapping = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"JoyKitNameMapping"][controller.deviceName];
    }
    
    if ((axis.usage == JOYAxisUsageR1 && !mapping) ||
        axis.uniqueID == [mapping[@"AnalogUnderclock"] unsignedLongValue]){
        analogClockMultiplier = MIN(MAX(1 - axis.value + 0.2, 1.0 / 3), 1.0);
        analogClockMultiplierValid = true;
    }
    
    else if ((axis.usage == JOYAxisUsageL1 && !mapping) ||
        axis.uniqueID == [mapping[@"AnalogTurbo"] unsignedLongValue]){
        analogClockMultiplier = MIN(MAX(axis.value * 3 + 0.8, 1.0), 3.0);
        analogClockMultiplierValid = true;
    }
}

- (void)controller:(JOYController *)controller buttonChangedState:(JOYButton *)button
{
    if (![self.window isMainWindow]) return;
    
    unsigned player_count = _emulator.numberOfPlayers;
    if (self.emulator.partner) {
        player_count = 2;
    }

    IOPMAssertionID assertionID;
    IOPMAssertionDeclareUserActivity(CFSTR(""), kIOPMUserActiveLocal, &assertionID);
    
    for (unsigned player = 0; player < player_count; player++) {
        NSString *preferred_joypad = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"JoyKitDefaultControllers"]
                                      objectForKey:n2s(player)];
        if (player_count != 1 && // Single player, accpet inputs from all joypads
            !(player == 0 && !preferred_joypad) && // Multiplayer, but player 1 has no joypad configured, so it takes inputs from all joypads
            ![preferred_joypad isEqualToString:controller.uniqueID]) {
            continue;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller setPlayerLEDs:1 << player];
        });
        NSDictionary *mapping = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"JoyKitInstanceMapping"][controller.uniqueID];
        if (!mapping) {
            mapping = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"JoyKitNameMapping"][controller.deviceName];
        }
        
        JOYButtonUsage usage = ((JOYButtonUsage)[mapping[n2s(button.uniqueID)] unsignedIntValue]) ?: button.usage;
        if (!mapping && usage >= JOYButtonUsageGeneric0) {
            usage = (const JOYButtonUsage[]){JOYButtonUsageY, JOYButtonUsageA, JOYButtonUsageB, JOYButtonUsageX}[(usage - JOYButtonUsageGeneric0) & 3];
        }
        
        Emulator *effectiveEmulator = _emulator;
        unsigned effectivePlayer = player;
        
        if (player && self.emulator.partner) {
            effectiveEmulator = self.emulator.partner;
            effectivePlayer = 0;
            if (controller != self.document.partner.view->lastController) {
                [self setRumble:0];
                self.document.partner.view->lastController = controller;
            }
        }
        else {
            if (controller != lastController) {
                [self setRumble:0];
                lastController = controller;
            }
        }
        
        switch (usage) {
                
            case JOYButtonUsageNone: break;
            case JOYButtonUsageA: [effectiveEmulator setKeyStateForButton:GB_KEY_A forPlayer:effectivePlayer pressed:button.isPressed]; break;
            case JOYButtonUsageB: [effectiveEmulator setKeyStateForButton:GB_KEY_B forPlayer:effectivePlayer pressed:button.isPressed]; break;
            case JOYButtonUsageC: break;
            case JOYButtonUsageStart:
            case JOYButtonUsageX: [effectiveEmulator setKeyStateForButton:GB_KEY_START forPlayer:effectivePlayer pressed:button.isPressed]; break;
            case JOYButtonUsageSelect:
            case JOYButtonUsageY: [effectiveEmulator setKeyStateForButton:GB_KEY_SELECT forPlayer:effectivePlayer pressed:button.isPressed]; break;
            case JOYButtonUsageR2:
            case JOYButtonUsageL2:
            case JOYButtonUsageZ: {
                self.isRewinding = button.isPressed;
                if (button.isPressed) {
                    if (self.emulator.isSlave) {
                        [self.emulator.partner setTurboMode:false noFrameSkip:false];
                    }
                    else {
                        [self.emulator setTurboMode:false noFrameSkip:false];
                    }
                }
                break;
            }
        
            case JOYButtonUsageL1: {
                if (self.emulator.isSlave) {
                    [self.emulator.partner setTurboMode:button.isPressed noFrameSkip:false]; break;
                }
                else {
                    [_emulator setTurboMode:button.isPressed noFrameSkip:button.isPressed && self.isRewinding]; break;
                }
            }

            case JOYButtonUsageR1: underclockKeyDown = button.isPressed; break;
            case JOYButtonUsageDPadLeft: [effectiveEmulator setKeyStateForButton:GB_KEY_LEFT forPlayer:effectivePlayer pressed:button.isPressed]; break;
            case JOYButtonUsageDPadRight: [effectiveEmulator setKeyStateForButton:GB_KEY_RIGHT forPlayer:effectivePlayer pressed:button.isPressed]; break;
            case JOYButtonUsageDPadUp: [effectiveEmulator setKeyStateForButton:GB_KEY_UP forPlayer:effectivePlayer pressed:button.isPressed]; break;
            case JOYButtonUsageDPadDown: [effectiveEmulator setKeyStateForButton:GB_KEY_DOWN forPlayer:effectivePlayer pressed:button.isPressed]; break;

            default:
                break;
        }
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (!mouse_hidden) {
        mouse_hidden = true;
        if (_mouseHidingEnabled) {
            [NSCursor hide];
        }
    }
    [super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if (mouse_hidden) {
        mouse_hidden = false;
        if (_mouseHidingEnabled) {
            [NSCursor unhide];
        }
    }
    [super mouseExited:theEvent];
}

- (void)setMouseHidingEnabled:(BOOL)mouseHidingEnabled
{
    if (mouseHidingEnabled == _mouseHidingEnabled) return;

    _mouseHidingEnabled = mouseHidingEnabled;
    
    if (mouse_hidden && _mouseHidingEnabled) {
        [NSCursor hide];
    }

    if (mouse_hidden && !_mouseHidingEnabled) {
        [NSCursor unhide];
    }
}

- (BOOL)isMouseHidingEnabled
{
    return _mouseHidingEnabled;
}

- (void) flagsChanged:(NSEvent *)event
{
    if (event.modifierFlags > previousModifiers) {
        [self keyDown:event];
    }
    else {
        [self keyUp:event];
    }
    
    previousModifiers = event.modifierFlags;
}

- (uint32_t *)currentBuffer
{
    return image_buffers[current_buffer];
}

- (uint32_t *)previousBuffer
{
    return image_buffers[(current_buffer + 2) % self.numberOfBuffers];
}

@end
