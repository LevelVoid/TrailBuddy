import Foundation
import RealityKit

@MainActor
enum PetEntityLoader {

    /// Base correction to stand the dog upright.
    /// Many USDZ models have a different "up" axis;
    /// this rotates -90° around X so the dog faces forward.
    static let baseCorrection = simd_quatf(
        angle: -Float.pi / 2, axis: SIMD3(1, 0, 0)
    )

    /// Loads dog.usdz from the app bundle at scale 50.
    /// Falls back to a brown sphere if the model is missing.
    static func load() async -> ModelEntity {
        if let url = Bundle.main.url(forResource: "dog", withExtension: "usdz") {
            do {
                let entity = try await ModelEntity(contentsOf: url)
                entity.scale = SIMD3(repeating: 50.0)
                entity.transform.rotation = baseCorrection
                entity.generateCollisionShapes(recursive: true)
                // Do NOT auto-play animation — caller controls it
                return entity
            } catch {
                print("⚠️ dog.usdz failed to load: \(error.localizedDescription)")
            }
        }
        return makeFallbackEntity()
    }

    /// Start the walk animation on the entity (and children).
    static func startWalking(_ entity: ModelEntity) {
        for anim in entity.availableAnimations {
            entity.playAnimation(
                anim.repeat(duration: .infinity),
                transitionDuration: 0.25,
                startsPaused: false
            )
        }
        for child in entity.children {
            if let m = child as? ModelEntity {
                for anim in m.availableAnimations {
                    m.playAnimation(
                        anim.repeat(duration: .infinity),
                        transitionDuration: 0.25,
                        startsPaused: false
                    )
                }
            }
        }
    }

    /// Stop all animations (idle pose).
    static func stopWalking(_ entity: ModelEntity) {
        entity.stopAllAnimations()
        for child in entity.children {
            if let m = child as? ModelEntity {
                m.stopAllAnimations()
            }
        }
    }

    private static func makeFallbackEntity() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.2)
        var material = SimpleMaterial()
        material.color = .init(
            tint: .init(red: 0.55, green: 0.27, blue: 0.07, alpha: 1)
        )
        return ModelEntity(mesh: mesh, materials: [material])
    }
}
