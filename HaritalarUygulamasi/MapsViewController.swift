//
//  ViewController.swift
//  HaritalarUygulamasi
//
//  Created by Furkan Eruçar on 9.04.2022.
//

import UIKit
import MapKit
import CoreLocation // Nasıl konum alacağız onu yapacağız.
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate { // Delegate'i viewController'a atamamız gerekiyor. Yoksa mapkit fonksiyonlarına ulaşamayız.

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var notTextField: UITextField!
    
    var locationManager = CLLocationManager() // Burada bir konum yöneticisi oluşturuyoruz.
    var secilenLatitude = Double() // kaydetClicked fonksiyonumuzda kullanıcıdan aldığımız enlem boylamı ayarlamamız lazım fakat o fonksiyon içinde bunlara ulaşamıyoruz.
    var secilenLongitute = Double() // Bundan dolayı onlara ulaşabileceğimiz şekilde bir değşiken ataması yapyoruz ve bunları konumSec fonksiyonunda bir değere atayacağız.
    
    var secilenIsim = ""
    var secilenId: UUID?
    
    var annotationTitle = "" // Annotation haritaya konulan pin demek.
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Ne kadar doğru bir şekilde konum almak istiyoruz.
        locationManager.requestWhenInUseAuthorization() // Kullanıcıdan izin isteyeceğiz haberi olsun.
        locationManager.startUpdatingLocation() // Konumu güncellemeye başla demek.
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer: ))) // Bunu kullanmamızın sebebi, eğer ilk öğrendiğimizi kullanırsak kullanıcı her dokunduğunda yer işaretlemesi yapılacak. Biz uzun dokunduktan sonra yapmasını istiyoruz.
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsim != "" {
            // Core Datadan verileri çek
            
            if let uuidString = secilenId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString) // hangi kolonu filtrelereyeceğimizi ve hangi değerle filtreleyeceğimizi yazabiliriz. id = %@ demek id'si birazdan yazacağım id'lere eşit olanları getir.
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0 {
                        
                        for sonuc in sonuclar as! [NSManagedObject] {
                            
                            if let isim = sonuc.value(forKey: "isim") as? String {
                                annotationTitle = isim
                                
                                if let not = sonuc.value(forKey: "not") as? String {
                                    annotationSubtitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            isimTextField.text = annotationTitle
                                            notTextField.text = annotationSubtitle
                                            
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
                    print("Hata var")
                }
                
                
            }
        } else {
            // yeni veri eklemeye geldi
        }
        
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil { // optional olduğu için nil de olabilir. eğer nilse baştan sıfırtan oluşturucaz pin'i
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // Bizim kullanacağımız annotation ekstra bir şey gösterebilir mi?
            pinView?.tintColor = .systemBlue
            
            let button = UIButton(type: .detailDisclosure) // Pin viewda göstereceğimiz buttonu oluşturucaz.
            pinView?.rightCalloutAccessoryView = button // Kullanıcı artık info kısmından tıklayabilecek. Biz ise bu button'a tıklayınca kullanıcının güncel konumuna navigasyon olsun istiyoruz.
            
            
        } else { // Değilse normal kullandığımız annotationa eşitleyebiliriz.
            pinView?.annotation = annotation
        }
        
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if secilenIsim != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarkDizisi, hata in
                
                if let placemarks = placemarkDizisi { // Burda da optional olduğu için böyle yazdık. belki nil gelecek?
                    if placemarks.count > 0 { // Yani sıfırdan büyük değilse yanlış gelmiştir.
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark) // harita üstünde kullanılacak bir öğe.
                        
                        item.name = self.annotationTitle // ARtık direk navigasyon içinde kullanabiliriz.
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: launchOptions)
                        
                        
                        
                    }
                }
            } // Biz bi konum vereceğiz o da bize bi şeyler verecek ama önce yukarda konumu almamız lazım.
        }
    }
    
    @objc func konumSec(gestureRecognizer: UILongPressGestureRecognizer) { // İçine parametre yazmamızın sebebi kullanıcının tıkladığı yere ulaşabilmek ve gestureRecognizer'ı selector içinde kullanabilmek
        if gestureRecognizer.state == .began { // BÖlyece jest algılayıcı başladığı takdirde ne olacağını yazacağız.
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView) // Bunla da birlikte artık kullanıcının dokunduğu yeri biliyorum.
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitute = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation() // İşaretleme yapıcaz.
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { // Konumun bize verildiği fonksiyonu yazacağız.
        //  print(locations[0].coordinate.latitude)
        // print(locations[0].coordinate.longitude)
        if secilenIsim == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // konum oluşturacağız
    
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            
        }
        
    }

    @IBAction func kaydetClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate // Context'e ulaşabilmek için appDelegate'imizi tanımlıyoruz.
        let context = appDelegate.persistentContainer.viewContext // Ve artık context'e ulaşmış bulunuyoruz.
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(isimTextField.text, forKey: "isim") // setValue ile değerleri kaydedebiliyorduk.
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitute, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        // Şimdi save edebilmemiz için do,try,catch kullanacağız.
        
        do {
            try context.save() // Bununla birlikte latitude longtitude her şeyimizi kaydedicez.
            print("kayıt edildi")
        } catch {
            print("Hata")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "yeniYerOlusturuldu"), object: nil) // Notification center ile uygulamaya bildiricez. Sonra gözlemleyip kaydedildiyse ne yapıcaz onu göstericez.
        navigationController?.popViewController(animated: true) // Burda bir önceki controller olan listviewcontrollera geri döndürmeyi yapabiliriz.
    }
    
}

