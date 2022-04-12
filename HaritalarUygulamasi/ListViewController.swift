//
//  ListViewController.swift
//  HaritalarUygulamasi
//
//  Created by Furkan Eruçar on 9.04.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var tableView: UITableView!
    
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    var secilenYerIsmi = ""
    var secilenYerId: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(artiButtonuClicked)) // Sağ üstte çıkan "+" buttonunu ekleyelim
         
        veriAl()
    }
    
    override func viewWillAppear(_ animated: Bool) { // ListviewController her gözüktüğünde yapılacak şeyler.
        
        NotificationCenter.default.addObserver(self, selector: #selector(veriAl), name: NSNotification.Name("yeniYerOlusturuldu"), object: nil) // addObserver olduğu zaman ne yapacağını selector fonksiyonu ile göstericez.
        
    }
    
    
    @objc func veriAl() { // Kullanıcıdan fetch etmemiz için burayı yapacağız. hatırladığınız gibi fetch için request ediyorduk sonra requeste cevap veriyorduk ve verimizi coredata'dan alabiliyorduk.
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        request.returnsObjectsAsFaults = false
        
        do {
            let sonuclar = try context.fetch(request) // context.fetch sonuçların olduğu bir dizi veriyordu ve bu dizi any türündeydi, bunu NSObject haline getiriyorduk.
            
            if sonuclar.count > 0 {
                
                isimDizisi.removeAll(keepingCapacity: false)
                idDizisi.removeAll(keepingCapacity: false)
                
                for sonuc in sonuclar as! [NSManagedObject] {
                    if let isim = sonuc.value(forKey: "isim") as? String { // Bu bize Any veriyor biz bunu string olarak cast etmemiz gerek
                        isimDizisi.append(isim)
                    }
                    
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                }
                
                tableView.reloadData()
                
            }
            
        } catch {
            print("Hata var")
        }
        
    }
    
    
    @objc func artiButtonuClicked() {
        
        secilenYerIsmi = ""
        performSegue(withIdentifier: "toMapsVC", sender: nil) // Artık navigation Bardaki "+" buttonuna tıklayınca diğer viewController'a geçiyoruz.
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenYerIsmi = isimDizisi[indexPath.row]
        secilenYerId = idDizisi[indexPath.row]
        performSegue(withIdentifier: "toMapsVC", sender: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVC" {
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.secilenIsim = secilenYerIsmi
            destinationVC.secilenId = secilenYerId // Böylece veri aktarımı tamamlanacak.
        }
    }

}
