//
//  ListViewController.swift
//  MapKitDemo
//
//  Created by Güray Gül on 24.01.2024.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var nameArray = [String]()
    var idArray = [UUID]()
    
    var selectedPlaceName = ""
    var selectedPlaceId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didAddTapped))
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("NewPlaceCreated"), object: nil)
    }
    
    
    
    @objc func getData() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        request.returnsObjectsAsFaults = false
        
        do {
            
            let results = try context.fetch(request)
            
            if results.count > 0 {
                
                nameArray.removeAll(keepingCapacity: false)
                idArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "name") as? String {
                        nameArray.append(name)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID {
                        idArray.append(id)
                    }
                }
                tableView.reloadData()
            }
        } catch {
            print("Error")
        }
    }
    
    @objc func didAddTapped() {
        selectedPlaceName = ""
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedPlaceName = nameArray[indexPath.row]
        selectedPlaceId = idArray[indexPath.row]
        
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC" {
            let destinationVC = segue.destination as! MapViewController
            destinationVC.selectedName = selectedPlaceName
            destinationVC.selectedId = selectedPlaceId
        }
    }
}
