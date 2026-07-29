//
//  SideScrollerScene.swift
//  Games
//

import SpriteKit

enum SideScrollerStatus: Equatable {
    case playing
    case won
    case lost
}

@Observable
final class SideScrollerSession {
    var status: SideScrollerStatus = .playing
    var canJump = true
}

private enum SideScrollerPhysics {
    static let player: UInt32 = 0b1
    static let ground: UInt32 = 0b10
    static let goal: UInt32 = 0b100
}

final class SideScrollerScene: SKScene, SKPhysicsContactDelegate {
    private weak var session: SideScrollerSession?

    private var player: SKSpriteNode!
    private var cameraNode = SKCameraNode()
    private var moveLeft = false
    private var groundedContacts = 0
    private var coyoteTime: TimeInterval = 0
    private var jumpIgnoreGroundTime: TimeInterval = 0
    private var didBuild = false
    private var lastUpdateTime: TimeInterval = 0
    private var levelWidth: CGFloat = 2800

    private let moveSpeed: CGFloat = 160
    private let jumpSpeed: CGFloat = 720
    private let coyoteLimit: TimeInterval = 0.2
    private let jumpIgnoreGroundLimit: TimeInterval = 0.22

    func attach(session: SideScrollerSession) {
        self.session = session
    }

    override func didMove(to view: SKView) {
        view.isPaused = false
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true
        isPaused = false

        backgroundColor = SKColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 1)
        // Very light gravity → long hang time / clear arc.
        physicsWorld.gravity = CGVector(dx: 0, dy: -160)
        physicsWorld.contactDelegate = self
        physicsWorld.speed = 1
        anchorPoint = .zero

