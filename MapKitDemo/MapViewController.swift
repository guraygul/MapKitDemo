//
//  ViewController.swift
//  MapKitDemo
//
//  Created by Güray Gül on 21.01.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var locationManager = CLLocationManager()
    var selectedLatitude = Double()
    var selectedLongitude = Double()
    
    var selectedName = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let keyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:)))
        
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        view.addGestureRecognizer(keyboardGestureRecognizer)
        
        if selectedName != "" {
            
            if let uuidString = selectedId?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    
                    let results = try context.fetch(fetchRequest)
                    
                    if results.count > 0 {
                        for result in results as! [NSManagedObject] {
                            
                            if let name = result.value(forKey: "name") as? String {
                                annotationTitle = name
                                
                                if let locationDescription = result.value(forKey: "locationDescription") as? String {
                                    annotationSubtitle = description
                                    
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = result.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            nameTextField.text = annotationTitle
                                            descriptionTextField.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    print("error")
                }
            }
            
        } else {
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
                
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDictionary, error) in
                
                if let placemarks = placemarkDictionary {
                    if placemarks.count > 0 {
                            
                        let newPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    @objc func closeKeyboard() {
        view.endEditing(true)
    }
    
    @objc func selectLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: mapView)
            let touchedCoordinate = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
            
            selectedLatitude = touchedCoordinate.latitude
            selectedLongitude = touchedCoordinate.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinate
            annotation.title = nameTextField.text
            annotation.subtitle = descriptionTextField.text
            mapView.addAnnotation(annotation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedName == "" {
            
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func didSaveTapped(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context)
        
        newPlace.setValue(nameTextField.text, forKey: "name")
        newPlace.setValue(descriptionTextField.text, forKey: "LocationDescription")
        newPlace.setValue(selectedLatitude, forKey: "latitude")
        newPlace.setValue(selectedLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("Saved")
        } catch {
            print("Error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("NewPlaceCreated"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    
    
}

