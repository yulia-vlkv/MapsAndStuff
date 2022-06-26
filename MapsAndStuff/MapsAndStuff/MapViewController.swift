//
//  ViewController.swift
//  MapsAndStuff
//
//  Created by Iuliia Volkova on 26.06.2022.
//

import UIKit
import MapKit


final class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate  {
    
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        let uiLongPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        uiLongPress.minimumPressDuration = 2.0
        map.addGestureRecognizer(uiLongPress)
        map.translatesAutoresizingMaskIntoConstraints = false
        map.delegate = self
        return map
    }()
    
    private lazy var compass: MKCompassButton = {
        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .visible
        compass.translatesAutoresizingMaskIntoConstraints = false
        return compass
    }()

    private lazy var locationManager = CLLocationManager()
    
    override func loadView() {
        super.loadView()
        
        setupNavigationBar()
        setupMapView()
        configureMapView()
        checkUserLocationPermissions()
        showStoredAnnotations()
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false
        navigationItem.title = "Map"
        navigationController?.navigationBar.tintColor = CustomColors.setColor(style: .dustyTeal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Remove All", style: .plain, target: self, action: #selector(removeAllAnnotations))
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = CustomColors.setColor(style: .pastelSandy)
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    @objc private func removeAllAnnotations(){
        self.mapView.removeAnnotations(mapView.annotations)
    }
    
    private func setupMapView() {
        view.addSubview(mapView)
        mapView.addSubview(compass)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            compass.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 8),
            compass.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -8),
        ])
    }
    
    @objc private func longPressed(sender: UILongPressGestureRecognizer){
        let touchPoint = sender.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        let alert = UIAlertController(title: "Add pin", message: "Enter title", preferredStyle: .alert)
        alert.addTextField() { newTextField in
            newTextField.placeholder = "My favourite place"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            if let textFields = alert.textFields,
               let tf = textFields.first,
               let title = tf.text {
                annotation.title = title
                self.mapView.addAnnotation(annotation)
                
                //To save annotations to UserDefaults
                let newAnnotationDict = [
                    "lat": newCoordinates.latitude,
                    "lng": newCoordinates.longitude,
                    "title": annotation.title
                ] as [String : Any]
                
                var annotationsArray: [[String:Any]]!
                var annotationsData = UserDefaults.standard.data(forKey: "StoredAnnotations")
                if annotationsData == nil {
                    annotationsArray = [newAnnotationDict]
                } else {
                    do {
                        annotationsArray = try JSONSerialization.jsonObject(with: annotationsData!, options: []) as! [[String:Any]]
                        annotationsArray.append(newAnnotationDict)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: annotationsArray, options: .prettyPrinted)
                    UserDefaults.standard.set(jsonData, forKey: "StoredAnnotations")
                } catch {
                    print(error.localizedDescription)
                }
                print(annotation.coordinate.latitude, annotation.coordinate.longitude)
            } else {
                print("Can't add an annotation")
            }
        })
        navigationController?.present(alert, animated: true)
    }
    
    private func showStoredAnnotations(){
        //Get annotations from UserDefaults
        if UserDefaults.standard.data(forKey: "StoredAnnotations") != nil {
            var storedAnnotationObjects = [MKPointAnnotation]()
            do {
                let storedAnnotationsData = UserDefaults.standard.data(forKey: "StoredAnnotations")!
                let storedAnnotationsArray = try JSONSerialization.jsonObject(with: storedAnnotationsData, options: []) as! [[String:Any]]
                for dict in storedAnnotationsArray {
                    let newAnnotation = MKPointAnnotation()
                    newAnnotation.coordinate = CLLocationCoordinate2D(latitude: dict["lat"] as! CGFloat, longitude: dict["lng"] as! CGFloat)
                    newAnnotation.title = dict["title"] as! String
                    storedAnnotationObjects.append(newAnnotation)
                }
                for annotation in storedAnnotationObjects {
                    self.mapView.addAnnotation(annotation)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func configureMapView() {
        
        mapView.mapType = .hybrid
        
        let centerCoordinates = CLLocationCoordinate2D(latitude: 42.2845927, longitude: 18.8828971)
        mapView.setCenter(centerCoordinates, animated: true)
        
        let region = MKCoordinateRegion(center: centerCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        
        mapView.showsTraffic = false
        mapView.isZoomEnabled = true
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.showsUserLocation = true
    }
    
    private func checkUserLocationPermissions() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    
        switch locationManager.authorizationStatus {
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            
        case .denied, .restricted:
            let alert = UIAlertController(title: "Permission", message: "Please allow the app to use your location", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        @unknown default:
            fatalError("Не обрабатываемый статус")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUserLocationPermissions()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = CustomColors.setColor(style: .dustyTeal)
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let directionRequest = MKDirections.Request()
        directionRequest.transportType = .automobile

        let sourcePlaceMark = MKPlacemark(coordinate: view.annotation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) )
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)

        let destinationPlaceMark = MKPlacemark(coordinate: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let destinationMapItem = MKMapItem(placemark: destinationPlaceMark)
        
        let alert = UIAlertController(title: "Draw a route?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "nope", style: .cancel))
        alert.addAction(UIAlertAction(title: "yep", style: .default) { _ in
            directionRequest.source = sourceMapItem
            directionRequest.destination = destinationMapItem
            let directions = MKDirections(request: directionRequest)
            directions.calculate { [weak self] response, error -> Void in
                guard let self = self else {
                    return
                }
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    return
                }
                let route = response.routes[0]
                self.mapView.delegate = self
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        })
        navigationController?.present(alert, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "something")
        annotationView.markerTintColor = CustomColors.setColor(style: .dustyTeal)
        return annotationView
    }

}

