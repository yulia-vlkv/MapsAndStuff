//
//  ViewController.swift
//  MapsAndStuff
//
//  Created by Iuliia Volkova on 26.06.2022.
//

import UIKit
import MapKit


final class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate  {
    
    private func updatePinCountLabel() {
        let pinCount = self.mapView.annotations.filter{$0 is MKPointAnnotation}.count
        let localized = NSLocalizedString("pins_count", comment: "")
        let formatted = String.localizedStringWithFormat(localized, pinCount)
        pinCountLabel.text = formatted
    }
    
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        let uiLongPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        uiLongPress.minimumPressDuration = 2.0
        map.addGestureRecognizer(uiLongPress)
        map.translatesAutoresizingMaskIntoConstraints = false
        map.delegate = self
        return map
    }()
    
    private lazy var pinCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.shadowColor = .black
        label.layer.shadowRadius = 3
        label.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        updatePinCountLabel()
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false
        navigationItem.title = "main_title".localized
        navigationController?.navigationBar.tintColor = CustomColors.setColor(style: .dustyTeal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "navigation_bar_remove_button".localized,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(removeAllAnnotations))
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = CustomColors.setColor(style: .pastelSandy)
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    @objc private func removeAllAnnotations(){
        self.mapView.removeAnnotations(mapView.annotations)
        UserDefaults.standard.removeObject(forKey: "StoredAnnotations")
        self.updatePinCountLabel()
    }
    
    private func setupMapView() {
        view.addSubview(mapView)
        mapView.addSubview(compass)
        mapView.addSubview(pinCountLabel)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            compass.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 8),
            compass.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -8),
            compass.leadingAnchor.constraint(equalTo: pinCountLabel.trailingAnchor, constant: 50),
            
            pinCountLabel.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 16),
            pinCountLabel.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            pinCountLabel.heightAnchor.constraint(equalToConstant: 50),
            pinCountLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])
    }
    
    @objc private func longPressed(sender: UILongPressGestureRecognizer){
        let touchPoint = sender.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        let alert = UIAlertController(title: "annotation_alert_title".localized, message: "annotation_alert_text".localized, preferredStyle: .alert)
        alert.addTextField() { newTextField in
            newTextField.placeholder = "annotation_alert_placeholder".localized
        }
        alert.addAction(UIAlertAction(title: "annotation_alert_cancel_action".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "annotation_alert_OK_action".localized, style: .default) { _ in
            if let textFields = alert.textFields,
               let tf = textFields.first,
               let title = tf.text {
                annotation.title = title
                self.mapView.addAnnotation(annotation)
                self.updatePinCountLabel()
                
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
                    updatePinCountLabel()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func configureMapView() {
        
        mapView.mapType = .hybrid
        
        let centerCoordinates = locationManager.location?.coordinate
        mapView.setCenter(centerCoordinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), animated: true)
        
        let region = MKCoordinateRegion(center: centerCoordinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), latitudinalMeters: 1000, longitudinalMeters: 1000)
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
            let alert = UIAlertController(title: "alert_title".localized, message: "alert_message".localized, preferredStyle: UIAlertController.Style.alert)
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

        let sourcePlaceMark = MKPlacemark(coordinate: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)

        let destinationPlaceMark =  MKPlacemark(coordinate: view.annotation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) )
        let destinationMapItem = MKMapItem(placemark: destinationPlaceMark)
        
        let alert = UIAlertController(title: "route_alert_title".localized, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "route_alert_no_action".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "route_alert_yes_action".localized, style: .default) { _ in
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

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