        if !didBuild {
            rebuildWorld()
            didBuild = true
        }
        session?.status = .playing
        session?.canJump = true
    }

    func setMovingLeft(_ isMoving: Bool) {
        moveLeft = isMoving
        isPaused = false
        view?.isPaused = false
    }

    func jump() {
        isPaused = false
        view?.isPaused = false
        guard session?.status == .playing, let player, let body = player.physicsBody else { return }

        if isFeetOnGround {
            coyoteTime = coyoteLimit
        }
        guard coyoteTime > 0 || isFeetOnGround else { return }

        // Break floor contact so the physics solver can’t cancel the upward launch.
        player.position.y += 8
        body.collisionBitMask = 0
        jumpIgnoreGroundTime = jumpIgnoreGroundLimit
        groundedContacts = 0
        coyoteTime = 0

        let dx = moveLeft ? -moveSpeed : moveSpeed
        body.velocity = CGVector(dx: dx, dy: jumpSpeed)
        session?.canJump = false
    }

    func restart() {
        moveLeft = false
        groundedContacts = 0
        coyoteTime = coyoteLimit
        jumpIgnoreGroundTime = 0
        lastUpdateTime = 0
        rebuildWorld()
        isPaused = false
        view?.isPaused = false
        session?.status = .playing
        session?.canJump = true
    }

    override func update(_ currentTime: TimeInterval) {
        guard let player, let body = player.physicsBody else { return }
        isPaused = false

        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = min(currentTime - lastUpdateTime, 1.0 / 20.0)
        }
        lastUpdateTime = currentTime

        if jumpIgnoreGroundTime > 0 {
            jumpIgnoreGroundTime = max(0, jumpIgnoreGroundTime - dt)
            if jumpIgnoreGroundTime == 0 {
                body.collisionBitMask = SideScrollerPhysics.ground
            }
        }

        let grounded = jumpIgnoreGroundTime == 0 && isFeetOnGround
        if grounded {
            groundedContacts = max(groundedContacts, 1)
            coyoteTime = coyoteLimit
        } else if jumpIgnoreGroundTime == 0 {
            coyoteTime = max(0, coyoteTime - dt)
        }

        session?.canJump = (session?.status == .playing) && (grounded || coyoteTime > 0)

        guard session?.status == .playing else {
            body.velocity = .zero
            return
        }

        let dx: CGFloat = moveLeft ? -moveSpeed : moveSpeed
        // Preserve vertical velocity from gravity/jump; only steer horizontally.
        body.velocity = CGVector(dx: dx, dy: body.velocity.dy)
        player.xScale = moveLeft ? -1 : 1

        let halfWidth = size.width / 2
        let minX = halfWidth
        let maxX = max(levelWidth - halfWidth, halfWidth)
        cameraNode.position = CGPoint(
            x: min(max(player.position.x, minX), maxX),
            y: size.height / 2
        )

        if player.position.y < -80 {
            session?.status = .lost
            session?.canJump = false
            body.velocity = .zero
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if mask == (SideScrollerPhysics.player | SideScrollerPhysics.ground) {
            if jumpIgnoreGroundTime == 0 {
                groundedContacts += 1
            }
        }

        if mask == (SideScrollerPhysics.player | SideScrollerPhysics.goal) {
            session?.status = .won
            player?.physicsBody?.velocity = .zero
            moveLeft = false
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if mask == (SideScrollerPhysics.player | SideScrollerPhysics.ground) {
            groundedContacts = max(0, groundedContacts - 1)
        }
    }

    private var isFeetOnGround: Bool {
        guard let player else { return groundedContacts > 0 }
        if jumpIgnoreGroundTime > 0 { return false }
        if groundedContacts > 0 { return true }

        if let body = player.physicsBody,
           body.velocity.dy <= 40,
           body.allContactedBodies().contains(where: { $0.categoryBitMask & SideScrollerPhysics.ground != 0 }) {
            return true
        }

        let footY = player.position.y - 26
        let start = CGPoint(x: player.position.x, y: footY)
        let end = CGPoint(x: player.position.x, y: footY - 16)
        var hitGround = false
        physicsWorld.enumerateBodies(alongRayStart: start, end: end) { body, _, _, stop in
            if body.categoryBitMask & SideScrollerPhysics.ground != 0 {
                hitGround = true
                stop.pointee = true
            }
        }
        return hitGround
    }

    private func rebuildWorld() {
        removeAllChildren()
        cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode
        jumpIgnoreGroundTime = 0

        buildLevel()
        spawnPlayer(at: CGPoint(x: 120, y: 100))
        groundedContacts = 1
        coyoteTime = coyoteLimit
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func spawnPlayer(at point: CGPoint) {
        let node = SKSpriteNode(
            color: SKColor(red: 0.86, green: 0.28, blue: 0.22, alpha: 1),
            size: CGSize(width: 36, height: 48)
        )
        node.name = "player"
        node.position = point
        node.zPosition = 10

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 28, height: 40))
        body.allowsRotation = false
        body.restitution = 0
        body.friction = 0
        body.linearDamping = 0
        body.angularDamping = 0
        body.affectedByGravity = true
        body.isDynamic = true
        body.allowsRotation = false
        body.categoryBitMask = SideScrollerPhysics.player
        body.collisionBitMask = SideScrollerPhysics.ground
        body.contactTestBitMask = SideScrollerPhysics.ground | SideScrollerPhysics.goal
        body.usesPreciseCollisionDetection = true
        node.physicsBody = body

        let hat = SKSpriteNode(
            color: SKColor(red: 0.15, green: 0.35, blue: 0.75, alpha: 1),
            size: CGSize(width: 40, height: 12)
        )
        hat.position = CGPoint(x: 0, y: 22)
        node.addChild(hat)

        player = node
        addChild(node)
    }

    private func buildLevel() {
        levelWidth = 2800
        let groundY: CGFloat = 56

        for i in 0..<8 {
            let cloud = SKShapeNode(ellipseOf: CGSize(width: 90, height: 36))
            cloud.fillColor = SKColor.white.withAlphaComponent(0.85)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: CGFloat(i) * 320 + 160, y: CGFloat(280 + (i % 3) * 36))
            cloud.zPosition = -2
            addChild(cloud)
        }

        let segments: [(x: CGFloat, width: CGFloat, y: CGFloat)] = [
            (0, 520, groundY),
            (600, 360, groundY),
            (1020, 320, groundY + 40),
            (1400, 360, groundY),
            (1820, 320, groundY + 30),
            (2200, 500, groundY),
        ]

        for segment in segments {
            addPlatform(
                at: CGPoint(x: segment.x + segment.width / 2, y: segment.y),
                size: CGSize(width: segment.width, height: 40)
            )
        }

        addPlatform(at: CGPoint(x: 1600, y: groundY + 120), size: CGSize(width: 100, height: 28))
        addPlatform(at: CGPoint(x: 1950, y: groundY + 140), size: CGSize(width: 100, height: 28))

        let pole = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 140))
        pole.position = CGPoint(x: 2550, y: groundY + 90)
        pole.zPosition = 5
        let poleBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 140))
        poleBody.isDynamic = false
        poleBody.categoryBitMask = SideScrollerPhysics.goal
        poleBody.contactTestBitMask = SideScrollerPhysics.player
        poleBody.collisionBitMask = 0
        pole.physicsBody = poleBody
        addChild(pole)

        let flag = SKSpriteNode(
            color: SKColor(red: 0.95, green: 0.8, blue: 0.15, alpha: 1),
            size: CGSize(width: 48, height: 28)
        )
        flag.position = CGPoint(x: 2578, y: groundY + 145)
        flag.zPosition = 6
        addChild(flag)

        let finishLabel = SKLabelNode(text: "GOAL")
        finishLabel.fontName = "AvenirNext-Bold"
        finishLabel.fontSize = 18
        finishLabel.fontColor = SKColor.black.withAlphaComponent(0.7)
        finishLabel.position = CGPoint(x: 2550, y: groundY + 175)
        finishLabel.zPosition = 7
        addChild(finishLabel)
    }

    private func addPlatform(at position: CGPoint, size: CGSize) {
        let platform = SKSpriteNode(
            color: SKColor(red: 0.33, green: 0.55, blue: 0.28, alpha: 1),
            size: size
        )
        platform.position = position
        platform.zPosition = 1

        let top = SKSpriteNode(
            color: SKColor(red: 0.45, green: 0.72, blue: 0.35, alpha: 1),
            size: CGSize(width: size.width, height: 8)
        )
        top.position = CGPoint(x: 0, y: size.height / 2 - 4)
        platform.addChild(top)

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.friction = 0
        body.restitution = 0
        body.categoryBitMask = SideScrollerPhysics.ground
        body.contactTestBitMask = SideScrollerPhysics.player
        body.collisionBitMask = SideScrollerPhysics.player
        platform.physicsBody = body
        addChild(platform)
    }
}
