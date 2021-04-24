//
//  ContentView.swift
//  poolAssistant
//
//  Created by Ningyang Peng on 3/13/21.
//

import SwiftUI
import RealityKit
import ARKit

//extension ARView: ARCoachingOverlayViewDelegate {
//    func addCoaching() {
//        let coachingOverlay = ARCoachingOverlayView()
//        coachingOverlay.delegate = self
//        coachingOverlay.session = self.session
//        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//        coachingOverlay.goal = .anyPlane
//        self.addSubview(coachingOverlay)
//    }
//
//    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
//        coachingOverlayView.activatesAutomatically = false
//        //Ready to add entities next?
//    }
//}

//class CustomBox: Entity, HasModel, HasAnchoring, HasCollision {
//
//    required init(color: UIColor) {
//        super.init()
//        self.components[ModelComponent] = ModelComponent(
//            mesh: .generateBox(size: 0.1),
//            materials: [SimpleMaterial(
//                color: color,
//                isMetallic: false)
//            ]
//        )
//    }
//
//    convenience init(color: UIColor, position: SIMD3<Float>) {
//        self.init(color: color)
//        self.position = position
//    }
//
//    required init() {
//        fatalError("init() has not been implemented")
//    }
//}

struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {

//    func makeUIView(context: Context) -> ARView {
//
//        let arView = ARView(frame: .zero)
//        arView.addCoaching()
//
//        let config = ARWorldTrackingConfiguration()
//        config.planeDetection = .horizontal
//        arView.session.run(config, options: [])
//
////        // Load the "Box" scene from the "Experience" Reality File
////        let boxAnchor = try! Experience.loadBox()
////
////        // Add the box anchor to the scene
////        arView.scene.anchors.append(boxAnchor)
//        let box = CustomBox(color: .yellow)
//        arView.scene.anchors.append(box)
//
//        return arView
//
//    }
//
//    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeUIView(context: Context) -> ARView {

        let arView = ARView(frame: .zero)
        createReferenceObject(arView: arView)

        let config = ARWorldTrackingConfiguration()
        guard let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "gallery", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Detecting plane
        config.planeDetection = .horizontal
        
        // Detecting objects
        config.detectionObjects = referenceObjects
        arView.session.run(config, options: [])

        return arView

    }

    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let objectAnchor = anchor as? ARObjectAnchor {
            node.addChildNode(self.model)
        }
    }
    
    func createReferenceObject(arView: ARView) {
        let configuration = ARObjectScanningConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration, options: .resetTracking)


        // Extract the reference object based on the position & orientation of the bounding box.
        arView.session.createReferenceObject(
            transform: boundingBox.simdWorldTransform,
            center: float3(), extent: boundingBox.extent,
            completionHandler: { object, error in
                if let referenceObject = object {
                    // Adjust the object's origin with the user-provided transform.
                    self.scannedReferenceObject = referenceObject.applyingTransform(origin.simdTransform)
                    self.scannedReferenceObject!.name = self.scannedObject.scanName
                    
                    if let referenceObjectToMerge = ViewController.instance?.referenceObjectToMerge {
                        ViewController.instance?.referenceObjectToMerge = nil
                        
                        // Show activity indicator during the merge.
                        ViewController.instance?.showAlert(title: "", message: "Merging previous scan into this scan...", buttonTitle: nil)
                        
                        // Try to merge the object which was just scanned with the existing one.
                        self.scannedReferenceObject?.mergeInBackground(with: referenceObjectToMerge, completion: { (mergedObject, error) in

                            if let mergedObject = mergedObject {
                                self.scannedReferenceObject = mergedObject
                                ViewController.instance?.showAlert(title: "Merge successful",
                                                                   message: "The previous scan has been merged into this scan.", buttonTitle: "OK")
                                creationFinished(self.scannedReferenceObject)

                            } else {
                                print("Error: Failed to merge scans. \(error?.localizedDescription ?? "")")
                                let message = """
                                        Merging the previous scan into this scan failed. Please make sure that
                                        there is sufficient overlap between both scans and that the lighting
                                        environment hasn't changed drastically.
                                        Which scan do you want to use for testing?
                                        """
                                let thisScan = UIAlertAction(title: "Use This Scan", style: .default) { _ in
                                    creationFinished(self.scannedReferenceObject)
                                }
                                let previousScan = UIAlertAction(title: "Use Previous Scan", style: .default) { _ in
                                    self.scannedReferenceObject = referenceObjectToMerge
                                    creationFinished(self.scannedReferenceObject)
                                }
                                ViewController.instance?.showAlert(title: "Merge failed", message: message, actions: [thisScan, previousScan])
                            }
                        })
                    } else {
                        creationFinished(self.scannedReferenceObject)
                    }
                } else {
                    print("Error: Failed to create reference object. \(error!.localizedDescription)")
                    creationFinished(nil)
                }
        })
    }

}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
